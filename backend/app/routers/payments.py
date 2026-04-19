from datetime import datetime, timezone
import pytz
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.config import get_settings
from app.models.user import User
from app.models.workshop import Workshop
from app.models.incident import Incident
from app.models.payment import Payment
from app.models.enums import IncidentStatus, PaymentStatus
from app.schemas.incident import PaymentCreate, PaymentResponse
from app.utils.security import get_current_user

settings = get_settings()
router = APIRouter(prefix="/api/payments", tags=["Pagos"])


@router.post("/{incident_id}", response_model=PaymentResponse, status_code=201)
def create_payment(
    incident_id: int,
    data: PaymentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Realizar pago por un servicio completado."""
    incident = db.query(Incident).filter(
        Incident.id == incident_id,
        Incident.user_id == current_user.id,
        Incident.status == IncidentStatus.COMPLETED,
    ).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incidente no encontrado o no completado")

    if db.query(Payment).filter(Payment.incident_id == incident_id).first():
        raise HTTPException(status_code=400, detail="El pago ya fue realizado")

    commission = data.amount * (settings.platform_commission_percent / 100)

    payment = Payment(
        incident_id=incident_id,
        amount=data.amount,
        commission_amount=round(commission, 2),
        commission_percent=settings.platform_commission_percent,
        payment_method=data.payment_method,
        payment_status=PaymentStatus.COMPLETED,
        paid_at=datetime.now(pytz.timezone('America/La_Paz')),
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
    payment = db.query(Payment).filter(Payment.incident_id == incident_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Pago no encontrado")

    # Verificar que el usuario es dueño del incidente
    incident = db.query(Incident).filter(Incident.id == incident_id, Incident.user_id == current_user.id).first()
    if not incident:
        raise HTTPException(status_code=403, detail="No tiene acceso a este pago")

    return payment
