"""
Módulo de clasificación de imágenes vehiculares.
Usa visión artificial (OpenAI GPT-4o) para analizar fotos y clasificar el incidente.
"""
import google.generativeai as genai
import json
from PIL import Image
from app.config import get_settings
from app.models.enums import IncidentType

settings = get_settings()

if settings.gemini_api_key:
    genai.configure(api_key=settings.gemini_api_key)


async def analyze_image(file_path: str) -> dict:
    """Analiza una imagen del vehículo y clasifica el tipo de daño usando Gemini o OpenAI."""
    # 1. Intentar con Gemini
    if settings.gemini_api_key:
        try:
            model = genai.GenerativeModel("gemini-flash-latest")
            img = Image.open(file_path)
            
            prompt = (
                "Actúa como un experto en peritaje de vehículos. Analiza la imagen adjunta "
                "e identifica el tipo de daño o problema visible. "
                "Responde ÚNICAMENTE en JSON válido con este formato: "
                '{"damage_type": "tire|engine|crash|battery|overheating|other", '
                '"damage_description": "descripción breve del daño", '
                '"severity": "low|medium|high|critical", "confidence": 0.0-1.0}'
            )
            
            response = model.generate_content([prompt, img])
            
            # Limpiar la respuesta de posibles bloques de código markdown
            text = response.text.strip()
            if "```json" in text:
                text = text.split("```json")[1].split("```")[0].strip()
            elif "```" in text:
                text = text.split("```")[1].split("```")[0].strip()
                
            result = json.loads(text)
            
            if 'confidence' in result:
                # Asegurar que confidence esté en rango 0-100 para el frontend
                if result['confidence'] <= 1.0:
                    result['confidence'] = round(result['confidence'] * 100, 2)
            
            print(f"[Gemini] Análisis visual exitoso: {result.get('damage_type')}")
            return result
        except Exception as e:
            print(f"Error en Gemini Image Analysis: {e}")
            # Si falla Gemini y no hay OpenAI, lanzamos el error para no usar Mock 
            # e identificar el problema real en lugar de mostrar datos falsos de batería.
            if not settings.openai_api_key:
                raise e

    # 2. Intentar con OpenAI (GPT-4o)
    if settings.openai_api_key and not settings.openai_api_key.startswith("sk-your"):
        import base64
        with open(file_path, "rb") as f:
            image_data = base64.b64encode(f.read()).decode("utf-8")

        ext = file_path.rsplit(".", 1)[-1].lower()
        mime = {"jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png"}.get(ext, "image/jpeg")

        from openai import OpenAI
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
        return json.loads(response.choices[0].message.content)

    # 3. Fallback a Mock
    return _mock_image_analysis(file_path)


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
    """Análisis simulado de imagen que rota según el segundo actual (para demo)."""
    import datetime
    sec = datetime.datetime.now().second
    
    if sec < 15:
        return {
            "damage_type": "battery",
            "damage_description": "Se observa corrosión en los bornes de la batería y cables desgastados.",
            "severity": "medium", "confidence": 0.85
        }
    elif sec < 30:
        return {
            "damage_type": "overheating",
            "damage_description": "Se observa vapor saliendo del capó y posibles fugas de refrigerante.",
            "severity": "high", "confidence": 0.90
        }
    elif sec < 45:
        return {
            "damage_type": "crash",
            "damage_description": "Daño estructural visible en el parachoques delantero y faro derecho roto.",
            "severity": "high", "confidence": 0.95
        }
    else:
        return {
            "damage_type": "tire",
            "damage_description": "Se observa una llanta totalmente desinflada con daño en el flanco.",
            "severity": "medium", "confidence": 0.88
        }
