"""Router de tenants: listar y administrar redes de talleres disponibles (tenants)."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.tenant import Tenant
from app.models.enums import UserRole
from app.models.user import User
from app.schemas.incident import TenantResponse, TenantCreate, TenantUpdate
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/tenants", tags=["Tenants"])


@router.get("/", response_model=list[TenantResponse])
def list_tenants(db: Session = Depends(get_db)):
    """Listar todos los tenants activos (público, para registro)."""
    return db.query(Tenant).filter(Tenant.is_active == True).all()


@router.get("/admin", response_model=list[TenantResponse])
def list_tenants_admin(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Listar todos los tenants (activos e inactivos) para la administración."""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso denegado: esta ruta es exclusiva para administradores de la plataforma",
        )
    return db.query(Tenant).order_by(Tenant.id.asc()).all()


@router.post("/", response_model=TenantResponse, status_code=201)
def create_tenant(
    data: TenantCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Crear un nuevo tenant (red de talleres)."""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso denegado: esta ruta es exclusiva para administradores de la plataforma",
        )
    
    # Verificar si el slug ya existe
    existing = db.query(Tenant).filter(Tenant.slug == data.slug).first()
    if existing:
        raise HTTPException(status_code=400, detail="El slug del tenant ya existe")

    tenant = Tenant(name=data.name, slug=data.slug, is_active=True)
    db.add(tenant)
    db.commit()
    db.refresh(tenant)
    return tenant


@router.put("/{tenant_id}", response_model=TenantResponse)
def update_tenant(
    tenant_id: int,
    data: TenantUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Actualizar datos de un tenant."""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso denegado: esta ruta es exclusiva para administradores de la plataforma",
        )
    
    tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant no encontrado")

    if data.slug is not None:
        existing = db.query(Tenant).filter(Tenant.slug == data.slug, Tenant.id != tenant_id).first()
        if existing:
            raise HTTPException(status_code=400, detail="El slug del tenant ya existe")
        tenant.slug = data.slug

    if data.name is not None:
        tenant.name = data.name

    if data.is_active is not None:
        tenant.is_active = data.is_active

    db.commit()
    db.refresh(tenant)
    return tenant


@router.delete("/{tenant_id}", status_code=204)
def delete_tenant(
    tenant_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Eliminar o desactivar un tenant."""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso denegado: esta ruta es exclusiva para administradores de la plataforma",
        )
    
    tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant no encontrado")

    # Hacer soft delete desactivando el tenant
    tenant.is_active = False
    db.commit()
    return
