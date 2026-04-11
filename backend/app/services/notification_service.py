"""
Servicio de notificaciones push y en tiempo real.
Soporta notificaciones a usuarios y talleres.
"""
from sqlalchemy.orm import Session
from app.models.notification import Notification
from app.models.user import User
from app.models.workshop import Workshop


async def notify_user(db: Session, user_id: int, title: str, message: str, notification_type: str) -> Notification:
    """Envía una notificación a un usuario."""
    notif = Notification(
        user_id=user_id,
        title=title,
        message=message,
        notification_type=notification_type,
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)

    # Enviar push notification si tiene token
    user = db.query(User).filter(User.id == user_id).first()
    if user and user.firebase_token:
        await _send_push(user.firebase_token, title, message)

    return notif


async def notify_workshop(db: Session, workshop_id: int, title: str, message: str, notification_type: str) -> Notification:
    """Envía una notificación a un taller."""
    notif = Notification(
        workshop_id=workshop_id,
        title=title,
        message=message,
        notification_type=notification_type,
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)

    # Enviar push notification
    workshop = db.query(Workshop).filter(Workshop.id == workshop_id).first()
    if workshop and workshop.firebase_token:
        await _send_push(workshop.firebase_token, title, message)

    return notif


async def get_user_notifications(db: Session, user_id: int, unread_only: bool = False) -> list[Notification]:
    """Obtiene las notificaciones de un usuario."""
    query = db.query(Notification).filter(Notification.user_id == user_id)
    if unread_only:
        query = query.filter(Notification.is_read == False)
    return query.order_by(Notification.created_at.desc()).all()


async def get_workshop_notifications(db: Session, workshop_id: int, unread_only: bool = False) -> list[Notification]:
    """Obtiene las notificaciones de un taller."""
    query = db.query(Notification).filter(Notification.workshop_id == workshop_id)
    if unread_only:
        query = query.filter(Notification.is_read == False)
    return query.order_by(Notification.created_at.desc()).all()


async def mark_as_read(db: Session, notification_id: int) -> bool:
    """Marca una notificación como leída."""
    notif = db.query(Notification).filter(Notification.id == notification_id).first()
    if notif:
        notif.is_read = True
        db.commit()
        return True
    return False


async def _send_push(token: str, title: str, body: str):
    """Envía notificación push via Firebase Cloud Messaging."""
    try:
        import firebase_admin
        from firebase_admin import messaging

        if not firebase_admin._apps:
            return  # Firebase no inicializado

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=token,
        )
        messaging.send(message)
    except Exception:
        pass  # No bloquear el flujo si falla la push notification
