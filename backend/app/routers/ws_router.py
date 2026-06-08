"""
Router WebSocket para comunicación en tiempo real.
Autenticación via JWT, manejo de location updates y suscripciones.
"""
import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.orm import Session
from app.database import get_db, SessionLocal
from app.utils.security import decode_token
from app.models.enums import UserRole
from app.services.websocket_manager import ws_manager

router = APIRouter(tags=["WebSocket"])


@router.websocket("/ws/{token}")
async def websocket_endpoint(websocket: WebSocket, token: str):
    """
    Endpoint WebSocket con autenticación JWT.
    
    Mensajes entrantes soportados:
    - {"type": "subscribe_incident", "incident_id": 123}
    - {"type": "location_update", "incident_id": 123, "latitude": -17.78, "longitude": -63.18, "eta_minutes": 10}
    - {"type": "ping"}
    """
    entity_type = None
    entity_id = None
    try:
        # Autenticar con JWT
        payload = decode_token(token)
        role = payload.get("role")
        entity_id = payload.get("entity_id")
        tenant_id = payload.get("tenant_id")

        # Determinar tipo de entidad
        if role == UserRole.WORKSHOP_ADMIN.value or role == "workshop_admin":
            entity_type = "workshop"
        elif role == UserRole.ADMIN.value or role == "admin":
            entity_type = "workshop"
            db = SessionLocal()
            try:
                from app.models.workshop import Workshop
                workshop = db.query(Workshop).first()
                if workshop:
                    entity_id = workshop.id
                else:
                    entity_id = 1
            finally:
                db.close()
        else:
            entity_type = "user"

        # Registrar conexión
        await ws_manager.connect(websocket, entity_type, entity_id, tenant_id)

        # Enviar confirmación
        await websocket.send_json({
            "type": "connected",
            "entity_type": entity_type,
            "entity_id": entity_id,
            "tenant_id": tenant_id,
            "message": "Conexión WebSocket establecida correctamente"
        })

        # Loop de mensajes
        while True:
            data = await websocket.receive_text()
            try:
                message = json.loads(data)
                msg_type = message.get("type")

                if msg_type == "ping":
                    await websocket.send_json({"type": "pong"})

                elif msg_type == "subscribe_incident":
                    incident_id = message.get("incident_id")
                    if incident_id:
                        ws_manager.subscribe_to_incident(entity_type, entity_id, incident_id)
                        await websocket.send_json({
                            "type": "subscribed",
                            "incident_id": incident_id
                        })

                elif msg_type == "location_update":
                    # Solo talleres/mecánicos pueden enviar ubicación
                    if entity_type == "workshop":
                        incident_id = message.get("incident_id")
                        lat = message.get("latitude")
                        lng = message.get("longitude")
                        eta = message.get("eta_minutes")
                        if incident_id and lat and lng:
                            await ws_manager.send_location_update(
                                incident_id, lat, lng, eta
                            )

                elif msg_type == "unsubscribe_incident":
                    incident_id = message.get("incident_id")
                    key = ws_manager._key(entity_type, entity_id)
                    subs = ws_manager.incident_subscribers.get(incident_id, set())
                    subs.discard(key)

            except json.JSONDecodeError:
                await websocket.send_json({"type": "error", "message": "JSON inválido"})

    except WebSocketDisconnect:
        if entity_type and entity_id:
            ws_manager.disconnect(entity_type, entity_id, websocket)
    except Exception as e:
        print(f"[WS] Error en conexion: {e}")
        if entity_type and entity_id:
            try:
                ws_manager.disconnect(entity_type, entity_id, websocket)
            except Exception:
                pass


