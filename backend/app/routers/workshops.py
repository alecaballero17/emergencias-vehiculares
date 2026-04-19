"""Router de talleres: gestión de solicitudes, técnicos y operaciones."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from typing import Optional
from app.database import get_db
from app.models.workshop import Workshop
from app.models.technician import Technician
from app.models.incident import Incident
from app.models.enums import IncidentStatus
from app.schemas.workshop import WorkshopResponse, WorkshopUpdate, TechnicianCreate, TechnicianUpdate, TechnicianResponse
from app.schemas.incident import IncidentResponse, IncidentDetail, IncidentUpdate
from app.services.incident_service import update_incident_status
from app.services.notification_service import notify_user
from app.utils.security import get_current_workshop

router = APIRouter(prefix="/api/workshops", tags=["Talleres"])


# === Perfil del taller ===
@router.get("/me", response_model=WorkshopResponse)
def get_workshop_profile(current_workshop: Workshop = Depends(get_current_workshop)):
    """Obtener perfil del taller actual."""
    return current_workshop


@router.put("/me", response_model=WorkshopResponse)
def update_workshop_profile(
    data: WorkshopUpdate,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Actualizar perfil del taller."""
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(current_workshop, field, value)
    db.commit()
    db.refresh(current_workshop)
    return current_workshop


# === Gestión de técnicos ===
@router.post("/technicians", response_model=TechnicianResponse, status_code=201)
def add_technician(
    data: TechnicianCreate,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Agregar un nuevo técnico al taller."""
    tech = Technician(
        workshop_id=current_workshop.id,
        name=data.name,
        phone=data.phone,
        specialties=data.specialties,
    )
    db.add(tech)
    db.commit()
    db.refresh(tech)
    return tech


@router.get("/technicians", response_model=list[TechnicianResponse])
def list_technicians(db: Session = Depends(get_db), current_workshop: Workshop = Depends(get_current_workshop)):
    """Listar técnicos del taller."""
    return db.query(Technician).filter(Technician.workshop_id == current_workshop.id).all()


@router.put("/technicians/{tech_id}", response_model=TechnicianResponse)
def update_technician(
    tech_id: int,
    data: TechnicianUpdate,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Actualizar datos de un técnico."""
    tech = db.query(Technician).filter(
        Technician.id == tech_id,
        Technician.workshop_id == current_workshop.id,
    ).first()
    if not tech:
        raise HTTPException(status_code=404, detail="Técnico no encontrado")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(tech, field, value)
    db.commit()
    db.refresh(tech)
    return tech


@router.delete("/technicians/{tech_id}", status_code=204)
def remove_technician(
    tech_id: int,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Eliminar un técnico del taller."""
    tech = db.query(Technician).filter(
        Technician.id == tech_id,
        Technician.workshop_id == current_workshop.id,
    ).first()
    if not tech:
        raise HTTPException(status_code=404, detail="Técnico no encontrado")
    db.delete(tech)
    db.commit()


# === Gestión de solicitudes/incidentes ===
@router.get("/incidents", response_model=list[IncidentResponse])
def list_workshop_incidents(
    status: Optional[IncidentStatus] = None,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Ver solicitudes asignadas al taller."""
    query = db.query(Incident).filter(Incident.workshop_id == current_workshop.id)
    if status:
        query = query.filter(Incident.status == status)
    return query.order_by(Incident.created_at.desc()).all()


@router.get("/incidents/available", response_model=list[IncidentResponse])
def list_available_incidents(
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Ver incidentes pendientes sin taller asignado (disponibles para tomar)."""
    return (
        db.query(Incident)
        .filter(Incident.status == IncidentStatus.PENDING, Incident.workshop_id.is_(None))
        .order_by(Incident.created_at.desc())
        .all()
    )


@router.get("/incidents/{incident_id}", response_model=IncidentDetail)
def get_workshop_incident_detail(
    incident_id: int,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Ver detalle completo de un incidente asignado (con información IA)."""
    incident = (
        db.query(Incident)
        .options(
            joinedload(Incident.evidences),
            joinedload(Incident.status_history),
            joinedload(Incident.payment),
        )
        .filter(Incident.id == incident_id)
        .first()
    )
    
    # Optimización para defensa: Permitir ver el detalle si está PENDING (disponible)
    # o si está asignado a este taller. 
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")
        
    # Permitir ver si está disponible para todos (PENDING) o si es suyo
    can_view = (incident.status == IncidentStatus.PENDING) or (incident.workshop_id == current_workshop.id)
    
    if not can_view:
         raise HTTPException(status_code=403, detail="Este incidente ya está siendo atendido por otro taller")
         
    return incident


@router.put("/incidents/{incident_id}/accept", response_model=IncidentResponse)
async def accept_incident(
    incident_id: int,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Aceptar una solicitud de incidente (cambia estado a en_proceso)."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.workshop_id == current_workshop.id,
        Incident.status == IncidentStatus.ASSIGNED,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado o no asignado a este taller")

    incident = await update_incident_status(
        db, incident, IncidentStatus.IN_PROGRESS,
        f"Aceptado por taller {current_workshop.name}",
        f"taller_{current_workshop.id}",
    )

    await notify_user(
        db, incident.user_id,
        "🔧 Tu solicitud fue aceptada",
        f"El taller {current_workshop.name} está en camino. ETA: {incident.estimated_arrival_minutes} min",
        "incident_accepted",
    )

    return incident


@router.put("/incidents/{incident_id}/reject", response_model=IncidentResponse)
async def reject_incident(
    incident_id: int,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Rechazar una solicitud (el incidente vuelve a pendiente para reasignación)."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.workshop_id == current_workshop.id,
        Incident.status == IncidentStatus.ASSIGNED,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    incident.workshop_id = None
    incident.technician_id = None
    incident.status = IncidentStatus.PENDING
    incident.assigned_at = None

    from app.services.incident_service import _add_history
    _add_history(db, incident.id, "pending", f"Rechazado por taller {current_workshop.name}", f"taller_{current_workshop.id}")
    db.commit()
    db.refresh(incident)

    await notify_user(
        db, incident.user_id,
        "🔄 Buscando otro taller",
        "Tu solicitud está siendo reasignada a otro taller cercano",
        "incident_reassigning",
    )

    return incident


@router.put("/incidents/{incident_id}/complete", response_model=IncidentResponse)
async def complete_incident(
    incident_id: int,
    final_cost: float | None = None,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Marcar un incidente como completado."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.workshop_id == current_workshop.id,
        Incident.status == IncidentStatus.IN_PROGRESS,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado o no en proceso")

    if final_cost is not None:
        incident.final_cost = final_cost

    incident = await update_incident_status(
        db, incident, IncidentStatus.COMPLETED,
        f"Servicio completado por taller {current_workshop.name}",
        f"taller_{current_workshop.id}",
    )

    await notify_user(
        db, incident.user_id,
        "✅ Servicio completado",
        f"El taller {current_workshop.name} ha completado el servicio",
        "incident_completed",
    )

    return incident
