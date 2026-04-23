from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.models.enums import (
    IncidentType,
    IncidentPriority,
    IncidentStatus,
    EvidenceType,
    PaymentStatus,
    PaymentMethod,
)


# --- Evidence ---
class EvidenceResponse(BaseModel):
    id: int
    incident_id: int
    evidence_type: EvidenceType
    file_url: Optional[str]
    content: Optional[str]
    ai_analysis: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


# --- Service History ---
class ServiceHistoryResponse(BaseModel):
    id: int
    incident_id: int
    status: str
    notes: Optional[str]
    created_by: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


# --- Payment ---
class PaymentCreate(BaseModel):
    amount: float
    payment_method: PaymentMethod


class PaymentResponse(BaseModel):
    id: int
    incident_id: int
    amount: float
    commission_amount: float
    commission_percent: float
    payment_status: PaymentStatus
    payment_method: Optional[PaymentMethod]
    created_at: datetime
    paid_at: Optional[datetime]

    model_config = {"from_attributes": True}


# --- Incident ---
class IncidentCreate(BaseModel):
    vehicle_id: Optional[int] = None
    latitude: float
    longitude: float
    address: Optional[str] = None
    description: Optional[str] = None


class IncidentUpdate(BaseModel):
    status: Optional[IncidentStatus] = None
    notes: Optional[str] = None


class IncidentResponse(BaseModel):
    id: int
    user_id: int
    vehicle_id: Optional[int]
    workshop_id: Optional[int]
    technician_id: Optional[int]
    latitude: float
    longitude: float
    address: Optional[str]
    description: Optional[str]
    audio_transcription: Optional[str]
    incident_type: IncidentType
    priority: IncidentPriority
    status: IncidentStatus
    ai_summary: Optional[str]
    ai_classification: Optional[str]
    ai_confidence: Optional[float]
    estimated_arrival_minutes: Optional[int]
    final_cost: Optional[float]
    created_at: datetime
    updated_at: datetime
    assigned_at: Optional[datetime]
    completed_at: Optional[datetime]

    model_config = {"from_attributes": True}


class IncidentDetail(IncidentResponse):
    evidences: list[EvidenceResponse] = []
    status_history: list[ServiceHistoryResponse] = []
    payment: Optional[PaymentResponse] = None


# --- AI Analysis Result ---
class AIAnalysisResult(BaseModel):
    incident_type: IncidentType
    priority: IncidentPriority
    confidence: float
    summary: str
    classification_details: str
    audio_transcription: Optional[str] = None


# --- Assignment ---
class WorkshopCandidate(BaseModel):
    workshop_id: int
    workshop_name: str
    distance_km: float
    estimated_arrival_minutes: int
    score: float
    specialties: list[str]
    available_technicians: int


class AssignmentResult(BaseModel):
    incident_id: int
    workshop_id: int
    technician_id: Optional[int]
    estimated_arrival_minutes: int
    candidates: list[WorkshopCandidate]


# --- Workshop Actions ---
class IncidentAccept(BaseModel):
    technician_id: Optional[int] = None

class IncidentReject(BaseModel):
    reason: Optional[str] = None

class IncidentComplete(BaseModel):
    final_cost: float
    notes: Optional[str] = None
