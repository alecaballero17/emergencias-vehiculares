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
    KEYS_LOST = "keys_lost"
    KEYS_LOCKED = "keys_locked"
    OVERHEATING = "overheating"
    OTHER = "other"


class IncidentPriority(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class IncidentStatus(str, enum.Enum):
    PENDING = "pending"
    ASSIGNED = "assigned"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


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
