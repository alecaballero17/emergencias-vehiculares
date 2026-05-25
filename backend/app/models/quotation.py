"""Modelo de Cotización - Ofertas de talleres para incidentes."""
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Text, Enum as SAEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
from app.models.enums import QuotationStatus


class Quotation(Base):
    __tablename__ = "quotations"

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.id", ondelete="CASCADE"), nullable=False)
    workshop_id = Column(Integer, ForeignKey("workshops.id"), nullable=False)
    amount = Column(Float, nullable=False)
    estimated_repair_hours = Column(Float, nullable=True)
    description = Column(Text, nullable=True)
    status = Column(SAEnum(QuotationStatus), default=QuotationStatus.PENDING)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    accepted_at = Column(DateTime(timezone=True), nullable=True)

    # Relaciones
    incident = relationship("Incident", back_populates="quotations")
    workshop = relationship("Workshop", back_populates="quotations")
