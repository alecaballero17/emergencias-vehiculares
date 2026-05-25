from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional


class WorkshopCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    phone: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    capacity: int = 5
    specialties: list[str] = []
    tenant_id: int


class WorkshopUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    capacity: Optional[int] = None
    specialties: Optional[list[str]] = None
    firebase_token: Optional[str] = None


class WorkshopResponse(BaseModel):
    id: int
    tenant_id: int
    name: str
    email: str
    phone: Optional[str]
    address: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    is_active: bool
    capacity: int
    specialties: list[str]
    created_at: datetime

    model_config = {"from_attributes": True}


# --- Technician ---
class TechnicianCreate(BaseModel):
    name: str
    phone: Optional[str] = None
    specialties: list[str] = []


class TechnicianUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    specialties: Optional[list[str]] = None
    is_available: Optional[bool] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class TechnicianResponse(BaseModel):
    id: int
    workshop_id: int
    name: str
    phone: Optional[str]
    specialties: list[str]
    is_available: bool
    latitude: Optional[float]
    longitude: Optional[float]
    created_at: datetime

    model_config = {"from_attributes": True}
