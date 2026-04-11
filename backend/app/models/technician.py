from sqlalchemy import Column, Integer, String, Boolean, Float, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class Technician(Base):
    __tablename__ = "technicians"

    id = Column(Integer, primary_key=True, index=True)
    workshop_id = Column(Integer, ForeignKey("workshops.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=False)
    phone = Column(String(20), nullable=True)
    specialties = Column(JSON, default=list)
    is_available = Column(Boolean, default=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relaciones
    workshop = relationship("Workshop", back_populates="technicians")
    incidents = relationship("Incident", back_populates="technician")
