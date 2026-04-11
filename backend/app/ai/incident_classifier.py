"""
Módulo de clasificación de incidentes.
Combina información multimodal (texto, audio, imágenes) para determinar
tipo, prioridad y generar un diagnóstico preliminar.
"""
from app.models.enums import IncidentType, IncidentPriority
from app.schemas.incident import AIAnalysisResult


PRIORITY_MAP = {
    IncidentType.CRASH: IncidentPriority.HIGH,
    IncidentType.OVERHEATING: IncidentPriority.HIGH,
    IncidentType.ENGINE: IncidentPriority.HIGH,
    IncidentType.BATTERY: IncidentPriority.MEDIUM,
    IncidentType.TIRE: IncidentPriority.MEDIUM,
    IncidentType.KEYS_LOST: IncidentPriority.LOW,
    IncidentType.KEYS_LOCKED: IncidentPriority.LOW,
    IncidentType.OTHER: IncidentPriority.MEDIUM,
}

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


async def classify_incident(
    text_description: str | None = None,
    audio_analysis: dict | None = None,
    image_analyses: list[dict] | None = None,
) -> AIAnalysisResult:
    """
    Clasifica un incidente combinando múltiples fuentes de datos.
    Retorna tipo, prioridad, confianza y resumen generado.
    """
    votes: dict[str, float] = {}
    total_confidence = 0.0
    details_parts = []

    # Análisis de texto
    if text_description:
        text_type = _classify_from_text(text_description)
        votes[text_type] = votes.get(text_type, 0) + 0.3
        total_confidence += 0.3
        details_parts.append(f"Texto: clasificado como {text_type}")

    # Análisis de audio
    if audio_analysis:
        audio_type = audio_analysis.get("probable_type", "other")
        weight = 0.35
        votes[audio_type] = votes.get(audio_type, 0) + weight
        total_confidence += weight
        details_parts.append(f"Audio: clasificado como {audio_type}")

    # Análisis de imágenes
    if image_analyses:
        for img in image_analyses:
            img_type = img.get("damage_type", "other")
            img_conf = img.get("confidence", 0.5)
            weight = 0.35 * img_conf
            votes[img_type] = votes.get(img_type, 0) + weight
            total_confidence += weight
        details_parts.append(f"Imágenes: {len(image_analyses)} analizadas")

    # Determinar tipo ganador
    if votes:
        winner = max(votes, key=votes.get)
        try:
            incident_type = IncidentType(winner)
        except ValueError:
            incident_type = IncidentType.OTHER
        confidence = min(votes[winner] / max(total_confidence, 0.01), 1.0)
    else:
        incident_type = IncidentType.OTHER
        confidence = 0.0

    # Determinar prioridad
    priority = PRIORITY_MAP.get(incident_type, IncidentPriority.MEDIUM)

    # Si la confianza es baja, indicar incertidumbre
    if confidence < 0.4:
        priority = IncidentPriority.MEDIUM
        details_parts.append("⚠️ Clasificación incierta, se recomienda revisión manual")

    summary = _generate_summary(incident_type, priority, confidence, text_description, audio_analysis, image_analyses)

    return AIAnalysisResult(
        incident_type=incident_type,
        priority=priority,
        confidence=round(confidence, 2),
        summary=summary,
        classification_details=" | ".join(details_parts) if details_parts else "Sin datos suficientes",
    )


def _classify_from_text(text: str) -> str:
    """Clasifica basándose en palabras clave del texto."""
    text_lower = text.lower()
    keyword_map = {
        "battery": ["batería", "no enciende", "no arranca", "arranque", "eléctric"],
        "tire": ["llanta", "neumático", "pinchazo", "ponchad", "rueda", "rin"],
        "crash": ["choque", "accidente", "golpe", "colisión", "impacto", "volcadura"],
        "engine": ["motor", "falla mecánica", "aceite", "ruido extraño", "vibración"],
        "overheating": ["sobrecalentamiento", "temperatura", "humo", "vapor", "radiador", "caliente"],
        "keys_lost": ["perdí la llave", "llave perdida", "no encuentro llave", "sin llave"],
        "keys_locked": ["llave dentro", "cerré con llave adentro", "quedó la llave"],
    }

    for incident_type, keywords in keyword_map.items():
        for kw in keywords:
            if kw in text_lower:
                return incident_type
    return "other"


def _generate_summary(
    incident_type: IncidentType,
    priority: IncidentPriority,
    confidence: float,
    text: str | None,
    audio: dict | None,
    images: list[dict] | None,
) -> str:
    """Genera un resumen estructurado del incidente."""
    parts = [
        f"📋 **Tipo de incidente**: {TYPE_LABELS.get(incident_type, 'Desconocido')}",
        f"🔴 **Prioridad**: {priority.value.upper()}",
        f"📊 **Confianza de IA**: {confidence:.0%}",
    ]

    if text:
        parts.append(f"📝 **Descripción del usuario**: {text[:200]}")

    if audio:
        keywords = audio.get("keywords", [])
        if keywords:
            parts.append(f"🎙️ **Palabras clave del audio**: {', '.join(keywords)}")

    if images:
        for i, img in enumerate(images, 1):
            desc = img.get("damage_description", "Sin descripción")
            parts.append(f"📸 **Imagen {i}**: {desc}")

    return "\n".join(parts)
