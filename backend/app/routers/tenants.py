"""Router de tenants: listar redes de talleres disponibles."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.tenant import Tenant
from app.schemas.incident import TenantResponse

router = APIRouter(prefix="/api/tenants", tags=["Tenants"])


@router.get("/", response_model=list[TenantResponse])
def list_tenants(db: Session = Depends(get_db)):
    """Listar todos los tenants activos (público, para registro)."""
    return db.query(Tenant).filter(Tenant.is_active == True).all()
