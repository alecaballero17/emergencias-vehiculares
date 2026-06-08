"""Router para Exportación e Importación de Backups (Base de Datos)."""
from datetime import datetime, date
import enum
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text, DateTime, Date
from app.database import get_db
from app.models import (
    Tenant, User, Vehicle, Workshop, Technician,
    Incident, Evidence, ServiceHistory, Payment,
    Notification, Quotation, UserRole
)
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/backup", tags=["Copia de Seguridad (Backup)"])


def serialize_model(db: Session, model) -> list:
    """Serializa todos los registros de un modelo a una lista de diccionarios."""
    records = db.query(model).all()
    serialized = []
    for r in records:
        data = {}
        for col in model.__table__.columns:
            val = getattr(r, col.name)
            if isinstance(val, (datetime, date)):
                data[col.name] = val.isoformat()
            elif isinstance(val, enum.Enum):
                data[col.name] = val.value
            else:
                data[col.name] = val
        serialized.append(data)
    return serialized


def deserialize_model(db: Session, model, data_list: list):
    """Crea e inserta instancias de un modelo a partir de una lista serializada."""
    for data in data_list:
        kwargs = {}
        for col in model.__table__.columns:
            if col.name in data:
                val = data[col.name]
                if val is not None:
                    if isinstance(col.type, DateTime) and isinstance(val, str):
                        kwargs[col.name] = datetime.fromisoformat(val)
                    elif isinstance(col.type, Date) and isinstance(val, str):
                        kwargs[col.name] = date.fromisoformat(val)
                    else:
                        kwargs[col.name] = val
                else:
                    kwargs[col.name] = None
        instance = model(**kwargs)
        db.add(instance)


@router.get("/export")
def export_database(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Exporta todas las tablas de la base de datos en formato JSON (Solo Administradores)."""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso denegado: solo el administrador de la plataforma puede exportar backups.",
        )

    try:
        data = {
            "tenants": serialize_model(db, Tenant),
            "users": serialize_model(db, User),
            "vehicles": serialize_model(db, Vehicle),
            "workshops": serialize_model(db, Workshop),
            "technicians": serialize_model(db, Technician),
            "incidents": serialize_model(db, Incident),
            "quotations": serialize_model(db, Quotation),
            "payments": serialize_model(db, Payment),
            "notifications": serialize_model(db, Notification),
            "evidences": serialize_model(db, Evidence),
            "service_history": serialize_model(db, ServiceHistory),
        }
        return {"status": "success", "timestamp": datetime.now().isoformat(), "data": data}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error al exportar base de datos: {str(e)}",
        )


@router.post("/import")
def import_database(
    payload: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Importa y restaura la base de datos desde un archivo JSON (Solo Administradores)."""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso denegado: solo el administrador de la plataforma puede restaurar backups.",
        )

    data = payload.get("data")
    if not data:
        raise HTTPException(
            status_code=400,
            detail="Formato de backup inválido: falta la clave 'data'",
        )

    try:
        # 1. Eliminar datos en orden inverso de dependencias
        db.query(ServiceHistory).delete()
        db.query(Evidence).delete()
        db.query(Notification).delete()
        db.query(Payment).delete()
        db.query(Quotation).delete()
        db.query(Incident).delete()
        db.query(Technician).delete()
        db.query(Workshop).delete()
        db.query(Vehicle).delete()
        db.query(User).delete()
        db.query(Tenant).delete()
        db.commit()

        # 2. Insertar en orden directo de dependencias
        if "tenants" in data:
            deserialize_model(db, Tenant, data["tenants"])
            db.commit()
        if "users" in data:
            deserialize_model(db, User, data["users"])
            db.commit()
        if "vehicles" in data:
            deserialize_model(db, Vehicle, data["vehicles"])
            db.commit()
        if "workshops" in data:
            deserialize_model(db, Workshop, data["workshops"])
            db.commit()
        if "technicians" in data:
            deserialize_model(db, Technician, data["technicians"])
            db.commit()
        if "incidents" in data:
            deserialize_model(db, Incident, data["incidents"])
            db.commit()
        if "quotations" in data:
            deserialize_model(db, Quotation, data["quotations"])
            db.commit()
        if "payments" in data:
            deserialize_model(db, Payment, data["payments"])
            db.commit()
        if "notifications" in data:
            deserialize_model(db, Notification, data["notifications"])
            db.commit()
        if "evidences" in data:
            deserialize_model(db, Evidence, data["evidences"])
            db.commit()
        if "service_history" in data:
            deserialize_model(db, ServiceHistory, data["service_history"])
            db.commit()

        # 3. Corregir secuencias en PostgreSQL
        if db.bind.dialect.name == "postgresql":
            tables = [
                "tenants", "users", "vehicles", "workshops", "technicians",
                "incidents", "quotations", "payments", "notifications",
                "evidences", "service_history"
            ]
            for t in tables:
                db.execute(text(
                    f"SELECT setval(pg_get_serial_sequence('{t}', 'id'), coalesce(max(id), 1), max(id) IS NOT null) FROM {t};"
                ))
            db.commit()

        return {"status": "success", "message": "Base de datos restaurada correctamente."}
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error al restaurar base de datos: {str(e)}",
        )
