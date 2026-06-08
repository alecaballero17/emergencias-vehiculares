"""Router para Asistente de Voz y Reportes de Audio mediante Groq Whisper y Llama3."""
import os
import shutil
import tempfile
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from sqlalchemy.orm import Session
import httpx
from app.database import get_db
from app.config import get_settings
from app.utils.security import get_current_entity
from app.models import (
    Tenant, User, Workshop, Incident, Payment, Vehicle
)
from app.models.enums import UserRole, IncidentStatus, PaymentStatus

settings = get_settings()
router = APIRouter(prefix="/api/ai", tags=["Asistente de Voz IA"])

# Groq API Configuration
GROQ_API_URL = "https://api.groq.com/openai/v1/audio/transcriptions"
GROQ_CHAT_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_API_KEY = settings.groq_api_key


@router.post("/voice-report")
async def generate_voice_report(
    audio: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_entity: dict = Depends(get_current_entity),
):
    """
    Recibe un archivo de audio, lo transcribe con Groq Whisper,
    consulta la base de datos operacional según la consulta,
    y genera una respuesta resumida por IA para ser leída en voz alta.
    """
    if not GROQ_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="La clave de API de Groq no está configurada.",
        )

    # 1. Guardar el archivo de audio subido temporalmente
    suffix = os.path.splitext(audio.filename)[1] or ".wav"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
        shutil.copyfileobj(audio.file, temp_file)
        temp_path = temp_file.name

    try:
        # 2. Enviar a Groq Whisper para transcripción
        async with httpx.AsyncClient() as client:
            with open(temp_path, "rb") as audio_file:
                response = await client.post(
                    GROQ_API_URL,
                    headers={"Authorization": f"Bearer {GROQ_API_KEY}"},
                    files={"file": (audio.filename, audio_file, audio.content_type)},
                    data={"model": "whisper-large-v3", "language": "es"},
                    timeout=30.0,
                )

            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Error en Groq Whisper: {response.text}",
                )

            transcription = response.json().get("text", "").strip()

        if not transcription:
            raise HTTPException(
                status_code=400,
                detail="No se pudo transcribir o entender el audio enviado.",
            )

        # 3. Construir contexto según palabras clave de la transcripción
        text_lower = transcription.lower()
        role = current_entity["role"]
        entity = current_entity["entity"]
        tenant_id = current_entity["tenant_id"]

        context_data = {}

        if any(w in text_lower for w in ["finanz", "ganancia", "pago", "dinero", "monto", "cobr"]):
            # Reporte Financiero
            if role == UserRole.WORKSHOP_ADMIN:
                payments = db.query(Payment).join(Incident).filter(
                    Incident.workshop_id == entity.id,
                    Payment.payment_status == PaymentStatus.COMPLETED,
                    Payment.tenant_id == tenant_id,
                ).all()
                total_earned = sum(p.amount for p in payments)
                context_data = {
                    "report_type": "Financiero del Taller",
                    "total_completed_payments": len(payments),
                    "total_earnings_bob": total_earned,
                    "workshop_name": entity.name,
                }
            elif role == UserRole.ADMIN:
                payments = db.query(Payment).filter(
                    Payment.payment_status == PaymentStatus.COMPLETED
                ).all()
                total_earned = sum(p.amount for p in payments)
                total_commission = sum(p.commission_amount for p in payments)
                context_data = {
                    "report_type": "Financiero Global de la Plataforma",
                    "total_completed_payments": len(payments),
                    "total_revenue_bob": total_earned,
                    "total_commission_bob": total_commission,
                }
            else:
                payments = db.query(Payment).join(Incident).filter(
                    Incident.user_id == entity.id,
                    Payment.payment_status == PaymentStatus.COMPLETED,
                    Payment.tenant_id == tenant_id,
                ).all()
                total_paid = sum(p.amount for p in payments)
                context_data = {
                    "report_type": "Financiero del Cliente",
                    "total_completed_payments": len(payments),
                    "total_spent_bob": total_paid,
                }
        elif any(w in text_lower for w in ["incidente", "emergencia", "choque", "batería", "llanta", "motor", "avería"]):
            # Reporte de Incidentes
            if role == UserRole.WORKSHOP_ADMIN:
                active_incidents = db.query(Incident).filter(
                    Incident.workshop_id == entity.id,
                    Incident.status.notin_([IncidentStatus.COMPLETED, IncidentStatus.CANCELLED]),
                    Incident.tenant_id == tenant_id,
                ).count()
                completed_incidents = db.query(Incident).filter(
                    Incident.workshop_id == entity.id,
                    Incident.status == IncidentStatus.COMPLETED,
                    Incident.tenant_id == tenant_id,
                ).count()
                context_data = {
                    "report_type": "Incidentes del Taller",
                    "active_incidents_count": active_incidents,
                    "completed_incidents_count": completed_incidents,
                    "workshop_name": entity.name,
                }
            elif role == UserRole.ADMIN:
                total_incidents = db.query(Incident).count()
                active_incidents = db.query(Incident).filter(
                    Incident.status.notin_([IncidentStatus.COMPLETED, IncidentStatus.CANCELLED])
                ).count()
                context_data = {
                    "report_type": "Incidentes Globales de la Plataforma",
                    "total_incidents_count": total_incidents,
                    "active_incidents_count": active_incidents,
                }
            else:
                my_active = db.query(Incident).filter(
                    Incident.user_id == entity.id,
                    Incident.status.notin_([IncidentStatus.COMPLETED, IncidentStatus.CANCELLED]),
                    Incident.tenant_id == tenant_id,
                ).count()
                my_completed = db.query(Incident).filter(
                    Incident.user_id == entity.id,
                    Incident.status == IncidentStatus.COMPLETED,
                    Incident.tenant_id == tenant_id,
                ).count()
                context_data = {
                    "report_type": "Incidentes del Cliente",
                    "my_active_incidents": my_active,
                    "my_completed_incidents": my_completed,
                }
        else:
            # Resumen General
            if role == UserRole.WORKSHOP_ADMIN:
                context_data = {
                    "report_type": "General del Taller",
                    "workshop_name": entity.name,
                    "address": entity.address,
                }
            elif role == UserRole.ADMIN:
                tenants_count = db.query(Tenant).count()
                workshops_count = db.query(Workshop).count()
                context_data = {
                    "report_type": "General de la Plataforma (Multi-tenant)",
                    "total_tenants": tenants_count,
                    "total_workshops": workshops_count,
                }
            else:
                vehicles = db.query(Vehicle).filter(
                    Vehicle.user_id == entity.id,
                    Vehicle.tenant_id == tenant_id,
                ).all()
                context_data = {
                    "report_type": "General del Cliente",
                    "client_name": entity.name,
                    "registered_vehicles_count": len(vehicles),
                }

        # 4. Generar respuesta con Groq Llama3 basada en los datos reales del contexto
        system_prompt = (
            "Eres el Asistente de Voz IA oficial de la Plataforma de Emergencias Vehiculares. "
            "A partir de los siguientes datos reales de la base de datos y la transcripción del usuario, "
            "genera una respuesta en español para ser leída en voz alta por un sintetizador de voz (Text-to-Speech). "
            "Responde de forma muy natural, cordial y concisa. Resalta los datos clave e introduce la moneda 'Bolivianos' "
            "si aplica. Mantén la respuesta en 3 o 4 oraciones como máximo."
        )
        user_prompt = (
            f"Consulta del usuario: '{transcription}'\n"
            f"Datos del contexto real: {context_data}"
        )

        async with httpx.AsyncClient() as client:
            chat_response = await client.post(
                GROQ_CHAT_URL,
                headers={
                    "Authorization": f"Bearer {GROQ_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": "llama-3.1-8b-instant",
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt},
                    ],
                    "temperature": 0.3,
                    "max_tokens": 150,
                },
                timeout=30.0,
            )

            if chat_response.status_code != 200:
                raise HTTPException(
                    status_code=chat_response.status_code,
                    detail=f"Error en Groq Chat Completion: {chat_response.text}",
                )

            answer = chat_response.json()["choices"][0]["message"]["content"].strip()

        return {
            "transcription": transcription,
            "answer": answer,
            "context": context_data,
        }

    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=500,
            detail=f"Error al procesar el reporte de voz: {str(e)}",
        )
    finally:
        # Asegurar la eliminación del archivo temporal
        if os.path.exists(temp_path):
            os.remove(temp_path)
