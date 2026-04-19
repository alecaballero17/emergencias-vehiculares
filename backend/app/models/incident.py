from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Text, Enum as SAEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
from app.models.enums import IncidentType, IncidentPriority, IncidentStatus


class Incident(Base):
    __tablename__ = "incidents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    vehicle_id = Column(Integer, ForeignKey("vehicles.id"), nullable=True)
    workshop_id = Column(Integer, ForeignKey("workshops.id"), nullable=True)
    technician_id = Column(Integer, ForeignKey("technicians.id"), nullable=True)

    # Ubicación
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    address = Column(String(500), nullable=True)

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

    # Servicio
    estimated_arrival_minutes = Column(Integer, nullable=True)
    final_cost = Column(Float, nullable=True)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    assigned_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)

    # Relaciones
    user = relationship("User", back_populates="incidents", foreign_keys=[user_id])
    vehicle = relationship("Vehicle", back_populates="incidents")
    workshop = relationship("Workshop", back_populates="incidents")
    technician = relationship("Technician", back_populates="incidents")
    evidences = relationship("Evidence", back_populates="incident", cascade="all, delete-orphan")
    status_history = relationship("ServiceHistory", back_populates="incident", cascade="all, delete-orphan")
    payment = relationship("Payment", back_populates="incident", uselist=False)
