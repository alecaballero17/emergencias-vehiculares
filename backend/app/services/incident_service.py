"""
Servicio de gestión de incidentes.
Orquesta: creación, procesamiento IA, alertas WebSocket por especialidad/geolocalización,
máquina de estados, y sincronización offline.
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
from app.ai.multimodal_processor import process_multimodal_incident
from app.services.assignment_service import find_nearby_workshops_by_specialty
from app.services.state_machine import transition_state, STATUS_LABELS, STATUS_EMOJIS
from app.services.websocket_manager import ws_manager
from app.utils.geolocation import format_address, get_reverse_geocoding

settings = get_settings()
BOL_TZ = pytz.timezone('America/La_Paz')


async def create_incident(
    db: Session,
    user_id: int,
    tenant_id: int,
    incident_data: IncidentCreate,
    images: list[UploadFile] | None = None,
    audio: UploadFile | None = None,
) -> Incident:
    """Crea un incidente, procesa con IA, y envía alertas WebSocket a talleres relevantes."""

    # Idempotencia: si viene un local_uuid, verificar que no exista ya
    if incident_data.local_uuid:
        existing = db.query(Incident).filter(
            Incident.local_uuid == incident_data.local_uuid
        ).first()
        if existing:
            return existing  # Ya fue sincronizado previamente

    # 1. Obtener dirección legible
    human_address = incident_data.address
    if not human_address:
        human_address = await get_reverse_geocoding(incident_data.latitude, incident_data.longitude)

    # 2. Crear incidente en estado PENDING
    incident = Incident(
        tenant_id=tenant_id,
        user_id=user_id,
        vehicle_id=incident_data.vehicle_id,
        latitude=incident_data.latitude,
        longitude=incident_data.longitude,
        address=human_address or incident_data.address,
        description=incident_data.description,
        status=IncidentStatus.PENDING,
        local_uuid=incident_data.local_uuid,
    )
    db.add(incident)
    db.flush()

    _add_history(db, incident.id, tenant_id, IncidentStatus.PENDING.value, "Incidente creado", "sistema")

    # 3. Guardar evidencias
    audio_path = None
    if audio:
        audio_path = await _save_upload(audio, "audio")
        db.add(Evidence(tenant_id=tenant_id, incident_id=incident.id, evidence_type=EvidenceType.AUDIO, file_url=audio_path))

    image_paths = []
    if images:
        for img_file in images:
            img_path = await _save_upload(img_file, "images")
            db.add(Evidence(tenant_id=tenant_id, incident_id=incident.id, evidence_type=EvidenceType.IMAGE, file_url=img_path))
            image_paths.append(img_path)

    if incident_data.description:
        db.add(Evidence(tenant_id=tenant_id, incident_id=incident.id, evidence_type=EvidenceType.TEXT, content=incident_data.description))

    # 4. Transicionar a SEARCHING (buscando_taller)
    ws_payload = transition_state(incident, IncidentStatus.SEARCHING)
    _add_history(db, incident.id, tenant_id, IncidentStatus.SEARCHING.value, "Buscando talleres cercanos", "sistema")

    # 5. Procesamiento IA multimodal
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

    # 6. Actualizar incidente con resultados IA
    incident.incident_type = ai_result.incident_type
    incident.priority = ai_result.priority
    incident.ai_confidence = ai_result.confidence
    incident.ai_summary = ai_result.summary
    incident.ai_classification = ai_result.classification_details
    incident.audio_transcription = ai_result.audio_transcription
    if ai_result.cost_estimate_min:
        incident.ai_cost_estimate_min = ai_result.cost_estimate_min
    if ai_result.cost_estimate_max:
        incident.ai_cost_estimate_max = ai_result.cost_estimate_max

    db.flush()

    # 7. Enviar alertas WebSocket a talleres del MISMO tenant, filtrados por geolocalización y especialidad
    candidates = find_nearby_workshops_by_specialty(db, incident, tenant_id)
    if candidates:
        workshop_ids = [c.workshop_id for c in candidates]
        alert_payload = {
            "type": "new_incident_alert",
            "incident_id": incident.id,
            "incident_type": incident.incident_type.value,
            "priority": incident.priority.value,
            "latitude": incident.latitude,
            "longitude": incident.longitude,
            "address": incident.address,
            "description": incident.description,
            "ai_summary": incident.ai_summary,
            "cost_estimate_min": incident.ai_cost_estimate_min,
            "cost_estimate_max": incident.ai_cost_estimate_max,
        }
        await ws_manager.broadcast_to_workshops(workshop_ids, alert_payload)

    db.commit()
    db.refresh(incident)

    # Suscribir al usuario al incidente por WebSocket
    ws_manager.subscribe_to_incident("user", user_id, incident.id)

    return incident


async def update_incident_status(
    db: Session,
    incident: Incident,
    new_status: IncidentStatus,
    notes: str | None = None,
    updated_by: str = "sistema",
) -> Incident:
    """Actualiza el estado con la máquina de estados y emite WebSocket."""
    ws_payload = transition_state(incident, new_status)

    _add_history(db, incident.id, incident.tenant_id, new_status.value, notes, updated_by)

    db.commit()
    db.refresh(incident)

    # Emitir cambio de estado a todos los suscritos al incidente
    await ws_manager.broadcast_to_incident(incident.id, ws_payload)

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


def _add_history(db: Session, incident_id: int, tenant_id: int, status: str, notes: str | None, created_by: str):
    """Agrega un registro al historial de servicio."""
    history = ServiceHistory(
        tenant_id=tenant_id,
        incident_id=incident_id,
        status=status,
        notes=notes,
        created_by=created_by,
    )
    db.add(history)
