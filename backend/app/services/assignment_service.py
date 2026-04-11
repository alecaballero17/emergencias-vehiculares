"""
Motor de asignación inteligente de talleres.
Evalúa múltiples factores para seleccionar el taller más adecuado.
"""
from sqlalchemy.orm import Session
from app.models.workshop import Workshop
from app.models.technician import Technician
from app.models.incident import Incident
from app.models.enums import IncidentType, IncidentStatus
from app.schemas.incident import WorkshopCandidate, AssignmentResult
from app.utils.geolocation import haversine_distance, estimate_arrival_minutes


# Pesos para el algoritmo de scoring
WEIGHTS = {
    "distance": 0.35,
    "specialty_match": 0.25,
    "availability": 0.20,
    "capacity": 0.10,
    "workload": 0.10,
}

MAX_SEARCH_RADIUS_KM = 50.0


def find_best_workshop(
    db: Session,
    incident: Incident,
) -> AssignmentResult | None:
    """
    Encuentra el mejor taller para atender un incidente.
    Considera: distancia, especialidad, disponibilidad, capacidad y carga actual.
    """
    candidates = _get_candidate_workshops(db, incident)

    if not candidates:
        return None

    # Ordenar por score descendente
    candidates.sort(key=lambda c: c.score, reverse=True)

    best = candidates[0]

    # Buscar técnico disponible en el taller seleccionado
    technician = _find_available_technician(db, best.workshop_id, incident.incident_type)

    return AssignmentResult(
        incident_id=incident.id,
        workshop_id=best.workshop_id,
        technician_id=technician.id if technician else None,
        estimated_arrival_minutes=best.estimated_arrival_minutes,
        candidates=candidates[:5],  # Top 5 candidatos
    )


def _get_candidate_workshops(db: Session, incident: Incident) -> list[WorkshopCandidate]:
    """Obtiene la lista de talleres candidatos con su score."""
    workshops = db.query(Workshop).filter(Workshop.is_active == True).all()
    candidates = []

    for ws in workshops:
        if ws.latitude is None or ws.longitude is None:
            continue

        # Calcular distancia
        distance = haversine_distance(incident.latitude, incident.longitude, ws.latitude, ws.longitude)

        if distance > MAX_SEARCH_RADIUS_KM:
            continue

        # Contar técnicos disponibles
        available_techs = (
            db.query(Technician)
            .filter(
                Technician.workshop_id == ws.id,
                Technician.is_available == True,
            )
            .count()
        )

        if available_techs == 0:
            continue

        # Calcular carga actual (incidentes activos)
        active_incidents = (
            db.query(Incident)
            .filter(
                Incident.workshop_id == ws.id,
                Incident.status.in_([IncidentStatus.ASSIGNED, IncidentStatus.IN_PROGRESS]),
            )
            .count()
        )

        # Calcular scores parciales
        distance_score = max(0, 1.0 - (distance / MAX_SEARCH_RADIUS_KM))
        specialty_score = _calculate_specialty_score(ws.specialties or [], incident.incident_type)
        availability_score = min(available_techs / max(ws.capacity, 1), 1.0)
        capacity_score = max(0, 1.0 - (active_incidents / max(ws.capacity, 1)))
        workload_score = 1.0 / (1.0 + active_incidents)

        # Score compuesto
        total_score = (
            WEIGHTS["distance"] * distance_score
            + WEIGHTS["specialty_match"] * specialty_score
            + WEIGHTS["availability"] * availability_score
            + WEIGHTS["capacity"] * capacity_score
            + WEIGHTS["workload"] * workload_score
        )

        candidates.append(
            WorkshopCandidate(
                workshop_id=ws.id,
                workshop_name=ws.name,
                distance_km=round(distance, 2),
                estimated_arrival_minutes=estimate_arrival_minutes(distance),
                score=round(total_score, 4),
                specialties=ws.specialties or [],
                available_technicians=available_techs,
            )
        )

    return candidates


def _calculate_specialty_score(specialties: list[str], incident_type: IncidentType) -> float:
    """Calcula qué tan bien coincide la especialidad del taller con el incidente."""
    if not specialties:
        return 0.3  # Score base si no tiene especialidades definidas

    type_value = incident_type.value
    if type_value in specialties:
        return 1.0

    # Mapeo de tipos relacionados
    related = {
        "battery": ["engine", "overheating"],
        "engine": ["battery", "overheating"],
        "overheating": ["engine", "battery"],
        "tire": [],
        "crash": ["engine"],
        "keys_lost": ["keys_locked"],
        "keys_locked": ["keys_lost"],
    }

    related_types = related.get(type_value, [])
    for rt in related_types:
        if rt in specialties:
            return 0.6

    return 0.3


def _find_available_technician(
    db: Session, workshop_id: int, incident_type: IncidentType
) -> Technician | None:
    """Busca el técnico más adecuado disponible en el taller."""
    # Primero buscar técnico con especialidad coincidente
    technician = (
        db.query(Technician)
        .filter(
            Technician.workshop_id == workshop_id,
            Technician.is_available == True,
        )
        .all()
    )

    if not technician:
        return None

    # Priorizar por especialidad
    for tech in technician:
        if incident_type.value in (tech.specialties or []):
            return tech

    # Si ninguno tiene la especialidad, retornar el primero disponible
    return technician[0]
