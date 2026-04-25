"""
Servicio de gestión de incidentes.
Orquesta el flujo completo: creación, procesamiento IA, asignación y actualización.
"""
import os
import uuid
import pytz
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from fastapi import UploadFile

from app.config import get_settings
from app.models.incident import Incident
from app.models.evidence import Evidence
from app.models.service_history import ServiceHistory
from app.models.vehicle import Vehicle
from app.models.enums import IncidentStatus, EvidenceType, IncidentType
from app.schemas.incident import IncidentCreate, AIAnalysisResult
import asyncio
from app.ai.multimodal_processor import process_multimodal_incident
from app.services.assignment_service import find_best_workshop
from app.utils.geolocation import format_address, get_reverse_geocoding

settings = get_settings()


async def create_incident(
    db: Session,
    user_id: int,
    incident_data: IncidentCreate,
    images: list[UploadFile] | None = None,
    audio: UploadFile | None = None,
) -> Incident:
    """Crea un incidente, procesa evidencias con IA y asigna taller."""

    # 1. Crear incidente base y obtener dirección legible
    human_address = incident_data.address
    if not human_address:
        print(f"[Sistema] Obteniendo dirección legible para {incident_data.latitude}, {incident_data.longitude}...")
        human_address = await get_reverse_geocoding(incident_data.latitude, incident_data.longitude)

    incident = Incident(
        user_id=user_id,
        vehicle_id=incident_data.vehicle_id,
        latitude=incident_data.latitude,
        longitude=incident_data.longitude,
        address=human_address or incident_data.address,
        description=incident_data.description,
        status=IncidentStatus.PENDING,
    )
    db.add(incident)
    db.flush()

    # Registrar en historial
    _add_history(db, incident.id, IncidentStatus.PENDING.value, "Incidente creado", "sistema")

    # 2. Guardar evidencias y preparar rutas
    audio_path = None
    if audio:
        audio_path = await _save_upload(audio, "audio")
        db.add(Evidence(incident_id=incident.id, evidence_type=EvidenceType.AUDIO, file_url=audio_path))
    
    image_paths = []
    if images:
        for img_file in images:
            img_path = await _save_upload(img_file, "images")
            db.add(Evidence(incident_id=incident.id, evidence_type=EvidenceType.IMAGE, file_url=img_path))
            image_paths.append(img_path)

    if incident_data.description:
        db.add(Evidence(incident_id=incident.id, evidence_type=EvidenceType.TEXT, content=incident_data.description))

    # 3. PROCESAMIENTO MAESTRO MULTIMODAL UNIFICADO
    # Obtenemos info del vehículo para contexto
    vehicle_info = None
    if incident_data.vehicle_id:
        vehicle = db.query(Vehicle).filter(Vehicle.id == incident_data.vehicle_id).first()
        if vehicle:
            vehicle_info = f"{vehicle.brand} {vehicle.model} {vehicle.year} - {vehicle.license_plate}"

    ai_result = await process_multimodal_incident(
        audio_path=audio_path,
        image_paths=image_paths,
        user_description=incident_data.description,
        vehicle_info=vehicle_info,
        location_address=incident.address
    )

    # 4. Actualizar incidente con resultados unificados
    incident.incident_type = ai_result.incident_type
    incident.priority = ai_result.priority
    incident.ai_confidence = ai_result.confidence
    incident.ai_summary = ai_result.summary
    incident.ai_classification = ai_result.classification_details
    incident.audio_transcription = ai_result.audio_transcription

    # 5. Asignación inteligente (con retraso simulado para realismo y sinc de UI)
    db.flush()
    await asyncio.sleep(4) # Simula a la IA procesando y permite que Flutter vea el estado "Pendiente"
    assignment = find_best_workshop(db, incident)

    if assignment:
        incident.workshop_id = assignment.workshop_id
        incident.technician_id = assignment.technician_id
        incident.estimated_arrival_minutes = assignment.estimated_arrival_minutes
        incident.status = IncidentStatus.ASSIGNED
        incident.assigned_at = datetime.now(pytz.timezone('America/La_Paz'))

        _add_history(
            db, incident.id, IncidentStatus.ASSIGNED.value,
            f"Asignado a taller #{assignment.workshop_id}, ETA: {assignment.estimated_arrival_minutes} min",
            "sistema",
        )

        from app.services.notification_service import notify_user
        await notify_user(
            db, incident.user_id,
            "🚀 ¡Taller asignado!",
            f"La IA ha encontrado el mejor taller. El técnico llegará en aprox. {assignment.estimated_arrival_minutes} minutos.",
            "incident_assigned",
        )

    db.commit()
    db.refresh(incident)
    return incident


async def update_incident_status(
    db: Session,
    incident: Incident,
    new_status: IncidentStatus,
    notes: str | None = None,
    updated_by: str = "sistema",
) -> Incident:
    """Actualiza el estado de un incidente."""
    incident.status = new_status

    if new_status == IncidentStatus.COMPLETED:
        incident.completed_at = datetime.now(pytz.timezone('America/La_Paz'))

    _add_history(db, incident.id, new_status.value, notes, updated_by)

    db.commit()
    db.refresh(incident)
    return incident


async def _save_upload(file: UploadFile, subfolder: str) -> str:
    """Guarda un archivo subido y retorna la ruta."""
    ext = file.filename.rsplit(".", 1)[-1] if file.filename and "." in file.filename else "bin"
    filename = f"{uuid.uuid4().hex}.{ext}"
    dir_path = os.path.join(settings.upload_dir, subfolder)
    os.makedirs(dir_path, exist_ok=True)
    file_path = os.path.join(dir_path, filename)

    content = await file.read()
    with open(file_path, "wb") as f:
        f.write(content)

    return file_path


def _add_history(db: Session, incident_id: int, status: str, notes: str | None, created_by: str):
    """Agrega un registro al historial de servicio."""
    history = ServiceHistory(
        incident_id=incident_id,
        status=status,
        notes=notes,
        created_by=created_by,
    )
    db.add(history)
