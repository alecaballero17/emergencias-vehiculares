from sqlalchemy import Column, Integer, String, Boolean, Float, DateTime, JSON, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class Workshop(Base):
    __tablename__ = "workshops"

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    phone = Column(String(20), nullable=True)
    address = Column(String(500), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    is_active = Column(Boolean, default=True)
    capacity = Column(Integer, default=5)
    specialties = Column(JSON, default=list)  # ["battery", "tire", "engine", ...]
    firebase_token = Column(String(500), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relaciones
    tenant = relationship("Tenant", back_populates="workshops")
    technicians = relationship("Technician", back_populates="workshop", cascade="all, delete-orphan")
    incidents = relationship("Incident", back_populates="workshop")
    notifications = relationship("Notification", back_populates="workshop")
    quotations = relationship("Quotation", back_populates="workshop")
