"""Router de autenticación: login y registro para usuarios y talleres, con soporte multi-tenant."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.models.workshop import Workshop
from app.models.tenant import Tenant
from app.models.enums import UserRole
from app.schemas.user import UserCreate, UserResponse, LoginRequest, Token
from app.schemas.workshop import WorkshopCreate, WorkshopResponse
from app.utils.security import hash_password, verify_password, create_access_token

router = APIRouter(prefix="/api/auth", tags=["Autenticación"])


@router.post("/register/user", response_model=UserResponse, status_code=201)
def register_user(data: UserCreate, db: Session = Depends(get_db)):
    """Registrar un nuevo usuario (cliente) vinculado a un tenant."""
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="El email ya está registrado")

    # Validar tenant
    tenant = db.query(Tenant).filter(Tenant.id == data.tenant_id).first()
    if not tenant or not tenant.is_active:
        raise HTTPException(status_code=400, detail="Tenant no encontrado o inactivo")

    user = User(
        tenant_id=data.tenant_id,
        email=data.email,
        password_hash=hash_password(data.password),
        full_name=data.full_name,
        phone=data.phone,
        role=UserRole.CLIENT,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/register/workshop", response_model=WorkshopResponse, status_code=201)
def register_workshop(data: WorkshopCreate, db: Session = Depends(get_db)):
    """Registrar un nuevo taller vinculado a un tenant."""
    if db.query(Workshop).filter(Workshop.email == data.email).first():
        raise HTTPException(status_code=400, detail="El email ya está registrado")

    # Validar tenant
    tenant = db.query(Tenant).filter(Tenant.id == data.tenant_id).first()
    if not tenant or not tenant.is_active:
        raise HTTPException(status_code=400, detail="Tenant no encontrado o inactivo")

    workshop = Workshop(
        tenant_id=data.tenant_id,
        name=data.name,
        email=data.email,
        password_hash=hash_password(data.password),
        phone=data.phone,
        address=data.address,
        latitude=data.latitude,
        longitude=data.longitude,
        capacity=data.capacity,
        specialties=data.specialties,
    )
    db.add(workshop)
    db.commit()
    db.refresh(workshop)
    return workshop


@router.post("/login", response_model=Token)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    """Login unificado para usuarios y talleres. Incluye tenant_id en el token."""
    # Intentar como usuario
    user = db.query(User).filter(User.email == data.email).first()
    if user and verify_password(data.password, user.password_hash):
        if not user.is_active:
            raise HTTPException(status_code=403, detail="Cuenta desactivada")
        token = create_access_token({
            "sub": user.email,
            "role": user.role.value,
            "entity_id": user.id,
            "tenant_id": user.tenant_id,
        })
        return Token(access_token=token, role=user.role.value, tenant_id=user.tenant_id)

    # Intentar como taller
    workshop = db.query(Workshop).filter(Workshop.email == data.email).first()
    if workshop and verify_password(data.password, workshop.password_hash):
        if not workshop.is_active:
            raise HTTPException(status_code=403, detail="Cuenta desactivada")
        token = create_access_token({
            "sub": workshop.email,
            "role": UserRole.WORKSHOP_ADMIN.value,
            "entity_id": workshop.id,
            "tenant_id": workshop.tenant_id,
        })
        return Token(access_token=token, role=UserRole.WORKSHOP_ADMIN.value, tenant_id=workshop.tenant_id)

    raise HTTPException(status_code=401, detail="Credenciales inválidas")
