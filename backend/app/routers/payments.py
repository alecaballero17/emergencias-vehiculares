"""Router de pagos con simulación de pasarela Paralela."""
from datetime import datetime
import uuid
import pytz
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.config import get_settings
from app.models.user import User
from app.models.incident import Incident
from app.models.payment import Payment
from app.models.enums import IncidentStatus, PaymentStatus
from app.schemas.incident import (
    PaymentCreate, PaymentResponse,
    PaymentIntentCreate, PaymentIntentResponse,
)
from app.services.notification_service import notify_user, notify_workshop
from app.services.websocket_manager import ws_manager
from app.utils.security import get_current_user

BOL_TZ = pytz.timezone('America/La_Paz')
settings = get_settings()
router = APIRouter(prefix="/api/payments", tags=["Pagos"])


@router.post("/create-intent", response_model=PaymentIntentResponse, status_code=201)
async def create_payment_intent(
    data: PaymentIntentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Crear intención de pago (simulación de pasarela Paralela).
    Genera un payment_intent_id único y registra el pago como pendiente.
    Acepta pagos de incidentes finalizados O penalizaciones por cancelación.
    """
    # Buscar incidente completado O cancelado con penalización
    incident = db.query(Incident).filter(
        Incident.id == data.incident_id,
        Incident.user_id == current_user.id,
        Incident.tenant_id == current_user.tenant_id,
        Incident.status.in_([IncidentStatus.COMPLETED, IncidentStatus.CANCELLED]),
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado o no finalizado/cancelado")

    # Si es cancelado, verificar que tenga penalización
    if incident.status == IncidentStatus.CANCELLED and not incident.cancellation_fee:
        raise HTTPException(status_code=400, detail="Este incidente cancelado no tiene penalización pendiente")

    # Verificar si ya existe pago completado
    existing = db.query(Payment).filter(Payment.incident_id == data.incident_id).first()
    if existing and existing.payment_status == PaymentStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="El pago ya fue realizado")

    intent_id = f"pi_paralela_{uuid.uuid4().hex[:16]}"

    if existing:
        existing.payment_intent_id = intent_id
        existing.amount = data.amount
        existing.payment_method = data.payment_method
        db.commit()
    else:
        commission = data.amount * (settings.platform_commission_percent / 100)
        payment = Payment(
            tenant_id=current_user.tenant_id,
            incident_id=data.incident_id,
            amount=data.amount,
            commission_amount=round(commission, 2),
            commission_percent=settings.platform_commission_percent,
            payment_method=data.payment_method,
            payment_intent_id=intent_id,
            payment_status=PaymentStatus.PENDING,
        )
        db.add(payment)
        db.commit()

    return PaymentIntentResponse(
        payment_intent_id=intent_id,
        status="requires_confirmation",
        amount=data.amount,
        currency="BOB",
    )


@router.post("/confirm/{payment_intent_id}", response_model=PaymentResponse)
async def confirm_payment(
    payment_intent_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Confirmar un pago (simulación de callback de Paralela)."""
    payment = db.query(Payment).filter(
        Payment.payment_intent_id == payment_intent_id,
        Payment.tenant_id == current_user.tenant_id,
    ).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Intención de pago no encontrada")

    if payment.payment_status == PaymentStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="El pago ya fue confirmado")

    payment.payment_status = PaymentStatus.COMPLETED
    payment.paid_at = datetime.now(BOL_TZ)
    db.commit()
    db.refresh(payment)

    # Notificar al taller que el pago fue recibido
    incident = db.query(Incident).filter(Incident.id == payment.incident_id).first()
    if incident and incident.workshop_id:
        is_penalty = incident.status == IncidentStatus.CANCELLED
        title = "💰 Penalización pagada" if is_penalty else "💰 Pago recibido"
        message = (
            f"El cliente pagó la penalización de Bs. {payment.amount} por el incidente #{incident.id}"
            if is_penalty
            else f"Pago de Bs. {payment.amount} confirmado para el incidente #{incident.id}"
        )
        await notify_workshop(
            db, incident.workshop_id, title, message,
            "payment_received", tenant_id=current_user.tenant_id,
        )

        # Enviar por WebSocket también
        payment_payload = {
            "type": "payment_confirmed",
            "incident_id": incident.id,
            "amount": payment.amount,
            "is_penalty": is_penalty,
        }
        await ws_manager.send_to_entity("workshop", incident.workshop_id, payment_payload)
        await ws_manager.broadcast_to_incident(incident.id, payment_payload)

    return payment


@router.post("/{incident_id}", response_model=PaymentResponse, status_code=201)
async def create_payment_direct(
    incident_id: int,
    data: PaymentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Pago directo (alternativa a flujo Paralela). Acepta incidentes finalizados o cancelados con penalización."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.user_id == current_user.id,
        Incident.tenant_id == current_user.tenant_id,
        Incident.status.in_([IncidentStatus.COMPLETED, IncidentStatus.CANCELLED]),
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado o no completado/cancelado")

    if incident.status == IncidentStatus.CANCELLED and not incident.cancellation_fee:
        raise HTTPException(status_code=400, detail="Este incidente cancelado no tiene penalización pendiente")

    if db.query(Payment).filter(Payment.incident_id == incident_id, Payment.payment_status == PaymentStatus.COMPLETED).first():
        raise HTTPException(status_code=400, detail="El pago ya fue realizado")

    commission = data.amount * (settings.platform_commission_percent / 100)

    payment = Payment(
        tenant_id=current_user.tenant_id,
        incident_id=incident_id,
        amount=data.amount,
        commission_amount=round(commission, 2),
        commission_percent=settings.platform_commission_percent,
        payment_method=data.payment_method,
        payment_status=PaymentStatus.COMPLETED,
        paid_at=datetime.now(BOL_TZ),
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)

    # Notificar al taller
    if incident.workshop_id:
        is_penalty = incident.status == IncidentStatus.CANCELLED
        title = "💰 Penalización pagada" if is_penalty else "💰 Pago recibido"
        message = (
            f"El cliente pagó la penalización de Bs. {data.amount} por el incidente #{incident_id}"
            if is_penalty
            else f"Pago de Bs. {data.amount} confirmado para el incidente #{incident_id}"
        )
        await notify_workshop(
            db, incident.workshop_id, title, message,
            "payment_received", tenant_id=current_user.tenant_id,
        )
        payment_payload = {
            "type": "payment_confirmed",
            "incident_id": incident_id,
            "amount": data.amount,
            "is_penalty": is_penalty,
        }
        await ws_manager.send_to_entity("workshop", incident.workshop_id, payment_payload)
        await ws_manager.broadcast_to_incident(incident_id, payment_payload)

    return payment


@router.get("/{incident_id}", response_model=PaymentResponse)
def get_payment(
    incident_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Consultar estado de un pago."""
    payment = db.query(Payment).filter(
        Payment.incident_id == incident_id,
        Payment.tenant_id == current_user.tenant_id,
    ).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Pago no encontrado")

    incident = db.query(Incident).filter(Incident.id == incident_id, Incident.user_id == current_user.id).first()
    if not incident:
        raise HTTPException(status_code=403, detail="No tiene acceso a este pago")

    return payment
