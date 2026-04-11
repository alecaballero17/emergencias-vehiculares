"""Router de autenticación: login y registro para usuarios y talleres."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.models.workshop import Workshop
from app.models.enums import UserRole
from app.schemas.user import UserCreate, UserResponse, LoginRequest, Token
from app.schemas.workshop import WorkshopCreate, WorkshopResponse
from app.utils.security import hash_password, verify_password, create_access_token

router = APIRouter(prefix="/api/auth", tags=["Autenticación"])


@router.post("/register/user", response_model=UserResponse, status_code=201)
def register_user(data: UserCreate, db: Session = Depends(get_db)):
    """Registrar un nuevo usuario (cliente)."""
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="El email ya está registrado")

    user = User(
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
    """Registrar un nuevo taller."""
    if db.query(Workshop).filter(Workshop.email == data.email).first():
        raise HTTPException(status_code=400, detail="El email ya está registrado")

    workshop = Workshop(
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
    """Login unificado para usuarios y talleres."""
    # Intentar como usuario
    user = db.query(User).filter(User.email == data.email).first()
    if user and verify_password(data.password, user.password_hash):
        if not user.is_active:
            raise HTTPException(status_code=403, detail="Cuenta desactivada")
        token = create_access_token({
            "sub": user.email,
            "role": user.role.value,
            "entity_id": user.id,
        })
        return Token(access_token=token, role=user.role.value)

    # Intentar como taller
    workshop = db.query(Workshop).filter(Workshop.email == data.email).first()
    if workshop and verify_password(data.password, workshop.password_hash):
        if not workshop.is_active:
            raise HTTPException(status_code=403, detail="Cuenta desactivada")
        token = create_access_token({
            "sub": workshop.email,
            "role": UserRole.WORKSHOP_ADMIN.value,
            "entity_id": workshop.id,
        })
        return Token(access_token=token, role=UserRole.WORKSHOP_ADMIN.value)

    raise HTTPException(status_code=401, detail="Credenciales inválidas")
