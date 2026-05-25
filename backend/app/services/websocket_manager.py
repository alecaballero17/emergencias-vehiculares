"""
Gestor de conexiones WebSocket.
Mantiene las conexiones activas de clientes y talleres, indexadas por tipo y ID.
"""
import json
from fastapi import WebSocket
from typing import Optional


class ConnectionManager:
    """Administrador central de conexiones WebSocket."""

    def __init__(self):
        # {entity_key: WebSocket} ej: "user_5", "workshop_3"
        self.active_connections: dict[str, WebSocket] = {}
        # {incident_id: set(entity_key)} - quién está suscrito a qué incidente
        self.incident_subscribers: dict[int, set[str]] = {}

    def _key(self, entity_type: str, entity_id: int) -> str:
        return f"{entity_type}_{entity_id}"

    async def connect(self, ws: WebSocket, entity_type: str, entity_id: int, tenant_id: int):
        """Registra una nueva conexión WebSocket."""
        await ws.accept()
        key = self._key(entity_type, entity_id)
        self.active_connections[key] = ws
        print(f"[WS] Conectado: {key} (tenant={tenant_id})")

    def disconnect(self, entity_type: str, entity_id: int):
        """Elimina una conexión."""
        key = self._key(entity_type, entity_id)
        self.active_connections.pop(key, None)
        # Limpiar suscripciones
        for subs in self.incident_subscribers.values():
            subs.discard(key)
        print(f"[WS] Desconectado: {key}")

    def subscribe_to_incident(self, entity_type: str, entity_id: int, incident_id: int):
        """Suscribe una entidad a actualizaciones de un incidente."""
        key = self._key(entity_type, entity_id)
        if incident_id not in self.incident_subscribers:
            self.incident_subscribers[incident_id] = set()
        self.incident_subscribers[incident_id].add(key)
        print(f"[WS] {key} suscrito a incidente #{incident_id}")

    async def send_to_entity(self, entity_type: str, entity_id: int, payload: dict):
        """Envía un mensaje a una entidad específica."""
        key = self._key(entity_type, entity_id)
        ws = self.active_connections.get(key)
        if ws:
            try:
                await ws.send_json(payload)
            except Exception as e:
                print(f"[WS] Error enviando a {key}: {e}")
                self.active_connections.pop(key, None)

    async def broadcast_to_incident(self, incident_id: int, payload: dict):
        """Envía a todos los suscritos a un incidente."""
        subscribers = self.incident_subscribers.get(incident_id, set())
        disconnected = []
        for key in subscribers:
            ws = self.active_connections.get(key)
            if ws:
                try:
                    await ws.send_json(payload)
                except Exception:
                    disconnected.append(key)
        for key in disconnected:
            self.active_connections.pop(key, None)
            subscribers.discard(key)

    async def broadcast_to_workshops(self, workshop_ids: list[int], payload: dict):
        """Envía alerta a una lista específica de talleres."""
        for wid in workshop_ids:
            key = self._key("workshop", wid)
            ws = self.active_connections.get(key)
            if ws:
                try:
                    await ws.send_json(payload)
                except Exception:
                    self.active_connections.pop(key, None)

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
        users = sum(1 for k in self.active_connections if k.startswith("user_"))
        workshops = sum(1 for k in self.active_connections if k.startswith("workshop_"))
        return {"users": users, "workshops": workshops, "total": len(self.active_connections)}


# Instancia global singleton
ws_manager = ConnectionManager()
