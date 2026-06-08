"""
Servicio de notificaciones push, en base de datos y en tiempo real (WebSocket).
Con retry logic, logging y manejo robusto de errores.
"""
import asyncio
import logging
from sqlalchemy.orm import Session
from app.models.notification import Notification
from app.models.user import User
from app.models.workshop import Workshop
from app.services.websocket_manager import ws_manager

logger = logging.getLogger(__name__)


async def notify_user(db: Session, user_id: int, title: str, message: str, notification_type: str, tenant_id: int = None) -> Notification:
    """
    Envía una notificación a un usuario por BD + WebSocket + Push (con reintentos).
    
    Se intenta enviar por Firebase 3 veces antes de fallar silenciosamente.
    """
    # Obtener tenant_id si no se proporcionó
    if not tenant_id:
        user = db.query(User).filter(User.id == user_id).first()
        tenant_id = user.tenant_id if user else 1

    notif = Notification(
        tenant_id=tenant_id,
        user_id=user_id,
        title=title,
        message=message,
        notification_type=notification_type,
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)

    # Enviar por WebSocket en tiempo real (no-blocking)
    try:
        await ws_manager.send_to_entity("user", user_id, {
            "type": "notification",
            "notification_id": notif.id,
            "title": title,
            "message": message,
            "notification_type": notification_type,
        })
    except Exception as e:
        logger.warning(f"Error enviando WebSocket a user {user_id}: {str(e)}")

    # Enviar push notification si tiene token (con reintentos)
    user = db.query(User).filter(User.id == user_id).first()
    if user and user.firebase_token:
        await _send_push_with_retry(user.firebase_token, title, message, user_id)

    return notif


async def notify_workshop(db: Session, workshop_id: int, title: str, message: str, notification_type: str, tenant_id: int = None) -> Notification:
    """Envía una notificación a un taller por BD + WebSocket + Push (con reintentos)."""
    if not tenant_id:
        workshop = db.query(Workshop).filter(Workshop.id == workshop_id).first()
        tenant_id = workshop.tenant_id if workshop else 1

    notif = Notification(
        tenant_id=tenant_id,
        workshop_id=workshop_id,
        title=title,
        message=message,
        notification_type=notification_type,
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)

    # Enviar por WebSocket en tiempo real (no-blocking)
    try:
        await ws_manager.send_to_entity("workshop", workshop_id, {
            "type": "notification",
            "notification_id": notif.id,
            "title": title,
            "message": message,
            "notification_type": notification_type,
        })
    except Exception as e:
        logger.warning(f"Error enviando WebSocket a workshop {workshop_id}: {str(e)}")

    # Enviar push notification (con reintentos)
    workshop = db.query(Workshop).filter(Workshop.id == workshop_id).first()
    if workshop and workshop.firebase_token:
        await _send_push_with_retry(workshop.firebase_token, title, message, workshop_id, entity_type="workshop")

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


async def _send_push_with_retry(token: str, title: str, body: str, entity_id: int, entity_type: str = "user", max_retries: int = 3):
    """
    Envía notificación push via Firebase con reintentos.
    
    Args:
        token: Token de Firebase del usuario/taller
        title: Título de la notificación
        body: Cuerpo de la notificación
        entity_id: ID del usuario o taller
        entity_type: "user" o "workshop"
        max_retries: Número máximo de intentos
    """
    for attempt in range(max_retries):
        try:
            await _send_push(token, title, body)
            logger.info(f"Notificación enviada a {entity_type} {entity_id} (intento {attempt + 1})")
            return True
        except Exception as e:
            logger.warning(f"Intento {attempt + 1} fallido para {entity_type} {entity_id}: {str(e)}")
            if attempt < max_retries - 1:
                await asyncio.sleep(2 ** attempt)  # Backoff exponencial: 1s, 2s, 4s
            else:
                logger.error(f"No se pudo enviar notificación a {entity_type} {entity_id} después de {max_retries} intentos")
    
    return False


async def _send_push(token: str, title: str, body: str):
    """Envía notificación push via Firebase Cloud Messaging."""
    try:
        import firebase_admin
        from firebase_admin import messaging

        if not firebase_admin._apps:
            raise Exception("Firebase no inicializado")

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=token,
        )
        response = messaging.send(message)
        logger.info(f"Firebase response: {response}")
        return response

    except Exception as e:
        logger.error(f"Error en Firebase: {str(e)}")
        raise
