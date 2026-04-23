"""
Módulo de generación de resúmenes automáticos de incidentes.
Crea fichas estructuradas del incidente para los talleres.
"""
from openai import OpenAI
from app.config import get_settings
from app.models.enums import IncidentType, IncidentPriority

settings = get_settings()

TYPE_LABELS = {
    IncidentType.BATTERY: "Problema de batería",
    IncidentType.TIRE: "Pinchazo / Llanta dañada",
    IncidentType.CRASH: "Accidente / Choque",
    IncidentType.ENGINE: "Falla de motor",
    IncidentType.OVERHEATING: "Sobrecalentamiento",
    IncidentType.KEYS_LOST: "Llave perdida",
    IncidentType.KEYS_LOCKED: "Llave dentro del vehículo",
    IncidentType.OTHER: "Otro problema",
}


import google.generativeai as genai

if settings.gemini_api_key:
    genai.configure(api_key=settings.gemini_api_key)


async def generate_incident_summary(
    incident_type: IncidentType,
    priority: IncidentPriority,
    description: str | None,
    audio_transcription: str | None,
    image_descriptions: list[str] | None,
    vehicle_info: str | None,
    location_address: str | None,
) -> str:
    """Genera un resumen completo y estructurado del incidente usando IA (Gemini o OpenAI)."""
    
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

    prompt_content = "\n".join(prompt_parts)

    # 1. Intentar con Gemini
    if settings.gemini_api_key:
        try:
            model = genai.GenerativeModel("gemini-flash-latest")
            response = model.generate_content(
                "Genera una FICHA TÉCNICA DE INTERVENCIÓN extremadamente concisa para un mecánico.\n"
                "Usa este formato exacto:\n"
                "🚨 **SITUACIÓN:** (Resumen en 1 oración)\n"
                "🛠️ **DIAGNÓSTICO PROBABLE:** (2-3 puntos clave)\n"
                "🧰 **RECOMENDACIÓN TÉCNICA:** (Herramientas o pasos iniciales)\n\n"
                f"DATOS:\n{prompt_content}"
            )
            print("[Gemini] Generación de resumen técnico exitosa")
            return response.text.strip()
        except Exception as e:
            print(f"Error en Gemini Summary: {e}")

    # 2. Intentar con OpenAI
    if settings.openai_api_key and not settings.openai_api_key.startswith("sk-your"):
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
        return response.choices[0].message.content

    # 3. Fallback a resumen local
    return _build_local_summary(
        incident_type, priority, description, audio_transcription, image_descriptions, vehicle_info, location_address
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
        IncidentType.ENGINE: "Llevar herramientas de diagnóstico OBD. Verificar niveles de fluidos.",
        IncidentType.OVERHEATING: "Llevar refrigerante y herramientas. No abrir radiador caliente.",
        IncidentType.KEYS_LOST: "Llevar equipo de cerrajería automotriz. Verificar tipo de llave.",
        IncidentType.KEYS_LOCKED: "Llevar kit de apertura vehicular. Verificar modelo del vehículo.",
        IncidentType.OTHER: "Llevar kit básico de herramientas. Evaluar la situación al llegar.",
    }
    return recs.get(incident_type, recs[IncidentType.OTHER])
