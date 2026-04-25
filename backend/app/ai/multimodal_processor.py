import google.generativeai as genai
import json
import os
import time
import mimetypes
from PIL import Image
from app.config import get_settings
from app.models.enums import IncidentType, IncidentPriority
from app.schemas.incident import AIAnalysisResult

settings = get_settings()

if settings.gemini_api_key:
    genai.configure(api_key=settings.gemini_api_key)


async def process_multimodal_incident(
    audio_path: str | None = None,
    image_paths: list[str] | None = None,
    user_description: str | None = None,
    vehicle_info: str | None = None,
    location_address: str | None = None
) -> AIAnalysisResult:
    """
    Procesador MAESTRO Multimodal.
    Analiza audio, imágenes y texto en una SOLA llamada a Gemini Flash
    para garantizar coherencia total y máxima velocidad.
    
    - Audio: se envía como bytes inline (evita el problema FAILED del File API).
    - Imágenes: se envían como objetos PIL.
    - Reintento automático: si Google nos da 429 (rate limit), esperamos y reintentamos.
    """
    if not settings.gemini_api_key:
        return AIAnalysisResult(
            incident_type=IncidentType.OTHER,
            priority=IncidentPriority.MEDIUM,
            confidence=0.0,
            summary="Error: No se encontró Gemini API Key",
            classification_details="No configurado"
        )

    try:
        # Lista de modelos con cuotas independientes (20 req/día cada uno en free tier)
        # Si uno se agota, automáticamente probamos el siguiente
        MODELS = [
            "gemini-2.5-flash-lite",
            "gemini-flash-latest",
            "gemini-pro-latest",
        ]

        # 1. Construir el prompt maestro
        prompt = f"""
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

        # 2. Construir la lista de contenidos multimodales
        contents = [prompt]

        # Audio: enviar como bytes inline (NO usar File API para evitar el estado FAILED)
        if audio_path and os.path.exists(audio_path):
            print(f"[Gemini] Preparando audio inline: {audio_path}")
            # IMPORTANTE: los .webm del navegador son AUDIO puro, no video.
            # mimetypes los detecta como video/webm, lo que causa error en Gemini.
            if audio_path.endswith(".webm"):
                mime_type = "audio/webm"
            else:
                mime_type = mimetypes.guess_type(audio_path)[0] or "audio/mpeg"
            with open(audio_path, "rb") as f:
                audio_bytes = f.read()
            contents.append({
                "mime_type": mime_type,
                "data": audio_bytes
            })
            print(f"[Gemini] Audio adjuntado ({len(audio_bytes)} bytes, {mime_type})")

        # Imágenes: enviar como objetos PIL
        if image_paths:
            for i, path in enumerate(image_paths):
                if os.path.exists(path):
                    print(f"[Gemini] Adjuntando imagen {i+1}: {path}")
                    contents.append(Image.open(path))

        # 3. Llamada a Gemini con FALLBACK automático entre modelos
        response = None
        last_error = None
        for model_name in MODELS:
            try:
                model = genai.GenerativeModel(model_name)
                print(f"[Gemini] Usando modelo: {model_name}")
                response = model.generate_content(contents)
                print(f"[Gemini] ✅ Respuesta recibida de {model_name}")
                break  # Éxito
            except Exception as api_error:
                last_error = api_error
                error_str = str(api_error)
                if "429" in error_str:
                    print(f"[Gemini] ⚠️ Cuota agotada en {model_name}, probando siguiente modelo...")
                    time.sleep(1)
                    continue
                else:
                    raise api_error
        
        if response is None:
            raise last_error or Exception("Todos los modelos agotaron su cuota")

        # 4. Procesar Respuesta
        text = response.text.strip()
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0].strip()
        elif "```" in text:
            text = text.split("```")[1].split("```")[0].strip()

        data = json.loads(text)

        # Mapeo a Enum
        try:
            inc_type = IncidentType(data["incident_type"])
        except Exception:
            inc_type = IncidentType.OTHER

        try:
            priority = IncidentPriority(data["priority"])
        except Exception:
            priority = IncidentPriority.MEDIUM

        # Normalizar confianza al rango 0-100
        raw_confidence = data.get("confidence", 0.9)
        confidence = round(raw_confidence * 100, 2) if raw_confidence <= 1.0 else round(raw_confidence, 2)

        print(f"[Gemini] ✅ Análisis maestro completado: {inc_type.value} | Confianza: {confidence}%")

        return AIAnalysisResult(
            incident_type=inc_type,
            priority=priority,
            confidence=confidence,
            summary=data.get("summary", "Sin resumen"),
            audio_transcription=data.get("transcription", "No disponible"),
            classification_details=data.get("details", "Analizado vía multimodal")
        )

    except Exception as e:
        print(f"Error crítico en Multimodal Processor: {e}")
        return AIAnalysisResult(
            incident_type=IncidentType.OTHER,
            priority=IncidentPriority.MEDIUM,
            confidence=0.0,
            summary=f"Error en análisis multimodal: {str(e)}",
            classification_details="Falla en la comunicación con la IA"
        )
