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
from app.utils.security import get_current_user

BOL_TZ = pytz.timezone('America/La_Paz')
settings = get_settings()
router = APIRouter(prefix="/api/payments", tags=["Pagos"])


@router.post("/create-intent", response_model=PaymentIntentResponse, status_code=201)
def create_payment_intent(
    data: PaymentIntentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Crear intención de pago (simulación de pasarela Paralela).
    Genera un payment_intent_id único y registra el pago como pendiente.
    """
    incident = db.query(Incident).filter(
        Incident.id == data.incident_id,
        Incident.user_id == current_user.id,
        Incident.tenant_id == current_user.tenant_id,
        Incident.status == IncidentStatus.COMPLETED,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado o no finalizado")

    # Verificar si ya existe pago
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
def confirm_payment(
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
    return payment


@router.post("/{incident_id}", response_model=PaymentResponse, status_code=201)
def create_payment_direct(
    incident_id: int,
    data: PaymentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Pago directo (alternativa a flujo Paralela)."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.user_id == current_user.id,
        Incident.tenant_id == current_user.tenant_id,
        Incident.status == IncidentStatus.COMPLETED,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado o no completado")

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
