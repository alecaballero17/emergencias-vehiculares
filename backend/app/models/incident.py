from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Text, Enum as SAEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
from app.database import Base
from app.models.enums import IncidentType, IncidentPriority, IncidentStatus


class Incident(Base):
    __tablename__ = "incidents"

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    vehicle_id = Column(Integer, ForeignKey("vehicles.id"), nullable=True)
    workshop_id = Column(Integer, ForeignKey("workshops.id"), nullable=True)
    technician_id = Column(Integer, ForeignKey("technicians.id"), nullable=True)

    # Ubicación
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    address = Column(Text, nullable=True)

    # Descripción
    description = Column(Text, nullable=True)
    audio_transcription = Column(Text, nullable=True)

    # Clasificación IA
    incident_type = Column(SAEnum(IncidentType), default=IncidentType.OTHER)
    priority = Column(SAEnum(IncidentPriority), default=IncidentPriority.MEDIUM)
    status = Column(SAEnum(IncidentStatus), default=IncidentStatus.PENDING, index=True)
    ai_summary = Column(Text, nullable=True)
    ai_classification = Column(Text, nullable=True)
    ai_confidence = Column(Float, nullable=True)
    ai_cost_estimate_min = Column(Float, nullable=True)
    ai_cost_estimate_max = Column(Float, nullable=True)

    # Servicio
    estimated_arrival_minutes = Column(Integer, nullable=True)
    final_cost = Column(Float, nullable=True)
    cancellation_fee = Column(Float, nullable=True)

    # Idempotencia offline
    local_uuid = Column(String(100), nullable=True, unique=True, index=True)

    # Timestamps de la máquina de estados
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    searching_at = Column(DateTime(timezone=True), nullable=True)
    assigned_at = Column(DateTime(timezone=True), nullable=True)
    en_route_at = Column(DateTime(timezone=True), nullable=True)
    attending_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    cancelled_at = Column(DateTime(timezone=True), nullable=True)

    # Relaciones
    tenant = relationship("Tenant", back_populates="incidents")
    user = relationship("User", back_populates="incidents", foreign_keys=[user_id])
    vehicle = relationship("Vehicle", back_populates="incidents")
    workshop = relationship("Workshop", back_populates="incidents")
    technician = relationship("Technician", back_populates="incidents")
    evidences = relationship("Evidence", back_populates="incident", cascade="all, delete-orphan")
    status_history = relationship("ServiceHistory", back_populates="incident", cascade="all, delete-orphan")
    payment = relationship("Payment", back_populates="incident", uselist=False)
    quotations = relationship("Quotation", back_populates="incident", cascade="all, delete-orphan")
