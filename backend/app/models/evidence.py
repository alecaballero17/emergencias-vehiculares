from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text, Enum as SAEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
from app.database import Base
from app.models.enums import EvidenceType


class Evidence(Base):
    __tablename__ = "evidences"

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.id", ondelete="CASCADE"), nullable=False)
    evidence_type = Column(SAEnum(EvidenceType), nullable=False)
    file_url = Column(String(500), nullable=True)
    content = Column(Text, nullable=True)  # Para texto, o transcripción de audio
    ai_analysis = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.now)

    # Relaciones
    incident = relationship("Incident", back_populates="evidences")
