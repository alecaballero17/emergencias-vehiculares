from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.config import get_settings
from app.database import get_db
from app.models.user import User
from app.models.workshop import Workshop
from app.models.enums import UserRole

settings = get_settings()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Crea un JWT que incluye tenant_id para aislamiento multi-tenant."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=settings.access_token_expire_minutes))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)


def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    payload = decode_token(token)
    role = payload.get("role")
    entity_id = payload.get("entity_id")

    if role == UserRole.WORKSHOP_ADMIN:
        raise HTTPException(status_code=403, detail="Acceso denegado: esta ruta es solo para usuarios")

    user = db.query(User).filter(User.id == entity_id).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Usuario no encontrado o inactivo")
    return user


def get_current_workshop(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> Workshop:
    payload = decode_token(token)
    role = payload.get("role")
    entity_id = payload.get("entity_id")

    if role != UserRole.WORKSHOP_ADMIN:
        raise HTTPException(status_code=403, detail="Acceso denegado: esta ruta es solo para talleres")

    workshop = db.query(Workshop).filter(Workshop.id == entity_id).first()
    if not workshop or not workshop.is_active:
        raise HTTPException(status_code=401, detail="Taller no encontrado o inactivo")
    return workshop


def get_current_entity(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> dict:
    """Retorna el usuario o taller actual según el token."""
    payload = decode_token(token)
    role = payload.get("role")
    entity_id = payload.get("entity_id")
    tenant_id = payload.get("tenant_id")

    if role == UserRole.WORKSHOP_ADMIN:
        entity = db.query(Workshop).filter(Workshop.id == entity_id).first()
        return {"type": "workshop", "entity": entity, "role": role, "tenant_id": tenant_id}
    else:
        entity = db.query(User).filter(User.id == entity_id).first()
        return {"type": "user", "entity": entity, "role": role, "tenant_id": tenant_id}
