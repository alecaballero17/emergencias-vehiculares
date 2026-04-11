"""Router de usuarios: perfil y gestión de datos del cliente."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse, UserUpdate
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/users", tags=["Usuarios"])


@router.get("/me", response_model=UserResponse)
def get_profile(current_user: User = Depends(get_current_user)):
    """Obtener perfil del usuario actual."""
    return current_user


@router.put("/me", response_model=UserResponse)
def update_profile(data: UserUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Actualizar perfil del usuario."""
    if data.full_name is not None:
        current_user.full_name = data.full_name
    if data.phone is not None:
        current_user.phone = data.phone
    if data.firebase_token is not None:
        current_user.firebase_token = data.firebase_token

    db.commit()
    db.refresh(current_user)
    return current_user
