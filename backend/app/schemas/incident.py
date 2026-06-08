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
    QuotationStatus,
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
    cancellation_fee: float
    payment_status: PaymentStatus
    payment_method: Optional[PaymentMethod]
    payment_intent_id: Optional[str]
    created_at: datetime
    paid_at: Optional[datetime]

    model_config = {"from_attributes": True}


# --- Quotation ---
class QuotationCreate(BaseModel):
    amount: float
    estimated_repair_hours: Optional[float] = None
    estimated_arrival_hours: Optional[float] = None
    description: Optional[str] = None


class QuotationResponse(BaseModel):
    id: int
    incident_id: int
    workshop_id: int
    tenant_id: int
    amount: float
    estimated_repair_hours: Optional[float]
    estimated_arrival_hours: Optional[float]
    description: Optional[str]
    status: QuotationStatus
    created_at: datetime
    accepted_at: Optional[datetime]

    model_config = {"from_attributes": True}


# --- Cost Estimate AI ---
class CostEstimateRequest(BaseModel):
    description: str
    incident_type: Optional[str] = None


class CostEstimateResponse(BaseModel):
    min_cost: float
    max_cost: float
    currency: str = "BOB"
    reasoning: str
    min_hours: Optional[float] = None
    max_hours: Optional[float] = None


# --- Payment Intent (Paralela Simulation) ---
class PaymentIntentCreate(BaseModel):
    incident_id: int
    amount: float
    payment_method: PaymentMethod = PaymentMethod.PARALELA


class PaymentIntentResponse(BaseModel):
    payment_intent_id: str
    status: str
    amount: float
    currency: str = "BOB"


# --- Incident ---
class IncidentCreate(BaseModel):
    vehicle_id: Optional[int] = None
    latitude: float
    longitude: float
    address: Optional[str] = None
    description: Optional[str] = None
    local_uuid: Optional[str] = None  # Para idempotencia offline
    requires_tow_truck: Optional[bool] = False


class IncidentUpdate(BaseModel):
    status: Optional[IncidentStatus] = None
    notes: Optional[str] = None


class IncidentResponse(BaseModel):
    id: int
    tenant_id: int
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
    ai_cost_estimate_min: Optional[float]
    ai_cost_estimate_max: Optional[float]
    estimated_arrival_minutes: Optional[int]
    final_cost: Optional[float] = None
    cancellation_fee: Optional[float]
    local_uuid: Optional[str]
    requires_tow_truck: Optional[bool] = False
    created_at: datetime
    updated_at: datetime
    searching_at: Optional[datetime]
    assigned_at: Optional[datetime]
    en_route_at: Optional[datetime]
    attending_at: Optional[datetime]
    completed_at: Optional[datetime]
    cancelled_at: Optional[datetime]
    payment: Optional[PaymentResponse] = None

    model_config = {"from_attributes": True}


from app.schemas.workshop import WorkshopResponse


class IncidentDetail(IncidentResponse):
    evidences: list[EvidenceResponse] = []
    status_history: list[ServiceHistoryResponse] = []
    quotations: list[QuotationResponse] = []
    workshop: Optional[WorkshopResponse] = None


# --- AI Analysis Result ---
class AIAnalysisResult(BaseModel):
    incident_type: IncidentType
    priority: IncidentPriority
    confidence: float
    summary: str
    classification_details: str
    audio_transcription: Optional[str] = None
    cost_estimate_min: Optional[float] = None
    cost_estimate_max: Optional[float] = None


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


# --- Tenant ---
class TenantResponse(BaseModel):
    id: int
    name: str
    slug: str
    is_active: bool

    model_config = {"from_attributes": True}


class TenantCreate(BaseModel):
    name: str
    slug: str


class TenantUpdate(BaseModel):
    name: Optional[str] = None
    slug: Optional[str] = None
    is_active: Optional[bool] = None
