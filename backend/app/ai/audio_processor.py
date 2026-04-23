"""
Módulo de procesamiento de audio.
Convierte audio a texto y extrae información relevante usando OpenAI Whisper API.
"""
import os
import google.generativeai as genai
import json
from app.config import get_settings

settings = get_settings()

if settings.gemini_api_key:
    genai.configure(api_key=settings.gemini_api_key)


async def transcribe_audio(file_path: str) -> str:
    """Transcribe un archivo de audio a texto usando Gemini o OpenAI."""
    # 1. Intentar con Gemini (Gratis y Multimodal)
    if settings.gemini_api_key:
        try:
            model = genai.GenerativeModel("gemini-flash-latest")
            with open(file_path, "rb") as f:
                audio_data = f.read()
            
            # Determinar mime_type
            mime_type = "audio/mpeg" if file_path.endswith(".mp3") else "audio/wav"
            
            response = model.generate_content([
                {"mime_type": mime_type, "data": audio_data},
                "Transcribe únicamente este audio a texto en español. "
                "No añadas comentarios, solo el texto transcrito."
            ])
            print("[Gemini] Transcripción de audio exitosa")
            return response.text.strip()
        except Exception as e:
            print(f"Error en Gemini Transcription: {e}")

    # 2. Intentar con OpenAI (Si está configurado)
    if settings.openai_api_key and not settings.openai_api_key.startswith("sk-your"):
        client = OpenAI(api_key=settings.openai_api_key)
        with open(file_path, "rb") as audio_file:
            transcription = client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file,
                language="es",
            )
        return transcription.text

    # 3. Fallback a Mock
    return _mock_transcription(file_path)


async def extract_audio_keywords(transcription: str) -> dict:
    """Extrae palabras clave del audio transcrito para clasificación."""
    # 1. Intentar con Gemini
    if settings.gemini_api_key:
        try:
            model = genai.GenerativeModel("gemini-flash-latest")
            prompt = (
                "Eres un experto en diagnóstico vehicular. Analiza la siguiente transcripción "
                "de una emergencia y extrae información estructurada. "
                "Responde ÚNICAMENTE en JSON válido con este formato: "
                '{"keywords": ["palabra1", "palabra2"], '
                '"probable_type": "battery|tire|crash|engine|keys_lost|keys_locked|overheating|other", '
                '"severity": "low|medium|high|critical"}'
                f"\n\nTranscripción: {transcription}"
            )
            response = model.generate_content(prompt)
            # Limpiar posibles bloques de código markdown
            json_text = response.text.replace("```json", "").replace("```", "").strip()
            print("[Gemini] Extracción de keywords exitosa")
            return json.loads(json_text)
        except Exception as e:
            print(f"Error en Gemini Keywords: {e}")

    # 2. Intentar con OpenAI
    if settings.openai_api_key and not settings.openai_api_key.startswith("sk-your"):
        client = OpenAI(api_key=settings.openai_api_key)
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Eres un asistente que analiza descripciones de problemas vehiculares. "
                        "Extrae las palabras clave y clasifica el tipo de problema. "
                        "Responde SOLO en formato JSON con los campos: "
                        "keywords (lista de palabras clave), "
                        "probable_type (battery|tire|crash|engine|keys_lost|keys_locked|overheating|other), "
                        "severity (low|medium|high|critical)"
                    ),
                },
                {"role": "user", "content": transcription},
            ],
            response_format={"type": "json_object"},
        )
        return json.loads(response.choices[0].message.content)

    # 3. Fallback a Mock
    return _mock_keyword_extraction(transcription)


def _mock_transcription(file_path: str) -> str:
    """Transcripción simulada que rota según el segundo actual (para demo)."""
    import datetime
    sec = datetime.datetime.now().second
    
    if sec < 15:
        return "Hola, mi auto no arranca. Creo que es la batería, las luces están muy tenues."
    elif sec < 30:
        return "Tengo humo saliendo del motor y la temperatura subió al máximo. Necesito ayuda."
    elif sec < 45:
        return "Acabo de tener un choque leve en la esquina, el parachoques se soltó y no puedo mover el auto."
    else:
        return "Se me pinchó una llanta en plena avenida y no tengo la llave de cruz para cambiarla."


def _mock_keyword_extraction(transcription: str) -> dict:
    """Extracción simulada de keywords."""
    text_lower = transcription.lower()
    keywords = []
    type_map = {
        "batería": "battery",
        "no enciende": "battery",
        "llanta": "tire",
        "pinchazo": "tire",
        "ponchada": "tire",
        "choque": "crash",
        "accidente": "crash",
        "golpe": "crash",
        "motor": "engine",
        "sobrecalentamiento": "overheating",
        "temperatura": "overheating",
        "llave": "keys_lost",
    }

    probable_type = "other"
    for keyword, incident_type in type_map.items():
        if keyword in text_lower:
            keywords.append(keyword)
            probable_type = incident_type

    return {
        "keywords": keywords or ["problema vehicular"],
        "probable_type": probable_type,
        "severity": "medium",
    }
