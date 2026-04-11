from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class VehicleCreate(BaseModel):
    brand: str
    model: str
    year: int
    color: Optional[str] = None
    license_plate: str
    vin: Optional[str] = None


class VehicleUpdate(BaseModel):
    brand: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    color: Optional[str] = None
    license_plate: Optional[str] = None
    vin: Optional[str] = None


class VehicleResponse(BaseModel):
    id: int
    user_id: int
    brand: str
    model: str
    year: int
    color: Optional[str]
    license_plate: str
    vin: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}
