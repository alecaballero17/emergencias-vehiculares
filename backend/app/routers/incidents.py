"""Router de incidentes: creación, consulta, cancelación con recargo."""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Request
from sqlalchemy.orm import Session, joinedload
from typing import Optional
from app.database import get_db
from app.models.user import User
from app.models.incident import Incident
from app.models.payment import Payment
from app.models.enums import IncidentStatus, PaymentStatus
from app.schemas.incident import IncidentCreate, IncidentResponse, IncidentDetail, IncidentUpdate
from app.services.incident_service import create_incident, update_incident_status
from app.services.notification_service import notify_workshop, notify_user
from app.services.state_machine import requires_cancellation_fee, DEFAULT_CANCELLATION_FEE, transition_state
from app.services.websocket_manager import ws_manager
from app.utils.security import get_current_user
from app.middleware.tenant_middleware import get_tenant_id

router = APIRouter(prefix="/api/incidents", tags=["Incidentes"])


@router.post("/", response_model=IncidentResponse, status_code=201)
async def report_incident(
    request: Request,
    latitude: float = Form(...),
    longitude: float = Form(...),
    vehicle_id: Optional[int] = Form(None),
    address: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    local_uuid: Optional[str] = Form(None),
    requires_tow_truck: bool = Form(False),
    images: list[UploadFile] = File(default=[]),
    audio: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Reportar una nueva emergencia vehicular.
    Acepta datos multimodales: texto, imágenes, audio y ubicación.
    Soporta local_uuid para idempotencia (sincronización offline).
    """
    tenant_id = current_user.tenant_id

    incident_data = IncidentCreate(
        vehicle_id=vehicle_id,
        latitude=latitude,
        longitude=longitude,
        address=address,
        description=description,
        local_uuid=local_uuid,
        requires_tow_truck=requires_tow_truck,
    )

    incident = await create_incident(
        db=db,
        user_id=current_user.id,
        tenant_id=tenant_id,
        incident_data=incident_data,
        images=images if images else None,
        audio=audio,
    )

    return incident


@router.get("/", response_model=list[IncidentResponse])
def list_my_incidents(
    status: Optional[IncidentStatus] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Listar incidentes del usuario actual (filtrado por tenant)."""
    query = (
        db.query(Incident)
        .options(joinedload(Incident.payment))
        .filter(
            Incident.user_id == current_user.id,
            Incident.tenant_id == current_user.tenant_id,
        )
    )
    if status:
        query = query.filter(Incident.status == status)
    return query.order_by(Incident.created_at.desc()).all()


@router.get("/{incident_id}", response_model=IncidentDetail)
def get_incident_detail(
    incident_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Obtener detalle completo de un incidente con evidencias, historial y cotizaciones."""
    incident = (
        db.query(Incident)
        .options(
            joinedload(Incident.evidences),
            joinedload(Incident.status_history),
            joinedload(Incident.payment),
            joinedload(Incident.quotations),
            joinedload(Incident.workshop),
        )
        .filter(
            Incident.id == incident_id,
            Incident.user_id == current_user.id,
            Incident.tenant_id == current_user.tenant_id,
        )
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
    """
    Cancelar un incidente.
    Si el estado es 'en_camino' o 'en_atencion', se aplica recargo de reconocimiento.
    """
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.user_id == current_user.id,
        Incident.tenant_id == current_user.tenant_id,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    # Verificar si requiere recargo
    needs_fee = requires_cancellation_fee(incident.status)
    fee = DEFAULT_CANCELLATION_FEE if needs_fee else None

    try:
        ws_payload = transition_state(incident, IncidentStatus.CANCELLED, cancellation_fee=fee)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    # Si hay recargo, crear el pago obligatorio
    if needs_fee and fee:
        payment = Payment(
            tenant_id=current_user.tenant_id,
            incident_id=incident.id,
            amount=fee,
            commission_amount=0,
            commission_percent=0,
            cancellation_fee=fee,
            payment_status=PaymentStatus.PENDING,
        )
        db.add(payment)

    from app.services.incident_service import _add_history
    notes = f"Cancelado por el usuario"
    if needs_fee:
        notes += f" (recargo de reconocimiento: Bs. {fee})"
    _add_history(db, incident.id, current_user.tenant_id, IncidentStatus.CANCELLED.value, notes, "usuario")

    db.commit()
    db.refresh(incident)

    # Emitir por WebSocket
    await ws_manager.broadcast_to_incident(incident.id, ws_payload)

    if incident.workshop_id:
        await notify_workshop(
            db, incident.workshop_id,
            "❌ Incidente cancelado",
            f"El incidente #{incident.id} fue cancelado por el usuario" + (f". Recargo aplicado: Bs. {fee}" if fee else ""),
            "incident_cancelled",
            tenant_id=current_user.tenant_id,
        )
    else:
        # Notificar a todos los talleres del tenant para que actualicen su listado
        from app.models.workshop import Workshop
        workshops = db.query(Workshop).filter(Workshop.tenant_id == current_user.tenant_id).all()
        w_ids = [w.id for w in workshops]
        await ws_manager.broadcast_to_workshops(w_ids, {
            "type": "incident_cancelled_broadcast",
            "incident_id": incident.id
        })

    return incident
