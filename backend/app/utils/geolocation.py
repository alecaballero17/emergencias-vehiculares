import math
from typing import Optional


import http.client
import json
import urllib.parse


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


async def get_reverse_geocoding(lat: float, lon: float) -> Optional[str]:
    """Obtiene una dirección legible a partir de coordenadas usando Nominatim (OSM)."""
    try:
        # Nominatim requiere un User-Agent. Usamos uno descriptivo para el proyecto.
        headers = {'User-Agent': 'EmergenciasVehiculares-AcademicProject/1.0'}
        url = f"/reverse?format=json&lat={lat}&lon={lon}&zoom=18&addressdetails=1"
        
        conn = http.client.HTTPSConnection("nominatim.openstreetmap.org", timeout=5)
        conn.request("GET", url, headers=headers)
        res = conn.getresponse()
        data = res.read()
        conn.close()
        
        if res.status == 200:
            result = json.loads(data.decode("utf-8"))
            address_data = result.get("address", {})
            
            # Construir una dirección legible
            road = address_data.get("road")
            suburb = address_data.get("suburb") or address_data.get("neighbourhood")
            city = address_data.get("city") or address_data.get("town") or address_data.get("village")
            
            parts = []
            if road: parts.append(road)
            if suburb: parts.append(suburb)
            if city: parts.append(city)
            
            if parts:
                return ", ".join(parts)
            
            return result.get("display_name")
    except Exception as e:
        print(f"Error en Geocodificacion Inversa: {e}")
    
    return None


def format_address(latitude: float, longitude: float, address: Optional[str] = None) -> str:
    """Formatea la dirección o retorna las coordenadas."""
    if address and address.strip():
        return address
    return f"Lat: {latitude:.6f}, Lon: {longitude:.6f}"
