"""
Servicio de cálculo de precio de grúa basado en geolocalización.
Estima el costo de la grúa según la distancia desde el taller más cercano.
"""
from geopy.distance import geodesic
from sqlalchemy.orm import Session
from app.models.workshop import Workshop
from app.database import get_db


class TowTruckEstimator:
    """Estimador de costo de grúa por distancia y ubicación."""

    # Configuración de costos (en BOB)
    BASE_TOW_COST = 50.0  # Costo base
    COST_PER_KM = 8.0     # Costo por kilómetro
    MAX_DISTANCE_KM = 50  # Distancia máxima sin recargo
    LONG_DISTANCE_MULTIPLIER = 1.5  # Multiplicador si excede distancia máxima

    @staticmethod
    def calculate_tow_cost(
        client_lat: float,
        client_lon: float,
        workshop_lat: float,
        workshop_lon: float,
    ) -> dict:
        """
        Calcula el costo de grúa entre cliente y taller.
        
        Args:
            client_lat, client_lon: Ubicación del cliente
            workshop_lat, workshop_lon: Ubicación del taller
            
        Returns:
            {
                "distance_km": float,
                "base_cost": float,
                "distance_cost": float,
                "total_cost": float,
                "estimated_time_minutes": int,
            }
        """
        # Calcular distancia con Haversine
        client_coords = (client_lat, client_lon)
        workshop_coords = (workshop_lat, workshop_lon)
        distance_km = geodesic(client_coords, workshop_coords).kilometers

        base_cost = TowTruckEstimator.BASE_TOW_COST
        distance_cost = distance_km * TowTruckEstimator.COST_PER_KM

        # Aplicar recargo si excede distancia máxima
        if distance_km > TowTruckEstimator.MAX_DISTANCE_KM:
            distance_cost *= TowTruckEstimator.LONG_DISTANCE_MULTIPLIER

        total_cost = round(base_cost + distance_cost, 2)

        # Estimar tiempo (30 min base + 3 min por km)
        estimated_time = 30 + int(distance_km * 3)

        return {
            "distance_km": round(distance_km, 2),
            "base_cost": base_cost,
            "distance_cost": round(distance_cost, 2),
            "total_cost": total_cost,
            "estimated_time_minutes": estimated_time,
        }

    @staticmethod
    def find_nearest_workshop_and_estimate(
        client_lat: float,
        client_lon: float,
        db: Session,
        tenant_id: int,
    ) -> list[dict]:
        """
        Encuentra los 5 talleres más cercanos y estima costo para cada uno.
        
        Returns:
            [
                {
                    "workshop_id": int,
                    "workshop_name": str,
                    "distance_km": float,
                    "estimated_cost": float,
                    "estimated_time_minutes": int,
                },
                ...
            ]
        """
        workshops = db.query(Workshop).filter(
            Workshop.tenant_id == tenant_id,
            Workshop.is_active == True,
        ).all()

        if not workshops:
            return []

        estimates = []
        for workshop in workshops:
            if not workshop.latitude or not workshop.longitude:
                continue

            cost_data = TowTruckEstimator.calculate_tow_cost(
                client_lat,
                client_lon,
                workshop.latitude,
                workshop.longitude,
            )

            estimates.append({
                "workshop_id": workshop.id,
                "workshop_name": workshop.name,
                "distance_km": cost_data["distance_km"],
                "estimated_cost": cost_data["total_cost"],
                "estimated_time_minutes": cost_data["estimated_time_minutes"],
            })

        # Ordenar por distancia y retornar top 5
        estimates.sort(key=lambda x: x["distance_km"])
        return estimates[:5]
