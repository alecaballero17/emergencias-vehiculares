import math
from typing import Optional


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calcula la distancia en kilómetros entre dos coordenadas usando la fórmula de Haversine."""
    R = 6371.0  # Radio de la Tierra en km

    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)

    a = math.sin(dlat / 2) ** 2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c


def estimate_arrival_minutes(distance_km: float, avg_speed_kmh: float = 40.0) -> int:
    """Estima el tiempo de llegada en minutos basado en la distancia."""
    if distance_km <= 0:
        return 5
    minutes = (distance_km / avg_speed_kmh) * 60
    return max(5, round(minutes))


def format_address(latitude: float, longitude: float, address: Optional[str] = None) -> str:
    """Formatea la dirección o retorna las coordenadas."""
    if address:
        return address
    return f"Lat: {latitude:.6f}, Lon: {longitude:.6f}"
