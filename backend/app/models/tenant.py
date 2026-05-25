"""Modelo de Tenant para arquitectura multi-tenant SaaS."""
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class Tenant(Base):
    __tablename__ = "tenants"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    slug = Column(String(100), unique=True, index=True, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relaciones
    users = relationship("User", back_populates="tenant")
    workshops = relationship("Workshop", back_populates="tenant")
    incidents = relationship("Incident", back_populates="tenant")

    def __repr__(self):
        return f"<Tenant {self.slug}: {self.name}>"
