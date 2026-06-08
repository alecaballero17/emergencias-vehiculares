"""
Estimador de costos con IA — Sistema BLINDADO con failover Gemini ↔ Groq.
Nunca devuelve error: si ambas IAs fallan, usa estimador local inteligente.
"""
import json
import logging
import google.generativeai as genai
from app.config import get_settings
from app.schemas.incident import CostEstimateResponse

logger = logging.getLogger("ai.cost_estimator")

settings = get_settings()
if settings.gemini_api_key:
    genai.configure(api_key=settings.gemini_api_key)

# ───────────────────────────────────────────────────────
#  Prompt reutilizable
# ───────────────────────────────────────────────────────
def _build_prompt(description: str, incident_type: str | None) -> str:
    return f"""
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

RESPONDE ÚNICAMENTE EN JSON VÁLIDO (sin bloques markdown ni explicaciones adicionales fuera del JSON):
{{
    "min_cost": (número en bolivianos, precio mínimo estimado),
    "max_cost": (número en bolivianos, precio máximo estimado),
    "min_hours": (número decimal en horas, tiempo mínimo estimado de reparación),
    "max_hours": (número decimal en horas, tiempo máximo estimado de reparación),
    "reasoning": "(explicación breve en español de por qué ese rango de costos y tiempos)"
}}
"""


def _parse_ai_response(text: str, provider: str) -> CostEstimateResponse:
    """Parsea la respuesta JSON de cualquier proveedor de IA."""
    # Limpiar bloques markdown si vienen
    if "```json" in text:
        text = text.split("```json")[1].split("```")[0].strip()
    elif "```" in text:
        text = text.split("```")[1].split("```")[0].strip()

    data = json.loads(text)
    return CostEstimateResponse(
        min_cost=float(data.get("min_cost", 100)),
        max_cost=float(data.get("max_cost", 500)),
        currency="BOB",
        reasoning=data.get("reasoning", f"Estimación basada en IA ({provider})"),
        min_hours=float(data.get("min_hours", 1.0)),
        max_hours=float(data.get("max_hours", 4.0)),
    )


# ───────────────────────────────────────────────────────
#  Proveedor 1: Google Gemini
# ───────────────────────────────────────────────────────
GEMINI_MODELS = [
    "gemini-2.5-flash-lite",
    "gemini-flash-latest",
    "gemini-pro-latest",
]


async def _estimate_with_gemini(description: str, incident_type: str | None) -> CostEstimateResponse:
    """Intenta con múltiples modelos de Gemini (cada uno tiene cuota independiente)."""
    import time

    prompt = _build_prompt(description, incident_type)
    last_error = None

    for model_name in GEMINI_MODELS:
        try:
            logger.info(f"[Gemini] Intentando con modelo: {model_name}")
            model = genai.GenerativeModel(model_name)
            response = model.generate_content(prompt)
            result = _parse_ai_response(response.text.strip(), f"Gemini/{model_name}")
            logger.info(f"[Gemini] ✅ Estimación exitosa con {model_name}")
            return result
        except Exception as e:
            last_error = e
            error_str = str(e)
            if "429" in error_str or "quota" in error_str.lower():
                logger.warning(f"[Gemini] ⚠️ Cuota agotada en {model_name}, probando siguiente...")
                time.sleep(0.5)
                continue
            else:
                logger.error(f"[Gemini] ❌ Error en {model_name}: {e}")
                raise

    raise last_error or Exception("Todos los modelos Gemini agotaron su cuota")


# ───────────────────────────────────────────────────────
#  Proveedor 2: Groq (Llama 3.1)
# ───────────────────────────────────────────────────────
async def _estimate_with_groq(description: str, incident_type: str | None) -> CostEstimateResponse:
    """Usa Groq Llama 3.1 para estimar el rango de costos y tiempos."""
    import httpx

    if not settings.groq_api_key:
        raise ValueError("Groq API Key no configurada en las variables de entorno.")

    prompt = _build_prompt(description, incident_type)

    headers = {
        "Authorization": f"Bearer {settings.groq_api_key}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": "llama-3.1-8b-instant",
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.2,
        "max_tokens": 400,
        "response_format": {"type": "json_object"}
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers=headers,
            json=payload,
            timeout=20.0,
        )
        if response.status_code != 200:
            raise ValueError(f"Groq API returned status {response.status_code}: {response.text}")

        chat_data = response.json()
        text = chat_data["choices"][0]["message"]["content"].strip()
        result = _parse_ai_response(text, "Groq/Llama-3.1")
        logger.info("[Groq] ✅ Estimación exitosa con Llama 3.1")
        return result


# ───────────────────────────────────────────────────────
#  Proveedor 3: Estimador LOCAL inteligente (nunca falla)
# ───────────────────────────────────────────────────────
def _estimate_local(description: str, incident_type: str | None) -> CostEstimateResponse:
    """
    Estimador local basado en reglas y palabras clave.
    No depende de ninguna API externa — es el safety net final.
    """
    desc_lower = (description or "").lower()
    inc_type = (incident_type or "").lower()

    # Reglas por tipo de incidente
    rules = {
        "battery": {"min_cost": 150, "max_cost": 600, "min_hours": 0.5, "max_hours": 2.0,
                     "reasoning": "Problema de batería: revisión, carga o reemplazo de batería. Precios en mercado boliviano."},
        "tire": {"min_cost": 80, "max_cost": 400, "min_hours": 0.5, "max_hours": 2.0,
                 "reasoning": "Pinchazo o daño de llanta: parche, cambio de neumático. Precios en mercado boliviano."},
        "crash": {"min_cost": 500, "max_cost": 8000, "min_hours": 8.0, "max_hours": 120.0,
                  "reasoning": "Accidente/choque: reparación de carrocería, pintura, posibles repuestos importados."},
        "engine": {"min_cost": 300, "max_cost": 5000, "min_hours": 2.0, "max_hours": 48.0,
                   "reasoning": "Falla de motor: diagnóstico, reparación mecánica, posible cambio de piezas."},
        "overheating": {"min_cost": 200, "max_cost": 3000, "min_hours": 1.0, "max_hours": 24.0,
                        "reasoning": "Sobrecalentamiento: revisión de sistema de refrigeración, termostato, radiador."},
        "keys_lost": {"min_cost": 100, "max_cost": 800, "min_hours": 0.5, "max_hours": 4.0,
                      "reasoning": "Llaves perdidas: cerrajería automotriz, duplicado de llave con chip."},
        "keys_locked": {"min_cost": 80, "max_cost": 300, "min_hours": 0.5, "max_hours": 1.5,
                        "reasoning": "Llaves dentro del vehículo: servicio de apertura sin daño."},
    }

    # Detectar por tipo explícito
    if inc_type in rules:
        r = rules[inc_type]
    # Detectar por palabras clave en la descripción
    elif any(w in desc_lower for w in ["batería", "battery", "arranque", "no enciende", "no prende"]):
        r = rules["battery"]
    elif any(w in desc_lower for w in ["llanta", "tire", "pinchazo", "neumático", "rueda"]):
        r = rules["tire"]
    elif any(w in desc_lower for w in ["choque", "crash", "accidente", "colisión", "golpe", "abolladura"]):
        r = rules["crash"]
    elif any(w in desc_lower for w in ["motor", "engine", "aceite", "humo", "ruido"]):
        r = rules["engine"]
    elif any(w in desc_lower for w in ["calentamiento", "overheating", "temperatura", "radiador"]):
        r = rules["overheating"]
    elif any(w in desc_lower for w in ["llave", "keys", "cerrad"]):
        r = rules["keys_locked"]
    else:
        # Estimación genérica
        r = {"min_cost": 150, "max_cost": 2000, "min_hours": 1.0, "max_hours": 24.0,
             "reasoning": "Estimación general basada en el tipo de incidente reportado. Se recomienda inspección presencial para cotización exacta."}

    logger.info("[LOCAL] 🔧 Estimación local inteligente generada (sin API externa)")
    return CostEstimateResponse(
        min_cost=r["min_cost"],
        max_cost=r["max_cost"],
        currency="BOB",
        reasoning=r["reasoning"],
        min_hours=r["min_hours"],
        max_hours=r["max_hours"],
    )


# ───────────────────────────────────────────────────────
#  FUNCIÓN PRINCIPAL — Failover blindado
# ───────────────────────────────────────────────────────
async def estimate_repair_cost(description: str, incident_type: str | None = None) -> CostEstimateResponse:
    """
    Sistema BLINDADO de estimación de costos con triple failover:
      1. Gemini (múltiples modelos)
      2. Groq / Llama 3.1
      3. Estimador local inteligente (nunca falla)
    
    GARANTÍA: siempre retorna un resultado, nunca lanza excepción.
    """
    providers_tried = []

    # ── Intento 1: Gemini ──
    if settings.gemini_api_key:
        try:
            logger.info("[FAILOVER] 🔄 Intentando con Gemini...")
            result = await _estimate_with_gemini(description, incident_type)
            return result
        except Exception as e:
            providers_tried.append(f"Gemini: {e}")
            logger.warning(f"[FAILOVER] ⚠️ Gemini falló: {e}")

    # ── Intento 2: Groq ──
    if settings.groq_api_key:
        try:
            logger.info("[FAILOVER] 🔄 Intentando con Groq/Llama 3.1...")
            result = await _estimate_with_groq(description, incident_type)
            return result
        except Exception as e:
            providers_tried.append(f"Groq: {e}")
            logger.warning(f"[FAILOVER] ⚠️ Groq falló: {e}")

    # ── Intento 3: Estimador Local (nunca falla) ──
    logger.warning(f"[FAILOVER] 🛡️ Ambas IAs fallaron. Usando estimador local. Intentos: {providers_tried}")
    return _estimate_local(description, incident_type)
