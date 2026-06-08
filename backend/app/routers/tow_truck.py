"""Router para solicitudes y estimaciones de grúa."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.utils.security import get_current_user
from app.services.tow_truck_service import TowTruckEstimator

router = APIRouter(prefix="/api/tow-truck", tags=["Grúa"])


class TowTruckEstimateRequest(BaseModel):
    """Solicitud de estimación de grúa."""
    client_latitude: float
    client_longitude: float
    workshop_id: int = None  # Opcional: si quiere un taller específico


class TowTruckEstimate(BaseModel):
    """Respuesta de estimación de grúa."""
    distance_km: float
    base_cost: float
    distance_cost: float
    total_cost: float
    estimated_time_minutes: int


class NearestWorkshopsResponse(BaseModel):
    """Lista de talleres cercanos con estimaciones."""
    workshop_id: int
    workshop_name: str
    distance_km: float
    estimated_cost: float
    estimated_time_minutes: int


@router.post("/estimate", response_model=TowTruckEstimate, status_code=200)
async def estimate_tow_cost(
    data: TowTruckEstimateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Estima el costo de grúa para un taller específico.
    
    Si workshop_id no se proporciona, usa el taller más cercano.
    """
    from app.models.workshop import Workshop

    if data.workshop_id:
        # Obtener taller específico
        workshop = db.query(Workshop).filter(
            Workshop.id == data.workshop_id,
            Workshop.tenant_id == current_user.tenant_id,
            Workshop.is_active == True,
        ).first()
        if not workshop:
            raise HTTPException(status_code=404, detail="Taller no encontrado")
        if not workshop.latitude or not workshop.longitude:
            raise HTTPException(status_code=400, detail="Taller sin ubicación registrada")
    else:
        # Encontrar taller más cercano
        workshops = db.query(Workshop).filter(
            Workshop.tenant_id == current_user.tenant_id,
            Workshop.is_active == True,
            Workshop.latitude.isnot(None),
            Workshop.longitude.isnot(None),
        ).all()

        if not workshops:
            raise HTTPException(status_code=404, detail="No hay talleres disponibles")

        # Calcular distancias
        from geopy.distance import geodesic
        client_coords = (data.client_latitude, data.client_longitude)
        distances = []
        for w in workshops:
            workshop_coords = (w.latitude, w.longitude)
            dist = geodesic(client_coords, workshop_coords).kilometers
            distances.append((w, dist))

        workshop = min(distances, key=lambda x: x[1])[0]

    # Calcular costo
    estimate = TowTruckEstimator.calculate_tow_cost(
        data.client_latitude,
        data.client_longitude,
        workshop.latitude,
        workshop.longitude,
    )

    return TowTruckEstimate(**estimate)


@router.post("/nearest-workshops", response_model=list[NearestWorkshopsResponse], status_code=200)
async def get_nearest_workshops(
    data: TowTruckEstimateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Obtiene los 5 talleres más cercanos con estimaciones de grúa.
    """
    estimates = TowTruckEstimator.find_nearest_workshop_and_estimate(
        data.client_latitude,
        data.client_longitude,
        db,
        current_user.tenant_id,
    )

    if not estimates:
        raise HTTPException(status_code=404, detail="No hay talleres disponibles")

    return [NearestWorkshopsResponse(**est) for est in estimates]
