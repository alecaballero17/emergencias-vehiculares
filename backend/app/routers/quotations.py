"""Router de cotizaciones: ofertas de talleres y selección por el cliente."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
import pytz
from app.database import get_db
from app.models.user import User
from app.models.workshop import Workshop
from app.models.incident import Incident
from app.models.quotation import Quotation
from app.models.enums import IncidentStatus, QuotationStatus
from app.schemas.incident import QuotationCreate, QuotationResponse
from app.services.notification_service import notify_user, notify_workshop
from app.services.websocket_manager import ws_manager
from app.utils.security import get_current_user, get_current_workshop

BOL_TZ = pytz.timezone('America/La_Paz')
router = APIRouter(prefix="/api/quotations", tags=["Cotizaciones"])


@router.post("/{incident_id}", response_model=QuotationResponse, status_code=201)
async def create_quotation(
    incident_id: int,
    data: QuotationCreate,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Taller envía una cotización para un incidente."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.tenant_id == current_workshop.tenant_id,
        Incident.status.in_([IncidentStatus.SEARCHING, IncidentStatus.ASSIGNED]),
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no disponible para cotización")

    # Verificar que no haya cotizado ya
    existing = db.query(Quotation).filter(
        Quotation.incident_id == incident_id,
        Quotation.workshop_id == current_workshop.id,
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Ya envió una cotización para este incidente")

    quotation = Quotation(
        tenant_id=current_workshop.tenant_id,
        incident_id=incident_id,
        workshop_id=current_workshop.id,
        amount=data.amount,
        estimated_repair_hours=data.estimated_repair_hours,
        estimated_arrival_hours=data.estimated_arrival_hours,
        description=data.description,
    )
    db.add(quotation)
    db.commit()
    db.refresh(quotation)

    # Notificar al usuario por WebSocket
    await ws_manager.send_to_entity("user", incident.user_id, {
        "type": "quotation_received",
        "incident_id": incident_id,
        "quotation_id": quotation.id,
        "workshop_name": current_workshop.name,
        "amount": data.amount,
        "estimated_repair_hours": data.estimated_repair_hours,
        "estimated_arrival_hours": data.estimated_arrival_hours,
    })

    await notify_user(
        db, incident.user_id,
        "💰 Nueva cotización recibida",
        f"El taller {current_workshop.name} cotizó Bs. {data.amount}",
        "quotation_received",
        tenant_id=current_workshop.tenant_id,
    )

    return quotation


@router.get("/{incident_id}", response_model=list[QuotationResponse])
def list_quotations(
    incident_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Cliente ve todas las cotizaciones recibidas para un incidente."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.user_id == current_user.id,
        Incident.tenant_id == current_user.tenant_id,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado")

    return db.query(Quotation).filter(
        Quotation.incident_id == incident_id,
        Quotation.tenant_id == current_user.tenant_id,
    ).order_by(Quotation.amount.asc()).all()


@router.put("/{quotation_id}/accept", response_model=QuotationResponse)
async def accept_quotation(
    quotation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Cliente acepta una cotización. Auto-rechaza las demás y asigna el taller."""
    quotation = db.query(Quotation).filter(
        Quotation.id == quotation_id,
        Quotation.tenant_id == current_user.tenant_id,
        Quotation.status == QuotationStatus.PENDING,
    ).first()
    if not quotation:
        raise HTTPException(status_code=404, detail="Cotización no encontrada")

    # Verificar que el incidente es del usuario
    incident = db.query(Incident).filter(
        Incident.id == quotation.incident_id,
        Incident.user_id == current_user.id,
    ).first()
    if not incident:
        raise HTTPException(status_code=403, detail="No tiene acceso a este incidente")

    # Aceptar esta cotización
    quotation.status = QuotationStatus.ACCEPTED
    quotation.accepted_at = datetime.now(BOL_TZ)

    # Rechazar todas las demás
    db.query(Quotation).filter(
        Quotation.incident_id == quotation.incident_id,
        Quotation.id != quotation_id,
        Quotation.status == QuotationStatus.PENDING,
    ).update({"status": QuotationStatus.REJECTED})

    # Asignar el taller al incidente
    incident.workshop_id = quotation.workshop_id
    from app.services.state_machine import transition_state
    from app.services.incident_service import _add_history

    if incident.status == IncidentStatus.SEARCHING:
        ws_payload = transition_state(incident, IncidentStatus.ASSIGNED)
        _add_history(db, incident.id, current_user.tenant_id, IncidentStatus.ASSIGNED.value,
                     f"Cotización aceptada - Taller #{quotation.workshop_id}", "usuario")
        await ws_manager.broadcast_to_incident(incident.id, ws_payload)

    db.commit()
    db.refresh(quotation)

    # Notificar al taller ganador
    await notify_workshop(
        db, quotation.workshop_id,
        "🎉 ¡Cotización aceptada!",
        f"Tu cotización de Bs. {quotation.amount} fue aceptada para el incidente #{incident.id}",
        "quotation_accepted",
        tenant_id=current_user.tenant_id,
    )

    return quotation


@router.put("/{quotation_id}/reject", response_model=QuotationResponse)
async def reject_quotation(
    quotation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Cliente rechaza una cotización."""
    quotation = db.query(Quotation).filter(
        Quotation.id == quotation_id,
        Quotation.tenant_id == current_user.tenant_id,
        Quotation.status == QuotationStatus.PENDING,
    ).first()
    if not quotation:
        raise HTTPException(status_code=404, detail="Cotización no encontrada")

    quotation.status = QuotationStatus.REJECTED
    db.commit()
    db.refresh(quotation)

    await notify_workshop(
        db, quotation.workshop_id,
        "❌ Cotización rechazada",
        f"Tu cotización fue rechazada para el incidente #{quotation.incident_id}",
        "quotation_rejected",
        tenant_id=current_user.tenant_id,
    )

    return quotation
