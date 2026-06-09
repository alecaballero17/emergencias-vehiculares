"""Router para exportación de reportes en múltiples formatos: PDF, HTML, Excel."""
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from datetime import datetime, timedelta
import io
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.models.workshop import Workshop
from app.utils.security import get_current_entity, get_current_workshop
from app.services.report_generator import ReportGenerator

router = APIRouter(prefix="/api/reports", tags=["Reportes"])


@router.get("/incidents/export", status_code=200)
async def export_incidents_report(
    format: str = Query("pdf", regex="^(pdf|html|excel)$"),
    days: int = Query(30, ge=1, le=365),
    db: Session = Depends(get_db),
    current_entity: dict = Depends(get_current_entity),
):
    """
    Exporta reporte de incidentes en PDF, HTML o Excel.
    
    Args:
        format: "pdf", "html" o "excel"
        days: Número de días hacia atrás (default: 30)
    """
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)

    try:
        content = ReportGenerator.generate_incidents_report(
            db,
            current_entity["tenant_id"],
            start_date,
            end_date,
            format=format,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generando reporte: {str(e)}")

    # Definir tipo de contenido y extensión
    if format == "pdf":
        media_type = "application/pdf"
        filename = f"incidents_report_{end_date.strftime('%Y%m%d')}.pdf"
    elif format == "html":
        media_type = "text/html; charset=utf-8"
        filename = f"incidents_report_{end_date.strftime('%Y%m%d')}.html"
    else:  # excel
        media_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        filename = f"incidents_report_{end_date.strftime('%Y%m%d')}.xlsx"

    return StreamingResponse(
        io.BytesIO(content),
        media_type=media_type,
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


@router.get("/financial/export", status_code=200)
async def export_financial_report(
    format: str = Query("pdf", regex="^(pdf|html|excel)$"),
    days: int = Query(30, ge=1, le=365),
    db: Session = Depends(get_db),
    current_entity: dict = Depends(get_current_entity),
):
    """
    Exporta reporte financiero en PDF, HTML o Excel.
    
    Args:
        format: "pdf", "html" o "excel"
        days: Número de días hacia atrás (default: 30)
    """
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)

    try:
        content = ReportGenerator.generate_financial_report(
            db,
            current_entity["tenant_id"],
            start_date,
            end_date,
            format=format,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generando reporte: {str(e)}")

    if format == "pdf":
        media_type = "application/pdf"
        filename = f"financial_report_{end_date.strftime('%Y%m%d')}.pdf"
    elif format == "html":
        media_type = "text/html; charset=utf-8"
        filename = f"financial_report_{end_date.strftime('%Y%m%d')}.html"
    else:  # excel
        media_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        filename = f"financial_report_{end_date.strftime('%Y%m%d')}.xlsx"

    return StreamingResponse(
        io.BytesIO(content),
        media_type=media_type,
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


@router.get("/workshop/incidents/export", status_code=200)
async def export_workshop_incidents_report(
    format: str = Query("pdf", regex="^(pdf|html|excel)$"),
    days: int = Query(30, ge=1, le=365),
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """
    Exporta reporte de incidentes del taller en PDF, HTML o Excel.
    """
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)

    # Filtrar incidentes solo del taller
    try:
        content = ReportGenerator.generate_incidents_report(
            db,
            current_workshop.tenant_id,
            start_date,
            end_date,
            format=format,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generando reporte: {str(e)}")

    if format == "pdf":
        media_type = "application/pdf"
        filename = f"workshop_incidents_{end_date.strftime('%Y%m%d')}.pdf"
    elif format == "html":
        media_type = "text/html; charset=utf-8"
        filename = f"workshop_incidents_{end_date.strftime('%Y%m%d')}.html"
    else:  # excel
        media_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        filename = f"workshop_incidents_{end_date.strftime('%Y%m%d')}.xlsx"

    return StreamingResponse(
        io.BytesIO(content),
        media_type=media_type,
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )
