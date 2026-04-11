"""Router de notificaciones: consulta y gestión de notificaciones."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.models.workshop import Workshop
from app.schemas.notification import NotificationResponse
from app.services.notification_service import get_user_notifications, get_workshop_notifications, mark_as_read
from app.utils.security import get_current_user, get_current_workshop

router = APIRouter(prefix="/api/notifications", tags=["Notificaciones"])


@router.get("/user", response_model=list[NotificationResponse])
async def list_user_notifications(
    unread_only: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Listar notificaciones del usuario."""
    return await get_user_notifications(db, current_user.id, unread_only)


@router.get("/workshop", response_model=list[NotificationResponse])
async def list_workshop_notifications(
    unread_only: bool = False,
    db: Session = Depends(get_db),
    current_workshop: Workshop = Depends(get_current_workshop),
):
    """Listar notificaciones del taller."""
    return await get_workshop_notifications(db, current_workshop.id, unread_only)


@router.put("/{notification_id}/read")
async def mark_notification_read(notification_id: int, db: Session = Depends(get_db)):
    """Marcar una notificación como leída."""
    success = await mark_as_read(db, notification_id)
    if not success:
        raise HTTPException(status_code=404, detail="Notificación no encontrada")
    return {"message": "Notificación marcada como leída"}
