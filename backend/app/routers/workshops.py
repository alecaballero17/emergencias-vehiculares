"""Router de talleres: gestión de solicitudes, técnicos, estados y tracking."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from typing import Optional
from app.database import get_db
from app.models.workshop import Workshop
from app.models.technician import Technician
from app.models.incident import Incident
from app.models.enums import IncidentStatus
from app.schemas.workshop import WorkshopResponse, WorkshopUpdate, TechnicianCreate, TechnicianUpdate, TechnicianResponse
from app.schemas.incident import (
    IncidentResponse, IncidentDetail, IncidentUpdate,
    IncidentAccept, IncidentReject, IncidentComplete
)
from app.services.incident_service import update_incident_status, _add_history
from app.services.notification_service import notify_user
from app.services.state_machine import transition_state, STATUS_LABELS
from app.services.websocket_manager import ws_manager
from app.utils.security import get_current_workshop
from app.utils.geolocation import haversine_distance, estimate_arrival_minutes

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
        tenant_id=current_workshop.tenant_id,
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
    return db.query(Technician).filter(
        Technician.workshop_id == current_workshop.id,
        Technician.tenant_id == current_workshop.tenant_id,
    ).all()


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
    """Ver solicitudes asignadas al taller (filtrado por tenant)."""
    query = db.query(Incident).filter(
        Incident.workshop_id == current_workshop.id,
        Incident.tenant_id == current_workshop.tenant_id,
    )
    if status:
        query = query.filter(Incident.status == status)
    return query.order_by(Incident.created_at.desc()).all()


@router.get("/incidents/available", response_model=list[IncidentResponse])
def list_available_incidents(
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Ver incidentes en estado 'buscando_taller' del mismo tenant."""
    return (
        db.query(Incident)
        .filter(
            Incident.tenant_id == current_workshop.tenant_id,
            Incident.status == IncidentStatus.SEARCHING,
            Incident.workshop_id.is_(None),
        )
        .order_by(Incident.created_at.desc())
        .all()
    )


@router.get("/incidents/{incident_id}", response_model=IncidentDetail)
def get_workshop_incident_detail(
    incident_id: int,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Ver detalle completo de un incidente (con cotizaciones e historial)."""
    incident = (
        db.query(Incident)
        .options(
            joinedload(Incident.evidences),
            joinedload(Incident.status_history),
            joinedload(Incident.payment),
            joinedload(Incident.quotations),
        )
        .filter(
            Incident.id == incident_id,
            Incident.tenant_id == current_workshop.tenant_id,
        )
        .first()
    )

    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    can_view = (
        incident.status == IncidentStatus.SEARCHING
        or incident.workshop_id == current_workshop.id
    )
    if not can_view:
        raise HTTPException(status_code=403, detail="Este incidente ya está siendo atendido por otro taller")

    return incident


@router.put("/incidents/{incident_id}/accept", response_model=IncidentResponse)
async def accept_incident(
    incident_id: int,
    data: IncidentAccept,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """
    Aceptar un incidente. Transiciona de buscando_taller → taller_asignado.
    Bloquea el incidente y notifica cierre a otros talleres.
    """
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.tenant_id == current_workshop.tenant_id,
    ).first()

    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    if incident.status != IncidentStatus.SEARCHING:
        raise HTTPException(status_code=400, detail=f"Solo se pueden aceptar incidentes en estado 'buscando_taller'. Estado actual: {incident.status.value}")

    # Asignar taller
    incident.workshop_id = current_workshop.id
    if data.technician_id:
        incident.technician_id = data.technician_id

    # Calcular ETA
    distance = haversine_distance(
        incident.latitude, incident.longitude,
        current_workshop.latitude, current_workshop.longitude
    )
    incident.estimated_arrival_minutes = estimate_arrival_minutes(distance)

    # Transicionar a ASSIGNED (taller_asignado)
    ws_payload = transition_state(incident, IncidentStatus.ASSIGNED)

    _add_history(
        db, incident.id, current_workshop.tenant_id,
        IncidentStatus.ASSIGNED.value,
        f"Aceptado por taller {current_workshop.name}",
        f"taller_{current_workshop.id}",
    )

    db.commit()
    db.refresh(incident)

    # Emitir estado a suscritos
    await ws_manager.broadcast_to_incident(incident.id, ws_payload)

    # Notificar cierre de oferta a otros talleres (incidente ya tomado)
    await ws_manager.broadcast_to_workshops([], {
        "type": "incident_taken",
        "incident_id": incident.id,
        "workshop_id": current_workshop.id,
    })

    await notify_user(
        db, incident.user_id,
        "🔧 Tu solicitud fue aceptada",
        f"El taller {current_workshop.name} ha aceptado tu emergencia. ETA: {incident.estimated_arrival_minutes} min",
        "incident_accepted",
        tenant_id=current_workshop.tenant_id,
    )

    return incident


@router.put("/incidents/{incident_id}/reject", response_model=IncidentResponse)
async def reject_incident(
    incident_id: int,
    data: IncidentReject,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Rechazar un incidente. Vuelve a buscando_taller para reasignación."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.workshop_id == current_workshop.id,
        Incident.tenant_id == current_workshop.tenant_id,
        Incident.status == IncidentStatus.ASSIGNED,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    rejection_notes = data.reason if data.reason else "Sin motivo especificado"

    # Desasignar
    incident.workshop_id = None
    incident.technician_id = None
    incident.assigned_at = None

    # Volver a SEARCHING
    ws_payload = transition_state(incident, IncidentStatus.SEARCHING)

    _add_history(
        db, incident.id, current_workshop.tenant_id,
        IncidentStatus.SEARCHING.value,
        f"Rechazado por taller {current_workshop.name}: {rejection_notes}",
        f"taller_{current_workshop.id}",
    )

    db.commit()
    db.refresh(incident)

    await ws_manager.broadcast_to_incident(incident.id, ws_payload)

    await notify_user(
        db, incident.user_id,
        "🔄 Buscando otro taller",
        "Tu solicitud está siendo reasignada a otro taller cercano",
        "incident_reassigning",
        tenant_id=current_workshop.tenant_id,
    )

    return incident


@router.put("/incidents/{incident_id}/en-route", response_model=IncidentResponse)
async def mark_en_route(
    incident_id: int,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Marcar que el mecánico está en camino. taller_asignado → en_camino."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.workshop_id == current_workshop.id,
        Incident.tenant_id == current_workshop.tenant_id,
        Incident.status == IncidentStatus.ASSIGNED,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado o no asignado")

    ws_payload = transition_state(incident, IncidentStatus.EN_ROUTE)

    _add_history(
        db, incident.id, current_workshop.tenant_id,
        IncidentStatus.EN_ROUTE.value,
        f"Mecánico en camino - Taller {current_workshop.name}",
        f"taller_{current_workshop.id}",
    )

    db.commit()
    db.refresh(incident)

    await ws_manager.broadcast_to_incident(incident.id, ws_payload)

    await notify_user(
        db, incident.user_id,
        "🚗 Auxilio en camino",
        f"El mecánico del taller {current_workshop.name} está en camino. ETA: {incident.estimated_arrival_minutes} min",
        "incident_en_route",
        tenant_id=current_workshop.tenant_id,
    )

    return incident


@router.put("/incidents/{incident_id}/arrive", response_model=IncidentResponse)
async def mark_arrived(
    incident_id: int,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Marcar que el mecánico llegó. en_camino → en_atención."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.workshop_id == current_workshop.id,
        Incident.tenant_id == current_workshop.tenant_id,
        Incident.status == IncidentStatus.EN_ROUTE,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado o no en camino")

    ws_payload = transition_state(incident, IncidentStatus.ATTENDING)

    _add_history(
        db, incident.id, current_workshop.tenant_id,
        IncidentStatus.ATTENDING.value,
        f"Mecánico llegó al lugar - Taller {current_workshop.name}",
        f"taller_{current_workshop.id}",
    )

    db.commit()
    db.refresh(incident)

    await ws_manager.broadcast_to_incident(incident.id, ws_payload)

    await notify_user(
        db, incident.user_id,
        "🔧 Mecánico ha llegado",
        f"El mecánico del taller {current_workshop.name} está atendiendo tu vehículo",
        "incident_attending",
        tenant_id=current_workshop.tenant_id,
    )

    return incident


@router.put("/incidents/{incident_id}/complete", response_model=IncidentResponse)
async def complete_incident(
    incident_id: int,
    data: IncidentComplete,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Marcar un incidente como finalizado. en_atención → finalizado."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.workshop_id == current_workshop.id,
        Incident.tenant_id == current_workshop.tenant_id,
        Incident.status == IncidentStatus.ATTENDING,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado o no en atención")

    incident.final_cost = data.final_cost

    ws_payload = transition_state(incident, IncidentStatus.COMPLETED)

    _add_history(
        db, incident.id, current_workshop.tenant_id,
        IncidentStatus.COMPLETED.value,
        data.notes if data.notes else f"Servicio completado por taller {current_workshop.name}",
        f"taller_{current_workshop.id}",
    )

    db.commit()
    db.refresh(incident)

    await ws_manager.broadcast_to_incident(incident.id, ws_payload)

    await notify_user(
        db, incident.user_id,
        "✅ Servicio completado",
        f"El taller {current_workshop.name} ha completado el servicio. Costo: Bs. {data.final_cost}",
        "incident_completed",
        tenant_id=current_workshop.tenant_id,
    )

    return incident
