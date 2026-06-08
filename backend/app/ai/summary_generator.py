"""
Módulo de generación de resúmenes automáticos de incidentes — BLINDADO.
Failover: Gemini → Groq/Llama 3.1 → OpenAI → Resumen local.
Crea fichas estructuradas del incidente para los talleres.
"""
import logging
from app.config import get_settings
from app.models.enums import IncidentType, IncidentPriority

logger = logging.getLogger("ai.summary_generator")

settings = get_settings()

TYPE_LABELS = {
    IncidentType.BATTERY: "Problema de batería",
    IncidentType.TIRE: "Pinchazo / Llanta dañada",
    IncidentType.CRASH: "Accidente / Choque",
    IncidentType.ENGINE: "Falla de motor",
    IncidentType.OTHER: "Otro problema",
}

import google.generativeai as genai

if settings.gemini_api_key:
    genai.configure(api_key=settings.gemini_api_key)

# Modelos de Gemini con cuotas independientes
GEMINI_MODELS = [
    "gemini-2.5-flash-lite",
    "gemini-flash-latest",
    "gemini-pro-latest",
]


def _build_prompt_content(
    incident_type: IncidentType,
    priority: IncidentPriority,
    description: str | None,
    audio_transcription: str | None,
    image_descriptions: list[str] | None,
    vehicle_info: str | None,
    location_address: str | None,
) -> str:
    """Construye el contenido del prompt reutilizable."""
    prompt_parts = [
        f"Tipo de incidente: {TYPE_LABELS.get(incident_type, 'Desconocido')}",
        f"Prioridad: {priority.value}",
    ]
    if description:
        prompt_parts.append(f"Descripción del usuario: {description}")
    if audio_transcription:
        prompt_parts.append(f"Transcripción de audio: {audio_transcription}")
    if image_descriptions:
        for i, desc in enumerate(image_descriptions, 1):
            prompt_parts.append(f"Análisis de imagen {i}: {desc}")
    if vehicle_info:
        prompt_parts.append(f"Vehículo: {vehicle_info}")
    if location_address:
        prompt_parts.append(f"Ubicación: {location_address}")
    return "\n".join(prompt_parts)


SYSTEM_INSTRUCTION = (
    "Genera una FICHA TÉCNICA DE INTERVENCIÓN extremadamente concisa para un mecánico.\n"
    "Usa este formato exacto:\n"
    "🚨 **SITUACIÓN:** (Resumen en 1 oración)\n"
    "🛠️ **DIAGNÓSTICO PROBABLE:** (2-3 puntos clave)\n"
    "🧰 **RECOMENDACIÓN TÉCNICA:** (Herramientas o pasos iniciales)\n\n"
)


# ───────────────────────────────────────────────────────
#  Proveedor 1: Gemini (múltiples modelos)
# ───────────────────────────────────────────────────────
async def _summarize_with_gemini(prompt_content: str) -> str:
    """Intenta con múltiples modelos Gemini."""
    import time
    last_error = None

    for model_name in GEMINI_MODELS:
        try:
            logger.info(f"[Gemini] Generando resumen con {model_name}...")
            model = genai.GenerativeModel(model_name)
            response = model.generate_content(
                SYSTEM_INSTRUCTION + f"DATOS:\n{prompt_content}"
            )
            logger.info(f"[Gemini] ✅ Resumen generado con {model_name}")
            return response.text.strip()
        except Exception as e:
            last_error = e
            error_str = str(e)
            if "429" in error_str or "quota" in error_str.lower():
                logger.warning(f"[Gemini] ⚠️ Cuota agotada en {model_name}, probando siguiente...")
                time.sleep(0.5)
                continue
            else:
                raise e

    raise last_error or Exception("Todos los modelos Gemini agotaron su cuota")


# ───────────────────────────────────────────────────────
#  Proveedor 2: Groq / Llama 3.1
# ───────────────────────────────────────────────────────
async def _summarize_with_groq(prompt_content: str) -> str:
    """Usa Groq Llama 3.1 para generar el resumen."""
    import httpx

    if not settings.groq_api_key:
        raise ValueError("Groq API Key no configurada")

    headers = {
        "Authorization": f"Bearer {settings.groq_api_key}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": "llama-3.1-8b-instant",
        "messages": [
            {
                "role": "system",
                "content": (
                    "Eres un coordinador de emergencias vehiculares experto. "
                    "Genera una ficha técnica de intervención concisa para el mecánico. "
                    "Usa emojis para cada sección: 🚨 SITUACIÓN, 🛠️ DIAGNÓSTICO PROBABLE, 🧰 RECOMENDACIÓN TÉCNICA."
                ),
            },
            {"role": "user", "content": f"DATOS DEL INCIDENTE:\n{prompt_content}"},
        ],
        "temperature": 0.3,
        "max_tokens": 400,
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers=headers,
            json=payload,
            timeout=20.0,
        )
        if response.status_code != 200:
            raise ValueError(f"Groq API status {response.status_code}: {response.text}")

        answer = response.json()["choices"][0]["message"]["content"].strip()
        logger.info("[Groq] ✅ Resumen generado con Llama 3.1")
        return answer


# ───────────────────────────────────────────────────────
#  Proveedor 3: OpenAI (legacy)
# ───────────────────────────────────────────────────────
async def _summarize_with_openai(prompt_content: str) -> str:
    """Usa OpenAI como fallback adicional."""
    from openai import OpenAI

    if not settings.openai_api_key or settings.openai_api_key.startswith("sk-your"):
        raise ValueError("OpenAI API Key no configurada")

    client = OpenAI(api_key=settings.openai_api_key)
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres un coordinador de emergencias vehiculares. "
                    "Genera una ficha de resumen estructurada y concisa del incidente para el taller mecánico asignado. "
                    "La ficha debe ser clara, profesional y contener toda la información relevante."
                ),
            },
            {"role": "user", "content": prompt_content},
        ],
        max_tokens=600,
    )
    logger.info("[OpenAI] ✅ Resumen generado con GPT-4o-mini")
    return response.choices[0].message.content


# ───────────────────────────────────────────────────────
#  FUNCIÓN PRINCIPAL — Failover blindado
# ───────────────────────────────────────────────────────
async def generate_incident_summary(
    incident_type: IncidentType,
    priority: IncidentPriority,
    description: str | None,
    audio_transcription: str | None,
    image_descriptions: list[str] | None,
    vehicle_info: str | None,
    location_address: str | None,
) -> str:
    """
    Genera un resumen completo del incidente con CUÁDRUPLE FAILOVER:
      1. Gemini (múltiples modelos)
      2. Groq / Llama 3.1
      3. OpenAI / GPT-4o-mini
      4. Resumen local (nunca falla)

    GARANTÍA: siempre retorna un resumen, nunca lanza excepción.
    """
    prompt_content = _build_prompt_content(
        incident_type, priority, description,
        audio_transcription, image_descriptions,
        vehicle_info, location_address,
    )
    providers_tried = []

    # ── Intento 1: Gemini ──
    if settings.gemini_api_key:
        try:
            return await _summarize_with_gemini(prompt_content)
        except Exception as e:
            providers_tried.append(f"Gemini: {e}")
            logger.warning(f"[FAILOVER] ⚠️ Gemini falló para resumen: {e}")

    # ── Intento 2: Groq ──
    if settings.groq_api_key:
        try:
            return await _summarize_with_groq(prompt_content)
        except Exception as e:
            providers_tried.append(f"Groq: {e}")
            logger.warning(f"[FAILOVER] ⚠️ Groq falló para resumen: {e}")

    # ── Intento 3: OpenAI ──
    if settings.openai_api_key and not settings.openai_api_key.startswith("sk-your"):
        try:
            return await _summarize_with_openai(prompt_content)
        except Exception as e:
            providers_tried.append(f"OpenAI: {e}")
            logger.warning(f"[FAILOVER] ⚠️ OpenAI falló para resumen: {e}")

    # ── Intento 4: Resumen local (nunca falla) ──
    logger.warning(f"[FAILOVER] 🛡️ Todas las IAs fallaron para resumen. Usando local. Intentos: {providers_tried}")
    return _build_local_summary(
        incident_type, priority, description,
        audio_transcription, image_descriptions,
        vehicle_info, location_address,
    )


def _build_local_summary(
    incident_type: IncidentType,
    priority: IncidentPriority,
    description: str | None,
    audio_transcription: str | None,
    image_descriptions: list[str] | None,
    vehicle_info: str | None,
    location_address: str | None,
) -> str:
    """Genera un resumen local sin usar IA externa."""
    lines = [
        "═══ FICHA DE INCIDENTE ═══",
        f"",
        f"🔧 Tipo: {TYPE_LABELS.get(incident_type, 'Desconocido')}",
        f"🔴 Prioridad: {priority.value.upper()}",
    ]

    if vehicle_info:
        lines.append(f"🚗 Vehículo: {vehicle_info}")
    if location_address:
        lines.append(f"📍 Ubicación: {location_address}")

    lines.append("")
    lines.append("── Información del incidente ──")

    if description:
        lines.append(f"📝 Descripción: {description}")
    if audio_transcription:
        lines.append(f"🎙️ Audio: {audio_transcription}")
    if image_descriptions:
        for i, desc in enumerate(image_descriptions, 1):
            lines.append(f"📸 Imagen {i}: {desc}")

    lines.append("")
    lines.append("── Recomendaciones ──")
    lines.append(_get_recommendations(incident_type))

    return "\n".join(lines)


def _get_recommendations(incident_type: IncidentType) -> str:
    """Retorna recomendaciones según el tipo de incidente."""
    recs = {
        IncidentType.BATTERY: "Llevar cables de arranque o batería de respaldo. Verificar alternador.",
        IncidentType.TIRE: "Llevar llanta de repuesto, gato hidráulico y herramientas. Verificar kit de parches.",
        IncidentType.CRASH: "Evaluar daño estructural. Verificar si el vehículo puede moverse. Considerar grúa.",
        IncidentType.ENGINE: "Llevar herramientas de diagnóstico OBD. Verificar niveles de fluidos. Si hay sobrecalentamiento, llevar refrigerante y herramientas (no abrir radiador caliente).",
        IncidentType.OTHER: "Llevar kit básico de herramientas. Si es cerrajería, llevar equipo de apertura o llaves de repuesto. Evaluar la situación al llegar.",
    }
    return recs.get(incident_type, recs[IncidentType.OTHER])
