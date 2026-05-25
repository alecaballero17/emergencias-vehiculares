"""
Router de Analítica Operacional y KPIs.
TODOS los indicadores se calculan desde datos REALES de la base de datos, filtrados por tenant.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, case, extract
from datetime import datetime, timedelta
import pytz
from app.database import get_db
from app.models.workshop import Workshop
from app.models.incident import Incident
from app.models.service_history import ServiceHistory
from app.models.enums import IncidentStatus
from app.utils.security import get_current_workshop

BOL_TZ = pytz.timezone('America/La_Paz')
router = APIRouter(prefix="/api/analytics", tags=["Analítica KPIs"])


@router.get("/assignment-time")
def get_avg_assignment_time(
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """
    KPI: Tiempo promedio de asignación.
    Diferencia de timestamps entre created_at y assigned_at.
    """
    tenant_id = current_workshop.tenant_id
    incidents = db.query(Incident).filter(
        Incident.tenant_id == tenant_id,
        Incident.assigned_at.isnot(None),
        Incident.created_at.isnot(None),
    ).all()

    if not incidents:
        return {"avg_minutes": 0, "total_incidents": 0, "detail": "Sin datos"}

    total_seconds = 0
    count = 0
    for inc in incidents:
        if inc.assigned_at and inc.created_at:
            diff = (inc.assigned_at.replace(tzinfo=None) - inc.created_at.replace(tzinfo=None)).total_seconds()
            if diff > 0:
                total_seconds += diff
                count += 1

    avg_minutes = round((total_seconds / count) / 60, 2) if count > 0 else 0

    return {
        "avg_minutes": avg_minutes,
        "total_incidents": count,
        "detail": f"Calculado sobre {count} incidentes con asignación"
    }


@router.get("/arrival-time")
def get_avg_arrival_time(
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """
    KPI: Tiempo promedio de llegada.
    Diferencia entre assigned_at y attending_at.
    """
    tenant_id = current_workshop.tenant_id
    incidents = db.query(Incident).filter(
        Incident.tenant_id == tenant_id,
        Incident.assigned_at.isnot(None),
        Incident.attending_at.isnot(None),
    ).all()

    if not incidents:
        return {"avg_minutes": 0, "total_incidents": 0, "detail": "Sin datos"}

    total_seconds = 0
    count = 0
    for inc in incidents:
        if inc.attending_at and inc.assigned_at:
            diff = (inc.attending_at.replace(tzinfo=None) - inc.assigned_at.replace(tzinfo=None)).total_seconds()
            if diff > 0:
                total_seconds += diff
                count += 1

    avg_minutes = round((total_seconds / count) / 60, 2) if count > 0 else 0

    return {
        "avg_minutes": avg_minutes,
        "total_incidents": count,
        "detail": f"Calculado sobre {count} incidentes con atención"
    }


@router.get("/incidents-by-type")
def get_incidents_by_type(
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """
    KPI: Incidentes por tipo.
    Para gráfico de torta/barras basado en la clasificación IA.
    """
    tenant_id = current_workshop.tenant_id
    results = (
        db.query(
            Incident.incident_type,
            func.count(Incident.id).label("count")
        )
        .filter(Incident.tenant_id == tenant_id)
        .group_by(Incident.incident_type)
        .all()
    )

    type_labels = {
        "battery": "Batería",
        "tire": "Llanta",
        "crash": "Choque",
        "engine": "Motor",
        "other": "Otros",
    }

    data = []
    for row in results:
        type_val = row[0].value if hasattr(row[0], 'value') else str(row[0])
        data.append({
            "type": type_val,
            "label": type_labels.get(type_val, type_val),
            "count": row[1],
        })

    return {"data": data, "total": sum(d["count"] for d in data)}


@router.get("/top-workshops")
def get_top_workshops(
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """
    KPI: Talleres más eficientes.
    Ranking por menor tiempo de respuesta y tasa de finalización.
    """
    tenant_id = current_workshop.tenant_id
    workshops = db.query(Workshop).filter(Workshop.tenant_id == tenant_id).all()

    ranking = []
    for ws in workshops:
        incidents = db.query(Incident).filter(
            Incident.workshop_id == ws.id,
            Incident.tenant_id == tenant_id,
        ).all()

        total = len(incidents)
        completed = sum(1 for i in incidents if i.status == IncidentStatus.COMPLETED)
        completion_rate = round((completed / total) * 100, 1) if total > 0 else 0

        # Tiempo promedio de respuesta (assigned_at - searching_at)
        response_times = []
        for inc in incidents:
            if inc.assigned_at and inc.searching_at:
                diff = (inc.assigned_at.replace(tzinfo=None) - inc.searching_at.replace(tzinfo=None)).total_seconds()
                if diff > 0:
                    response_times.append(diff / 60)

        avg_response = round(sum(response_times) / len(response_times), 2) if response_times else 0

        ranking.append({
            "workshop_id": ws.id,
            "workshop_name": ws.name,
            "total_incidents": total,
            "completed": completed,
            "completion_rate": completion_rate,
            "avg_response_minutes": avg_response,
        })

    # Ordenar por completion_rate desc, luego avg_response asc
    ranking.sort(key=lambda x: (-x["completion_rate"], x["avg_response_minutes"]))

    return {"data": ranking}


@router.get("/incident-heatmap")
def get_incident_heatmap(
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """
    KPI: Zonas con más incidentes.
    Retorna coordenadas de geolocalización para mapa de calor (Heatmap).
    """
    tenant_id = current_workshop.tenant_id
    incidents = db.query(
        Incident.latitude,
        Incident.longitude,
        Incident.incident_type,
    ).filter(
        Incident.tenant_id == tenant_id,
        Incident.latitude.isnot(None),
        Incident.longitude.isnot(None),
    ).all()

    points = [
        {
            "lat": inc.latitude,
            "lng": inc.longitude,
            "type": inc.incident_type.value if hasattr(inc.incident_type, 'value') else str(inc.incident_type),
        }
        for inc in incidents
    ]

    return {"points": points, "total": len(points)}


@router.get("/cancelled-cases")
def get_cancelled_cases(
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """
    KPI: Casos cancelados.
    Emergencias cuyo estado final fue cancelado o que expiraron sin atención.
    """
    tenant_id = current_workshop.tenant_id

    total = db.query(Incident).filter(Incident.tenant_id == tenant_id).count()
    cancelled = db.query(Incident).filter(
        Incident.tenant_id == tenant_id,
        Incident.status == IncidentStatus.CANCELLED,
    ).count()

    # Incidentes que llevan más de 2 horas en buscando_taller (expirados)
    two_hours_ago = datetime.now() - timedelta(hours=2)
    expired = db.query(Incident).filter(
        Incident.tenant_id == tenant_id,
        Incident.status == IncidentStatus.SEARCHING,
        Incident.created_at < two_hours_ago,
    ).count()

    cancellation_rate = round((cancelled / total) * 100, 1) if total > 0 else 0

    # Detalle de cancelaciones recientes
    recent_cancelled = db.query(Incident).filter(
        Incident.tenant_id == tenant_id,
        Incident.status == IncidentStatus.CANCELLED,
    ).order_by(Incident.cancelled_at.desc()).limit(10).all()

    details = [
        {
            "incident_id": inc.id,
            "incident_type": inc.incident_type.value if hasattr(inc.incident_type, 'value') else str(inc.incident_type),
            "cancellation_fee": inc.cancellation_fee,
            "cancelled_at": inc.cancelled_at.isoformat() if inc.cancelled_at else None,
        }
        for inc in recent_cancelled
    ]

    return {
        "total_incidents": total,
        "cancelled": cancelled,
        "expired": expired,
        "cancellation_rate": cancellation_rate,
        "recent_details": details,
    }


@router.get("/sla-compliance")
def get_sla_compliance(
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """
    KPI: Nivel de cumplimiento SLA.
    Porcentaje de servicios cuyo tiempo de llegada real fue <= al estimado.
    """
    tenant_id = current_workshop.tenant_id
    incidents = db.query(Incident).filter(
        Incident.tenant_id == tenant_id,
        Incident.assigned_at.isnot(None),
        Incident.attending_at.isnot(None),
        Incident.estimated_arrival_minutes.isnot(None),
    ).all()

    if not incidents:
        return {"sla_percent": 0, "compliant": 0, "total": 0, "detail": "Sin datos"}

    compliant = 0
    for inc in incidents:
        actual_minutes = (inc.attending_at.replace(tzinfo=None) - inc.assigned_at.replace(tzinfo=None)).total_seconds() / 60
        if actual_minutes <= inc.estimated_arrival_minutes:
            compliant += 1

    total = len(incidents)
    sla_percent = round((compliant / total) * 100, 1) if total > 0 else 0

    return {
        "sla_percent": sla_percent,
        "compliant": compliant,
        "non_compliant": total - compliant,
        "total": total,
    }


@router.get("/summary")
def get_dashboard_summary(
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Resumen general del dashboard con todos los KPIs en una sola llamada."""
    tenant_id = current_workshop.tenant_id

    total = db.query(Incident).filter(Incident.tenant_id == tenant_id).count()
    active = db.query(Incident).filter(
        Incident.tenant_id == tenant_id,
        Incident.status.in_([
            IncidentStatus.PENDING, IncidentStatus.SEARCHING,
            IncidentStatus.ASSIGNED, IncidentStatus.EN_ROUTE,
            IncidentStatus.ATTENDING,
        ]),
    ).count()
    completed = db.query(Incident).filter(
        Incident.tenant_id == tenant_id,
        Incident.status == IncidentStatus.COMPLETED,
    ).count()
    cancelled = db.query(Incident).filter(
        Incident.tenant_id == tenant_id,
        Incident.status == IncidentStatus.CANCELLED,
    ).count()

    return {
        "total_incidents": total,
        "active_incidents": active,
        "completed_incidents": completed,
        "cancelled_incidents": cancelled,
        "completion_rate": round((completed / total) * 100, 1) if total > 0 else 0,
    }
