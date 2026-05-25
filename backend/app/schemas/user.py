from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional
from app.models.enums import UserRole


# --- Auth ---
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    tenant_id: int


class TokenData(BaseModel):
    sub: str
    role: str
    entity_id: int
    tenant_id: int


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# --- User ---
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    phone: Optional[str] = None
    tenant_id: int


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    firebase_token: Optional[str] = None


class UserResponse(BaseModel):
    id: int
    tenant_id: int
    email: str
    full_name: str
    phone: Optional[str]
    role: UserRole
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
