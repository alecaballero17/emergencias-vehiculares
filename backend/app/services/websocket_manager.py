"""
Gestor de conexiones WebSocket.
Mantiene las conexiones activas de clientes y talleres, indexadas por tipo y ID.
Soporta múltiples conexiones por entidad (varias pestañas/sesiones).
"""
import json
import logging
from fastapi import WebSocket
from typing import Optional

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Administrador central de conexiones WebSocket."""

    def __init__(self):
        # {entity_key: [WebSocket, ...]} ej: "user_5": [ws1, ws2], "workshop_3": [ws1]
        self.active_connections: dict[str, list[WebSocket]] = {}
        # {incident_id: set(entity_key)} - quién está suscrito a qué incidente
        self.incident_subscribers: dict[int, set[str]] = {}

    def _key(self, entity_type: str, entity_id: int) -> str:
        return f"{entity_type}_{entity_id}"

    async def connect(self, ws: WebSocket, entity_type: str, entity_id: int, tenant_id: int):
        """Registra una nueva conexión WebSocket."""
        await ws.accept()
        key = self._key(entity_type, entity_id)
        if key not in self.active_connections:
            self.active_connections[key] = []
        self.active_connections[key].append(ws)
        logger.info(f"[WS] Conectado: {key} (tenant={tenant_id}) — Total conexiones para {key}: {len(self.active_connections[key])}")
        print(f"[WS] Conectado: {key} (tenant={tenant_id}) — Total conexiones para {key}: {len(self.active_connections[key])}")

    def disconnect(self, entity_type: str, entity_id: int, ws: WebSocket):
        """Elimina una conexión específica de la lista."""
        key = self._key(entity_type, entity_id)
        connections = self.active_connections.get(key, [])
        if ws in connections:
            connections.remove(ws)
            if not connections:
                self.active_connections.pop(key, None)
                # Limpiar suscripciones si ya no hay conexiones
                for subs in self.incident_subscribers.values():
                    subs.discard(key)
            logger.info(f"[WS] Desconectado: {key} — Restantes: {len(connections)}")
            print(f"[WS] Desconectado: {key} — Restantes: {len(connections)}")
        else:
            logger.debug(f"[WS] Ignorado desconexión obsoleta para {key}")

    def subscribe_to_incident(self, entity_type: str, entity_id: int, incident_id: int):
        """Suscribe una entidad a actualizaciones de un incidente."""
        key = self._key(entity_type, entity_id)
        if incident_id not in self.incident_subscribers:
            self.incident_subscribers[incident_id] = set()
        self.incident_subscribers[incident_id].add(key)
        print(f"[WS] {key} suscrito a incidente #{incident_id}")

    async def _send_to_all(self, key: str, payload: dict):
        """Envía un mensaje a TODAS las conexiones de una entidad. Limpia las muertas."""
        connections = self.active_connections.get(key, [])
        if not connections:
            return
        dead = []
        for ws in connections:
            try:
                await ws.send_json(payload)
            except Exception as e:
                logger.warning(f"[WS] Error enviando a {key}: {e}")
                dead.append(ws)
        # Limpiar conexiones muertas
        for ws in dead:
            if ws in connections:
                connections.remove(ws)
        if not connections:
            self.active_connections.pop(key, None)

    async def send_to_entity(self, entity_type: str, entity_id: int, payload: dict):
        """Envía un mensaje a todas las conexiones de una entidad específica."""
        key = self._key(entity_type, entity_id)
        await self._send_to_all(key, payload)

    async def broadcast_to_incident(self, incident_id: int, payload: dict):
        """Envía a todos los suscritos a un incidente."""
        subscribers = self.incident_subscribers.get(incident_id, set()).copy()
        for key in subscribers:
            await self._send_to_all(key, payload)
        # Limpiar suscripciones de entidades sin conexiones
        remaining = self.incident_subscribers.get(incident_id, set())
        dead_keys = [k for k in remaining if k not in self.active_connections]
        for k in dead_keys:
            remaining.discard(k)

    async def broadcast_to_workshops(self, workshop_ids: list[int], payload: dict):
        """Envía alerta a una lista específica de talleres."""
        for wid in workshop_ids:
            key = self._key("workshop", wid)
            await self._send_to_all(key, payload)

    async def send_location_update(self, incident_id: int, latitude: float, longitude: float, eta_minutes: int | None = None):
        """Envía actualización de ubicación del mecánico a suscritos del incidente."""
        payload = {
            "type": "location_update",
            "incident_id": incident_id,
            "latitude": latitude,
            "longitude": longitude,
            "eta_minutes": eta_minutes,
        }
        await self.broadcast_to_incident(incident_id, payload)

    def get_connected_count(self) -> dict:
        """Retorna estadísticas de conexiones activas."""
        users = sum(len(v) for k, v in self.active_connections.items() if k.startswith("user_"))
        workshops = sum(len(v) for k, v in self.active_connections.items() if k.startswith("workshop_"))
        total = sum(len(v) for v in self.active_connections.values())
        return {"users": users, "workshops": workshops, "total": total, "entities": len(self.active_connections)}


# Instancia global singleton
ws_manager = ConnectionManager()
