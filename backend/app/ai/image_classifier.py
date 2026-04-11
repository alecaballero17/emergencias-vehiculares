"""
Módulo de clasificación de imágenes vehiculares.
Usa visión artificial (OpenAI GPT-4o) para analizar fotos y clasificar el incidente.
"""
import base64
from openai import OpenAI
from app.config import get_settings
from app.models.enums import IncidentType

settings = get_settings()


async def analyze_image(file_path: str) -> dict:
    """Analiza una imagen del vehículo y clasifica el tipo de daño."""
    if not settings.openai_api_key or settings.openai_api_key.startswith("sk-your"):
        return _mock_image_analysis(file_path)

    with open(file_path, "rb") as f:
        image_data = base64.b64encode(f.read()).decode("utf-8")

    ext = file_path.rsplit(".", 1)[-1].lower()
    mime = {"jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png"}.get(ext, "image/jpeg")

    client = OpenAI(api_key=settings.openai_api_key)
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "system",
                "content": (
                    "Eres un experto en diagnóstico vehicular visual. "
                    "Analiza la imagen del vehículo y responde SOLO en JSON con: "
                    "damage_type (battery|tire|crash|engine|overheating|keys_lost|keys_locked|other), "
                    "damage_description (descripción breve del daño visible), "
                    "severity (low|medium|high|critical), "
                    "confidence (0.0 a 1.0)"
                ),
            },
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "Analiza esta imagen de un vehículo con problemas:"},
                    {"type": "image_url", "image_url": {"url": f"data:{mime};base64,{image_data}"}},
                ],
            },
        ],
        response_format={"type": "json_object"},
        max_tokens=500,
    )
    import json
    return json.loads(response.choices[0].message.content)


async def classify_damage_from_images(image_analyses: list[dict]) -> dict:
    """Consolida los análisis de múltiples imágenes en una clasificación final."""
    if not image_analyses:
        return {
            "damage_type": "other",
            "damage_description": "No se proporcionaron imágenes",
            "severity": "medium",
            "confidence": 0.0,
        }

    # Tomar el análisis con mayor confianza
    best = max(image_analyses, key=lambda x: x.get("confidence", 0))
    return best


def _mock_image_analysis(file_path: str) -> dict:
    """Análisis simulado de imagen cuando no hay API key."""
    return {
        "damage_type": "tire",
        "damage_description": "Se observa una llanta desinflada en el lado derecho del vehículo",
        "severity": "medium",
        "confidence": 0.78,
    }
