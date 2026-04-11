"""Router de incidentes: creación, consulta y actualización de emergencias."""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session, joinedload
from typing import Optional
from app.database import get_db
from app.models.user import User
from app.models.incident import Incident
from app.models.enums import IncidentStatus
from app.schemas.incident import IncidentCreate, IncidentResponse, IncidentDetail, IncidentUpdate
from app.services.incident_service import create_incident, update_incident_status
from app.services.notification_service import notify_workshop, notify_user
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/incidents", tags=["Incidentes"])


@router.post("/", response_model=IncidentResponse, status_code=201)
async def report_incident(
    latitude: float = Form(...),
    longitude: float = Form(...),
    vehicle_id: Optional[int] = Form(None),
    address: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    images: list[UploadFile] = File(default=[]),
    audio: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Reportar una nueva emergencia vehicular.
    Acepta datos multimodales: texto, imágenes, audio y ubicación.
    El sistema procesará automáticamente con IA y asignará un taller.
    """
    incident_data = IncidentCreate(
        vehicle_id=vehicle_id,
        latitude=latitude,
        longitude=longitude,
        address=address,
        description=description,
    )

    incident = await create_incident(
        db=db,
        user_id=current_user.id,
        incident_data=incident_data,
        images=images if images else None,
        audio=audio,
    )

    # Notificar al taller asignado
    if incident.workshop_id:
        await notify_workshop(
            db, incident.workshop_id,
            "🚨 Nueva emergencia asignada",
            f"Incidente #{incident.id}: {incident.incident_type.value} - Prioridad {incident.priority.value}",
            "incident_new",
        )

    return incident


@router.get("/", response_model=list[IncidentResponse])
def list_my_incidents(
    status: Optional[IncidentStatus] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Listar incidentes del usuario actual."""
    query = db.query(Incident).filter(Incident.user_id == current_user.id)
    if status:
        query = query.filter(Incident.status == status)
    return query.order_by(Incident.created_at.desc()).all()


@router.get("/{incident_id}", response_model=IncidentDetail)
def get_incident_detail(
    incident_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Obtener detalle completo de un incidente con evidencias e historial."""
    incident = (
        db.query(Incident)
        .options(
            joinedload(Incident.evidences),
            joinedload(Incident.status_history),
            joinedload(Incident.payment),
        )
        .filter(Incident.id == incident_id, Incident.user_id == current_user.id)
        .first()
    )
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")
    return incident


@router.put("/{incident_id}/cancel", response_model=IncidentResponse)
async def cancel_incident(
    incident_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Cancelar un incidente (solo si está pendiente o asignado)."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.user_id == current_user.id,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    if incident.status not in [IncidentStatus.PENDING, IncidentStatus.ASSIGNED]:
        raise HTTPException(status_code=400, detail="No se puede cancelar un incidente en este estado")

    incident = await update_incident_status(db, incident, IncidentStatus.CANCELLED, "Cancelado por el usuario", "usuario")

    if incident.workshop_id:
        await notify_workshop(
            db, incident.workshop_id,
            "❌ Incidente cancelado",
            f"El incidente #{incident.id} fue cancelado por el usuario",
            "incident_cancelled",
        )

    return incident
