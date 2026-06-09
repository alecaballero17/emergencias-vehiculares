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
from app.utils.security import get_current_entity

router = APIRouter(prefix="/api/backup", tags=["Copia de Seguridad (Backup)"])


def serialize_model(db: Session, model, tenant_id: int = None) -> list:
    """Serializa todos los registros de un modelo a una lista de diccionarios, filtrando por tenant_id si aplica."""
    query = db.query(model)
    if tenant_id is not None:
        if hasattr(model, 'tenant_id'):
            query = query.filter(model.tenant_id == tenant_id)
        elif model.__name__ == 'Tenant':
            query = query.filter(model.id == tenant_id)
        elif model.__name__ == 'Technician':
            query = query.join(Workshop).filter(Workshop.tenant_id == tenant_id)
        elif model.__name__ == 'Evidence':
            query = query.join(Incident).filter(Incident.tenant_id == tenant_id)
        elif model.__name__ == 'ServiceHistory':
            query = query.join(Incident).filter(Incident.tenant_id == tenant_id)

    records = query.all()
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


def deserialize_model(db: Session, model, data_list: list, tenant_id: int = None):
    """Crea e inserta instancias de un modelo, forzando/validando el tenant_id si es taller."""
    for data in data_list:
        kwargs = {}
        for col in model.__table__.columns:
            if col.name in data:
                val = data[col.name]
                if tenant_id is not None:
                    if col.name == 'tenant_id':
                        val = tenant_id
                    elif model.__name__ == 'Tenant' and col.name == 'id':
                        val = tenant_id

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
    current_entity: dict = Depends(get_current_entity),
):
    """Exporta las tablas de la base de datos en formato JSON (Solo Administradores y Talleres)."""
    role = current_entity["role"]
    tenant_id = current_entity["tenant_id"]

    if role not in [UserRole.ADMIN, UserRole.WORKSHOP_ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso denegado: solo administradores y talleres pueden exportar backups.",
        )

    # Si es taller, filtramos por su tenant_id
    filter_tenant = tenant_id if role == UserRole.WORKSHOP_ADMIN else None

    try:
        data = {
            "tenants": serialize_model(db, Tenant, filter_tenant),
            "users": serialize_model(db, User, filter_tenant),
            "vehicles": serialize_model(db, Vehicle, filter_tenant),
            "workshops": serialize_model(db, Workshop, filter_tenant),
            "technicians": serialize_model(db, Technician, filter_tenant),
            "incidents": serialize_model(db, Incident, filter_tenant),
            "quotations": serialize_model(db, Quotation, filter_tenant),
            "payments": serialize_model(db, Payment, filter_tenant),
            "notifications": serialize_model(db, Notification, filter_tenant),
            "evidences": serialize_model(db, Evidence, filter_tenant),
            "service_history": serialize_model(db, ServiceHistory, filter_tenant),
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
    current_entity: dict = Depends(get_current_entity),
):
    """Importa y restaura la base de datos desde un archivo JSON."""
    role = current_entity["role"]
    tenant_id = current_entity["tenant_id"]

    if role not in [UserRole.ADMIN, UserRole.WORKSHOP_ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso denegado: solo administradores y talleres pueden restaurar backups.",
        )

    data = payload.get("data")
    if not data:
        raise HTTPException(
            status_code=400,
            detail="Formato de backup inválido: falta la clave 'data'",
        )

    filter_tenant = tenant_id if role == UserRole.WORKSHOP_ADMIN else None

    try:
        # 1. Eliminar datos en orden inverso de dependencias (filtrando si es taller)
        if filter_tenant is not None:
            # Eliminar service history
            db.query(ServiceHistory).filter(ServiceHistory.incident_id.in_(
                db.query(Incident.id).filter(Incident.tenant_id == filter_tenant)
            )).delete(synchronize_session=False)
            
            # Eliminar evidences
            db.query(Evidence).filter(Evidence.incident_id.in_(
                db.query(Incident.id).filter(Incident.tenant_id == filter_tenant)
            )).delete(synchronize_session=False)

            db.query(Notification).filter(Notification.tenant_id == filter_tenant).delete(synchronize_session=False)
            db.query(Payment).filter(Payment.tenant_id == filter_tenant).delete(synchronize_session=False)
            db.query(Quotation).filter(Quotation.tenant_id == filter_tenant).delete(synchronize_session=False)
            db.query(Incident).filter(Incident.tenant_id == filter_tenant).delete(synchronize_session=False)
            
            # Eliminar técnicos de talleres del tenant
            db.query(Technician).filter(Technician.workshop_id.in_(
                db.query(Workshop.id).filter(Workshop.tenant_id == filter_tenant)
            )).delete(synchronize_session=False)
            
            db.query(Workshop).filter(Workshop.tenant_id == filter_tenant).delete(synchronize_session=False)
            db.query(Vehicle).filter(Vehicle.tenant_id == filter_tenant).delete(synchronize_session=False)
            db.query(User).filter(User.tenant_id == filter_tenant).delete(synchronize_session=False)
            # No eliminamos Tenant para preservar su existencia
        else:
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

        # 2. Insertar en orden directo de dependencias (filtrando/forzando tenant si es taller)
        if filter_tenant is None and "tenants" in data:
            deserialize_model(db, Tenant, data["tenants"], None)
            db.commit()
            
        if "users" in data:
            deserialize_model(db, User, data["users"], filter_tenant)
            db.commit()
        if "vehicles" in data:
            deserialize_model(db, Vehicle, data["vehicles"], filter_tenant)
            db.commit()
        if "workshops" in data:
            deserialize_model(db, Workshop, data["workshops"], filter_tenant)
            db.commit()
        if "technicians" in data:
            deserialize_model(db, Technician, data["technicians"], None)
            db.commit()
        if "incidents" in data:
            deserialize_model(db, Incident, data["incidents"], filter_tenant)
            db.commit()
        if "quotations" in data:
            deserialize_model(db, Quotation, data["quotations"], filter_tenant)
            db.commit()
        if "payments" in data:
            deserialize_model(db, Payment, data["payments"], filter_tenant)
            db.commit()
        if "notifications" in data:
            deserialize_model(db, Notification, data["notifications"], filter_tenant)
            db.commit()
        if "evidences" in data:
            deserialize_model(db, Evidence, data["evidences"], None)
            db.commit()
        if "service_history" in data:
            deserialize_model(db, ServiceHistory, data["service_history"], None)
            db.commit()

        # 3. Corregir secuencias en PostgreSQL
        if db.bind.dialect.name == "postgresql":
            tables = [
                "users", "vehicles", "workshops", "technicians",
                "incidents", "quotations", "payments", "notifications",
                "evidences", "service_history"
            ]
            if filter_tenant is None:
                tables.insert(0, "tenants")
                
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
