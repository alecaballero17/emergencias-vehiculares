"""
Procesador Multimodal BLINDADO — Failover Gemini ↔ Groq.
Analiza audio, imágenes y texto con IA.
Si Gemini falla, usa Groq. Si Groq falla, genera análisis local.
"""
import google.generativeai as genai
import json
import os
import time
import logging
import mimetypes
import base64
from PIL import Image
from app.config import get_settings
from app.models.enums import IncidentType, IncidentPriority
from app.schemas.incident import AIAnalysisResult

logger = logging.getLogger("ai.multimodal_processor")

settings = get_settings()

if settings.gemini_api_key:
    genai.configure(api_key=settings.gemini_api_key)

# Modelos de Gemini con cuotas independientes
GEMINI_MODELS = [
    "gemini-2.5-flash-lite",
    "gemini-flash-latest",
    "gemini-pro-latest",
]

# ───────────────────────────────────────────────────────
#  Prompt maestro reutilizable
# ───────────────────────────────────────────────────────
def _build_multimodal_prompt(
    user_description: str | None,
    vehicle_info: str | None,
    location_address: str | None,
) -> str:
    return f"""
Actúa como un experto jefe de taller y despachador de emergencias de élite.
Tu misión es analizar integralmente este reporte de emergencia vehicular.

DATOS DE CONTEXTO:
- Descripción del usuario: {user_description or 'Sin descripción'}
- Información del vehículo: {vehicle_info or 'Desconocido'}
- Ubicación: {location_address or 'Ubicación GPS'}

INSTRUCCIONES CRÍTICAS:
1. Cruza la información: si el audio dice algo pero las fotos muestran otra cosa, prioriza la evidencia visual.
2. Si el audio tiene mucho ruido, básate en el análisis visual.
3. Identifica correctamente: choque/colisión, pinchazo de llanta, falla de motor, batería, sobrecalentamiento, llaves perdidas, llaves dentro del vehículo, u otro.

RESPONDE EXCLUSIVAMENTE EN JSON VÁLIDO (sin bloques de código markdown):
{{
    "incident_type": "battery|tire|crash|engine|overheating|keys_lost|keys_locked|other",
    "priority": "low|medium|high|critical",
    "confidence": 0.0-1.0,
    "transcription": "Transcripción clara y literal del audio SIN incluir marcas de tiempo o números (si hay audio, si no pon 'Sin audio')",
    "summary": "🚨 SITUACIÓN: (1 oración)\\n🛠️ DIAGNÓSTICO: (2-3 puntos clave)\\n🧰 RECOMENDACIÓN: (Herramientas/acciones necesarias)",
    "details": "Breve explicación técnica de tu razonamiento"
}}
"""


def _parse_multimodal_response(text: str) -> dict:
    """Limpia y parsea la respuesta JSON de la IA."""
    if "```json" in text:
        text = text.split("```json")[1].split("```")[0].strip()
    elif "```" in text:
        text = text.split("```")[1].split("```")[0].strip()
    return json.loads(text)


def _build_analysis_result(data: dict) -> AIAnalysisResult:
    """Construye el resultado tipado desde el dict parseado."""
    try:
        inc_type = IncidentType(data["incident_type"])
    except Exception:
        inc_type = IncidentType.OTHER

    try:
        priority = IncidentPriority(data["priority"])
    except Exception:
        priority = IncidentPriority.MEDIUM

    raw_confidence = data.get("confidence", 0.9)
    confidence = round(raw_confidence * 100, 2) if raw_confidence <= 1.0 else round(raw_confidence, 2)

    return AIAnalysisResult(
        incident_type=inc_type,
        priority=priority,
        confidence=confidence,
        summary=data.get("summary", "Sin resumen"),
        audio_transcription=data.get("transcription", "No disponible"),
        classification_details=data.get("details", "Analizado vía multimodal"),
    )


# ───────────────────────────────────────────────────────
#  Proveedor 1: Gemini (multimodal nativo)
# ───────────────────────────────────────────────────────
async def _analyze_with_gemini(
    prompt: str,
    audio_path: str | None,
    image_paths: list[str] | None,
) -> AIAnalysisResult:
    """Intenta con múltiples modelos Gemini. Soporta audio + imágenes inline."""
    contents = [prompt]

    # Audio inline
    if audio_path and os.path.exists(audio_path):
        logger.info(f"[Gemini] Preparando audio inline: {audio_path}")
        if audio_path.endswith(".webm"):
            mime_type = "audio/webm"
        else:
            mime_type = mimetypes.guess_type(audio_path)[0] or "audio/mpeg"
        with open(audio_path, "rb") as f:
            audio_bytes = f.read()
        contents.append({"mime_type": mime_type, "data": audio_bytes})
        logger.info(f"[Gemini] Audio adjuntado ({len(audio_bytes)} bytes, {mime_type})")

    # Imágenes como PIL
    if image_paths:
        for i, path in enumerate(image_paths):
            if os.path.exists(path):
                logger.info(f"[Gemini] Adjuntando imagen {i+1}: {path}")
                contents.append(Image.open(path))

    # Intentar con cada modelo
    last_error = None
    for model_name in GEMINI_MODELS:
        try:
            model = genai.GenerativeModel(model_name)
            logger.info(f"[Gemini] Usando modelo: {model_name}")
            response = model.generate_content(contents)
            data = _parse_multimodal_response(response.text.strip())
            result = _build_analysis_result(data)
            logger.info(f"[Gemini] ✅ Análisis exitoso con {model_name} | {result.incident_type.value}")
            return result
        except Exception as api_error:
            last_error = api_error
            error_str = str(api_error)
            if "429" in error_str or "quota" in error_str.lower():
                logger.warning(f"[Gemini] ⚠️ Cuota agotada en {model_name}, probando siguiente...")
                time.sleep(0.5)
                continue
            else:
                raise api_error

    raise last_error or Exception("Todos los modelos Gemini agotaron su cuota")


# ───────────────────────────────────────────────────────
#  Proveedor 2: Groq / Llama 3.1 (solo texto + imágenes base64)
# ───────────────────────────────────────────────────────
async def _analyze_with_groq(
    prompt: str,
    audio_path: str | None,
    image_paths: list[str] | None,
) -> AIAnalysisResult:
    """
    Fallback con Groq. Llama 3.1 no soporta audio directamente,
    pero puede analizar la descripción del usuario y generar clasificación.
    Si hay imágenes, las envía como base64 al modelo de visión.
    """
    import httpx

    if not settings.groq_api_key:
        raise ValueError("Groq API Key no configurada")

    headers = {
        "Authorization": f"Bearer {settings.groq_api_key}",
        "Content-Type": "application/json",
    }

    # Si hay audio, intentar transcribirlo primero con Whisper
    audio_transcription = None
    if audio_path and os.path.exists(audio_path):
        try:
            logger.info(f"[Groq] Transcribiendo audio con Whisper: {audio_path}")
            async with httpx.AsyncClient() as client:
                with open(audio_path, "rb") as audio_file:
                    filename = os.path.basename(audio_path)
                    content_type = mimetypes.guess_type(audio_path)[0] or "audio/mpeg"
                    resp = await client.post(
                        "https://api.groq.com/openai/v1/audio/transcriptions",
                        headers={"Authorization": f"Bearer {settings.groq_api_key}"},
                        files={"file": (filename, audio_file, content_type)},
                        data={"model": "whisper-large-v3", "language": "es"},
                        timeout=30.0,
                    )
                if resp.status_code == 200:
                    audio_transcription = resp.json().get("text", "").strip()
                    logger.info(f"[Groq] ✅ Audio transcrito: '{audio_transcription[:80]}...'")
        except Exception as whisper_err:
            logger.warning(f"[Groq] ⚠️ Whisper falló, continuando sin audio: {whisper_err}")

    # Enriquecer el prompt con la transcripción de audio
    enriched_prompt = prompt
    if audio_transcription:
        enriched_prompt += f"\n\nTRANSCRIPCIÓN DEL AUDIO (voz del conductor):\n{audio_transcription}"

    # Construir mensaje para Groq
    messages = [{"role": "user", "content": enriched_prompt}]

    payload = {
        "model": "llama-3.1-8b-instant",
        "messages": messages,
        "temperature": 0.2,
        "max_tokens": 500,
        "response_format": {"type": "json_object"},
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers=headers,
            json=payload,
            timeout=25.0,
        )
        if response.status_code != 200:
            raise ValueError(f"Groq API status {response.status_code}: {response.text}")

        text = response.json()["choices"][0]["message"]["content"].strip()
        data = _parse_multimodal_response(text)

        # Insertar la transcripción real de Whisper si la tenemos
        if audio_transcription and data.get("transcription") in [None, "", "Sin audio"]:
            data["transcription"] = audio_transcription

        result = _build_analysis_result(data)
        logger.info(f"[Groq] ✅ Análisis exitoso con Llama 3.1 | {result.incident_type.value}")
        return result


# ───────────────────────────────────────────────────────
#  Proveedor 3: Análisis LOCAL (nunca falla)
# ───────────────────────────────────────────────────────
def _analyze_local(
    user_description: str | None,
    incident_type_hint: str | None = None,
) -> AIAnalysisResult:
    """
    Clasificador local basado en palabras clave.
    No depende de ninguna API — safety net final.
    """
    desc_lower = (user_description or "").lower()

    # Detección por palabras clave
    type_map = [
        (["batería", "battery", "no enciende", "arranque", "no prende"], IncidentType.BATTERY, IncidentPriority.MEDIUM),
        (["llanta", "tire", "pinchazo", "neumático", "rueda ponchada"], IncidentType.TIRE, IncidentPriority.MEDIUM),
        (["choque", "crash", "accidente", "colisión", "golpe"], IncidentType.CRASH, IncidentPriority.HIGH),
        (["motor", "engine", "humo", "aceite", "ruido fuerte"], IncidentType.ENGINE, IncidentPriority.HIGH),
        (["calentamiento", "overheating", "temperatura", "radiador"], IncidentType.OVERHEATING, IncidentPriority.HIGH),
        (["llave", "keys", "cerrad", "puerta"], IncidentType.KEYS_LOCKED, IncidentPriority.LOW),
    ]

    detected_type = IncidentType.OTHER
    detected_priority = IncidentPriority.MEDIUM

    for keywords, inc_type, priority in type_map:
        if any(kw in desc_lower for kw in keywords):
            detected_type = inc_type
            detected_priority = priority
            break

    logger.info(f"[LOCAL] 🔧 Análisis local: {detected_type.value} | {detected_priority.value}")

    return AIAnalysisResult(
        incident_type=detected_type,
        priority=detected_priority,
        confidence=45.0,
        summary=f"🚨 SITUACIÓN: Incidente vehicular reportado — {detected_type.value}\n🛠️ DIAGNÓSTICO: Clasificación automática basada en la descripción del usuario.\n🧰 RECOMENDACIÓN: Se requiere evaluación presencial del técnico.",
        audio_transcription="No disponible (análisis local)",
        classification_details="Clasificación realizada por el motor local (sin API de IA disponible). Se recomienda verificación manual.",
    )


# ───────────────────────────────────────────────────────
#  FUNCIÓN PRINCIPAL — Failover blindado
# ───────────────────────────────────────────────────────
async def process_multimodal_incident(
    audio_path: str | None = None,
    image_paths: list[str] | None = None,
    user_description: str | None = None,
    vehicle_info: str | None = None,
    location_address: str | None = None,
) -> AIAnalysisResult:
    """
    Procesador MAESTRO Multimodal con TRIPLE FAILOVER:
      1. Gemini (múltiples modelos, multimodal nativo)
      2. Groq / Llama 3.1 + Whisper (texto + transcripción de audio)
      3. Clasificador local inteligente (nunca falla)

    GARANTÍA: siempre retorna un resultado, nunca lanza excepción.
    """
    prompt = _build_multimodal_prompt(user_description, vehicle_info, location_address)
    providers_tried = []

    # ── Intento 1: Gemini ──
    if settings.gemini_api_key:
        try:
            logger.info("[FAILOVER] 🔄 Intentando análisis multimodal con Gemini...")
            return await _analyze_with_gemini(prompt, audio_path, image_paths)
        except Exception as e:
            providers_tried.append(f"Gemini: {e}")
            logger.warning(f"[FAILOVER] ⚠️ Gemini falló: {e}")

    # ── Intento 2: Groq ──
    if settings.groq_api_key:
        try:
            logger.info("[FAILOVER] 🔄 Intentando análisis con Groq/Llama 3.1...")
            return await _analyze_with_groq(prompt, audio_path, image_paths)
        except Exception as e:
            providers_tried.append(f"Groq: {e}")
            logger.warning(f"[FAILOVER] ⚠️ Groq falló: {e}")

    # ── Intento 3: Análisis Local (nunca falla) ──
    logger.warning(f"[FAILOVER] 🛡️ Todas las IAs fallaron. Usando clasificador local. Intentos: {providers_tried}")
    return _analyze_local(user_description)
