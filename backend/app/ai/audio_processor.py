"""
Módulo de procesamiento de audio.
Convierte audio a texto y extrae información relevante usando OpenAI Whisper API.
"""
import os
from openai import OpenAI
from app.config import get_settings

settings = get_settings()


async def transcribe_audio(file_path: str) -> str:
    """Transcribe un archivo de audio a texto usando OpenAI Whisper."""
    if not settings.openai_api_key or settings.openai_api_key.startswith("sk-your"):
        return _mock_transcription(file_path)

    client = OpenAI(api_key=settings.openai_api_key)
    with open(file_path, "rb") as audio_file:
        transcription = client.audio.transcriptions.create(
            model="whisper-1",
            file=audio_file,
            language="es",
        )
    return transcription.text


async def extract_audio_keywords(transcription: str) -> dict:
    """Extrae palabras clave del audio transcrito para clasificación."""
    if not settings.openai_api_key or settings.openai_api_key.startswith("sk-your"):
        return _mock_keyword_extraction(transcription)

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
    import json
    return json.loads(response.choices[0].message.content)


def _mock_transcription(file_path: str) -> str:
    """Transcripción simulada cuando no hay API key configurada."""
    return (
        "Mi auto no enciende, creo que es un problema con la batería. "
        "Estoy en un estacionamiento y necesito ayuda urgente."
    )


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
