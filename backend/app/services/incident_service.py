"""
Servicio de gestión de incidentes.
Orquesta el flujo completo: creación, procesamiento IA, asignación y actualización.
"""
import os
import uuid
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
from app.ai.audio_processor import transcribe_audio, extract_audio_keywords
from app.ai.image_classifier import analyze_image
from app.ai.incident_classifier import classify_incident
from app.ai.summary_generator import generate_incident_summary
from app.services.assignment_service import find_best_workshop
from app.utils.geolocation import format_address

settings = get_settings()


async def create_incident(
    db: Session,
    user_id: int,
    incident_data: IncidentCreate,
    images: list[UploadFile] | None = None,
    audio: UploadFile | None = None,
) -> Incident:
    """Crea un incidente, procesa evidencias con IA y asigna taller."""

    # 1. Crear incidente base
    incident = Incident(
        user_id=user_id,
        vehicle_id=incident_data.vehicle_id,
        latitude=incident_data.latitude,
        longitude=incident_data.longitude,
        address=incident_data.address,
        description=incident_data.description,
        status=IncidentStatus.PENDING,
    )
    db.add(incident)
    db.flush()

    # Registrar en historial
    _add_history(db, incident.id, IncidentStatus.PENDING.value, "Incidente creado", "sistema")

    # 2. Guardar evidencia de texto
    if incident_data.description:
        text_evidence = Evidence(
            incident_id=incident.id,
            evidence_type=EvidenceType.TEXT,
            content=incident_data.description,
        )
        db.add(text_evidence)

    # 3. Procesar audio
    audio_analysis = None
    if audio:
        audio_path = await _save_upload(audio, "audio")
        audio_evidence = Evidence(
            incident_id=incident.id,
            evidence_type=EvidenceType.AUDIO,
            file_url=audio_path,
        )
        db.add(audio_evidence)

        # Transcribir audio
        transcription = await transcribe_audio(audio_path)
        incident.audio_transcription = transcription
        audio_evidence.content = transcription

        # Extraer keywords del audio
        audio_analysis = await extract_audio_keywords(transcription)
        audio_evidence.ai_analysis = str(audio_analysis)

    # 4. Procesar imágenes
    image_analyses = []
    if images:
        for img_file in images:
            img_path = await _save_upload(img_file, "images")
            img_evidence = Evidence(
                incident_id=incident.id,
                evidence_type=EvidenceType.IMAGE,
                file_url=img_path,
            )
            db.add(img_evidence)

            # Analizar imagen
            img_result = await analyze_image(img_path)
            image_analyses.append(img_result)
            img_evidence.ai_analysis = str(img_result)

    # 5. Clasificación combinada con IA
    ai_result: AIAnalysisResult = await classify_incident(
        text_description=incident_data.description,
        audio_analysis=audio_analysis,
        image_analyses=image_analyses,
    )

    incident.incident_type = ai_result.incident_type
    incident.priority = ai_result.priority
    incident.ai_confidence = ai_result.confidence
    incident.ai_classification = ai_result.classification_details

    # 6. Generar resumen
    vehicle_info = None
    if incident_data.vehicle_id:
        vehicle = db.query(Vehicle).filter(Vehicle.id == incident_data.vehicle_id).first()
        if vehicle:
            vehicle_info = f"{vehicle.brand} {vehicle.model} {vehicle.year} - {vehicle.license_plate}"

    image_descriptions = [img.get("damage_description", "") for img in image_analyses]

    summary = await generate_incident_summary(
        incident_type=ai_result.incident_type,
        priority=ai_result.priority,
        description=incident_data.description,
        audio_transcription=incident.audio_transcription,
        image_descriptions=image_descriptions if image_descriptions else None,
        vehicle_info=vehicle_info,
        location_address=format_address(incident_data.latitude, incident_data.longitude, incident_data.address),
    )
    incident.ai_summary = summary

    # 7. Asignación inteligente
    db.flush()
    assignment = find_best_workshop(db, incident)

    if assignment:
        incident.workshop_id = assignment.workshop_id
        incident.technician_id = assignment.technician_id
        incident.estimated_arrival_minutes = assignment.estimated_arrival_minutes
        incident.status = IncidentStatus.ASSIGNED
        incident.assigned_at = datetime.now(timezone.utc)

        _add_history(
            db, incident.id, IncidentStatus.ASSIGNED.value,
            f"Asignado a taller #{assignment.workshop_id}, ETA: {assignment.estimated_arrival_minutes} min",
            "sistema",
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
        incident.completed_at = datetime.now(timezone.utc)

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
