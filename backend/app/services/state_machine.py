"""
Máquina de estados para incidentes.
Define las transiciones válidas y gestiona los timestamps de cada estado.
"""
import pytz
from datetime import datetime
from app.models.incident import Incident
from app.models.enums import IncidentStatus

BOL_TZ = pytz.timezone('America/La_Paz')

# Transiciones válidas: estado_actual -> [estados_posibles]
VALID_TRANSITIONS: dict[IncidentStatus, list[IncidentStatus]] = {
    IncidentStatus.PENDING: [IncidentStatus.SEARCHING, IncidentStatus.CANCELLED],
    IncidentStatus.SEARCHING: [IncidentStatus.ASSIGNED, IncidentStatus.CANCELLED],
    IncidentStatus.ASSIGNED: [IncidentStatus.EN_ROUTE, IncidentStatus.SEARCHING, IncidentStatus.CANCELLED],
    IncidentStatus.EN_ROUTE: [IncidentStatus.ATTENDING, IncidentStatus.CANCELLED],
    IncidentStatus.ATTENDING: [IncidentStatus.COMPLETED, IncidentStatus.CANCELLED],
    IncidentStatus.COMPLETED: [],  # Estado terminal
    IncidentStatus.CANCELLED: [],  # Estado terminal
}

# Estados donde cancelar requiere recargo obligatorio
CANCELLATION_FEE_STATES = [IncidentStatus.EN_ROUTE, IncidentStatus.ATTENDING]

# Tarifa de reconocimiento por defecto (en Bs.)
DEFAULT_CANCELLATION_FEE = 50.0

# Mapeo de estado -> campo de timestamp
TIMESTAMP_MAP = {
    IncidentStatus.SEARCHING: "searching_at",
    IncidentStatus.ASSIGNED: "assigned_at",
    IncidentStatus.EN_ROUTE: "en_route_at",
    IncidentStatus.ATTENDING: "attending_at",
    IncidentStatus.COMPLETED: "completed_at",
    IncidentStatus.CANCELLED: "cancelled_at",
}

# Labels legibles para notificaciones
STATUS_LABELS = {
    IncidentStatus.PENDING: "Pendiente",
    IncidentStatus.SEARCHING: "Buscando taller",
    IncidentStatus.ASSIGNED: "Taller asignado",
    IncidentStatus.EN_ROUTE: "En camino",
    IncidentStatus.ATTENDING: "En atención",
    IncidentStatus.COMPLETED: "Finalizado",
    IncidentStatus.CANCELLED: "Cancelado",
}

STATUS_EMOJIS = {
    IncidentStatus.PENDING: "🔵",
    IncidentStatus.SEARCHING: "🔍",
    IncidentStatus.ASSIGNED: "🟡",
    IncidentStatus.EN_ROUTE: "🟠",
    IncidentStatus.ATTENDING: "🔴",
    IncidentStatus.COMPLETED: "✅",
    IncidentStatus.CANCELLED: "❌",
}


class InvalidTransitionError(Exception):
    """Error cuando se intenta una transición de estado inválida."""
    pass


def validate_transition(current_status: IncidentStatus, new_status: IncidentStatus) -> bool:
    """Valida si una transición de estado es permitida."""
    allowed = VALID_TRANSITIONS.get(current_status, [])
    return new_status in allowed


def requires_cancellation_fee(current_status: IncidentStatus) -> bool:
    """Indica si cancelar desde este estado requiere recargo."""
    return current_status in CANCELLATION_FEE_STATES


def transition_state(
    incident: Incident,
    new_status: IncidentStatus,
    cancellation_fee: float | None = None,
) -> dict:
    """
    Ejecuta una transición de estado en el incidente.
    Valida la transición, actualiza timestamps, y retorna el payload WebSocket.
    
    Returns:
        dict: Payload para emitir por WebSocket
    
    Raises:
        InvalidTransitionError: Si la transición no es válida
    """
    current = incident.status

    if not validate_transition(current, new_status):
        raise InvalidTransitionError(
            f"Transición inválida: {current.value} → {new_status.value}. "
            f"Transiciones permitidas: {[s.value for s in VALID_TRANSITIONS.get(current, [])]}"
        )

    # Aplicar recargo si es cancelación en estado avanzado
    if new_status == IncidentStatus.CANCELLED and requires_cancellation_fee(current):
        incident.cancellation_fee = cancellation_fee or DEFAULT_CANCELLATION_FEE

    # Actualizar estado
    incident.status = new_status

    # Actualizar timestamp correspondiente
    ts_field = TIMESTAMP_MAP.get(new_status)
    if ts_field:
        setattr(incident, ts_field, datetime.now(BOL_TZ))

    # Construir payload WebSocket
    emoji = STATUS_EMOJIS.get(new_status, "📋")
    label = STATUS_LABELS.get(new_status, new_status.value)

    payload = {
        "type": "status_change",
        "incident_id": incident.id,
        "previous_status": current.value,
        "new_status": new_status.value,
        "status_label": f"{emoji} {label}",
        "timestamp": datetime.now(BOL_TZ).isoformat(),
        "cancellation_fee": incident.cancellation_fee,
    }

    if incident.workshop_id:
        payload["workshop_id"] = incident.workshop_id
    if incident.estimated_arrival_minutes:
        payload["eta_minutes"] = incident.estimated_arrival_minutes

    return payload
