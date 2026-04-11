from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Enum as SAEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
from app.models.enums import PaymentStatus, PaymentMethod


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.id", ondelete="CASCADE"), unique=True, nullable=False)
    amount = Column(Float, nullable=False)
    commission_amount = Column(Float, nullable=False)
    commission_percent = Column(Float, default=10.0)
    payment_status = Column(SAEnum(PaymentStatus), default=PaymentStatus.PENDING)
    payment_method = Column(SAEnum(PaymentMethod), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    paid_at = Column(DateTime(timezone=True), nullable=True)

    # Relaciones
    incident = relationship("Incident", back_populates="payment")
