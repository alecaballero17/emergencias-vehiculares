import enum


class UserRole(str, enum.Enum):
    CLIENT = "client"
    WORKSHOP_ADMIN = "workshop_admin"
    ADMIN = "admin"


class IncidentType(str, enum.Enum):
    BATTERY = "battery"
    TIRE = "tire"
    CRASH = "crash"
    ENGINE = "engine"
    OTHER = "other"


class IncidentPriority(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class IncidentStatus(str, enum.Enum):
    """Máquina de estados obligatoria del segundo parcial."""
    PENDING = "pendiente"
    SEARCHING = "buscando_taller"
    ASSIGNED = "taller_asignado"
    EN_ROUTE = "en_camino"
    ATTENDING = "en_atencion"
    COMPLETED = "finalizado"
    CANCELLED = "cancelado"


class EvidenceType(str, enum.Enum):
    IMAGE = "image"
    AUDIO = "audio"
    TEXT = "text"


class PaymentStatus(str, enum.Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"


class PaymentMethod(str, enum.Enum):
    CREDIT_CARD = "credit_card"
    DEBIT_CARD = "debit_card"
    MOBILE_PAYMENT = "mobile_payment"
    CASH = "cash"
    PARALELA = "paralela"


class QuotationStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
