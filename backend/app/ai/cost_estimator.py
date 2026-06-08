"""
Estimador de costos con IA — Prompt en español para precios en bolivianos.
"""
import json
import google.generativeai as genai
from app.config import get_settings
from app.schemas.incident import CostEstimateResponse

settings = get_settings()
if settings.gemini_api_key:
    genai.configure(api_key=settings.gemini_api_key)


async def estimate_repair_cost(description: str, incident_type: str | None = None) -> CostEstimateResponse:
    """
    Usa Gemini para estimar un rango de precios en bolivianos (Bs.)
    basado en la descripción del daño y tipo de incidente.
    """
    if not settings.gemini_api_key:
        return CostEstimateResponse(
            min_cost=100, max_cost=500, currency="BOB",
            reasoning="Estimación por defecto: API de IA no configurada"
        )

    try:
        model = genai.GenerativeModel("gemini-2.5-flash-lite")

        prompt = f"""
Eres un experto mecánico automotriz en Bolivia. 
Analiza el siguiente reporte de daño vehicular y estima:
1. Un rango de precios de reparación en BOLIVIANOS (Bs.).
2. Un rango de tiempo estimado de reparación en HORAS de trabajo (por ejemplo, de 1.0 a 4.0 horas para cambiar una llanta, o de 24.0 a 72.0 horas para desabollar/pintar).

DESCRIPCIÓN DEL DAÑO:
{description}

TIPO DE INCIDENTE: {incident_type or 'No especificado'}

Considera:
- Precios de mano de obra en Bolivia (talleres de nivel medio-alto)
- Costo de repuestos comunes en el mercado boliviano y tiempo de importación/consecución
- Si es un daño menor, mayor o catastrófico

RESPONDE ÚNICAMENTE EN JSON VÁLIDO (sin bloques markdown):
{{
    "min_cost": (número en bolivianos, precio mínimo estimado),
    "max_cost": (número en bolivianos, precio máximo estimado),
    "min_hours": (número decimal en horas, tiempo mínimo estimado de reparación),
    "max_hours": (número decimal en horas, tiempo máximo estimado de reparación),
    "reasoning": "(explicación breve en español de por qué ese rango de costos y tiempos)"
}}
"""
        response = model.generate_content(prompt)
        text = response.text.strip()

        if "```json" in text:
            text = text.split("```json")[1].split("```")[0].strip()
        elif "```" in text:
            text = text.split("```")[1].split("```")[0].strip()

        data = json.loads(text)

        return CostEstimateResponse(
            min_cost=float(data.get("min_cost", 100)),
            max_cost=float(data.get("max_cost", 500)),
            currency="BOB",
            reasoning=data.get("reasoning", "Estimación basada en IA"),
            min_hours=float(data.get("min_hours", 1.0)),
            max_hours=float(data.get("max_hours", 4.0)),
        )

    except Exception as e:
        print(f"Error en estimador de costos IA: {e}")
        return CostEstimateResponse(
            min_cost=100, max_cost=800, currency="BOB",
            reasoning=f"Estimación por defecto (error IA: {str(e)[:50]})",
            min_hours=1.0, max_hours=4.0
        )
