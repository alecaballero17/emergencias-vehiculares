"""Router de vehículos: CRUD de vehículos del usuario."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.models.vehicle import Vehicle
from app.schemas.vehicle import VehicleCreate, VehicleUpdate, VehicleResponse
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/vehicles", tags=["Vehículos"])


@router.post("/", response_model=VehicleResponse, status_code=201)
def create_vehicle(data: VehicleCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Registrar un nuevo vehículo."""
    if db.query(Vehicle).filter(Vehicle.license_plate == data.license_plate).first():
        raise HTTPException(status_code=400, detail="La placa ya está registrada")

    vehicle = Vehicle(
        tenant_id=current_user.tenant_id,
        user_id=current_user.id,
        brand=data.brand,
        model=data.model,
        year=data.year,
        color=data.color,
        license_plate=data.license_plate,
        vin=data.vin,
    )
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle


@router.get("/", response_model=list[VehicleResponse])
def list_vehicles(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Listar vehículos del usuario."""
    return db.query(Vehicle).filter(Vehicle.user_id == current_user.id).all()


@router.get("/{vehicle_id}", response_model=VehicleResponse)
def get_vehicle(vehicle_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Obtener detalle de un vehículo."""
    vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id, Vehicle.user_id == current_user.id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehículo no encontrado")
    return vehicle


@router.put("/{vehicle_id}", response_model=VehicleResponse)
def update_vehicle(
    vehicle_id: int,
    data: VehicleUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Actualizar datos de un vehículo."""
    vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id, Vehicle.user_id == current_user.id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehículo no encontrado")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(vehicle, field, value)

    db.commit()
    db.refresh(vehicle)
    return vehicle


@router.delete("/{vehicle_id}", status_code=204)
def delete_vehicle(vehicle_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Eliminar un vehículo."""
    vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id, Vehicle.user_id == current_user.id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehículo no encontrado")

    db.delete(vehicle)
    db.commit()
