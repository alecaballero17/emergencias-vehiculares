"""
Plataforma Inteligente de Atención de Emergencias Vehiculares
Backend API - FastAPI - Fase 2: Multi-tenant, WebSockets, Offline, KPIs
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from app.config import get_settings
from app.database import engine, Base
from app.middleware.tenant_middleware import tenant_middleware
from app.routers import (
    auth, users, vehicles, incidents, workshops,
    payments, notifications, quotations, analytics,
    tenants, ai_router, ws_router, backup, voice_assistant,
    tow_truck, reports,
)

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version="2.0.0",
    description=(
        "API para la Plataforma Inteligente de Atención de Emergencias Vehiculares. "
        "Fase 2: Arquitectura Multi-tenant SaaS, WebSockets en tiempo real, "
        "modo offline con sincronización, analítica operacional con KPIs, "
        "cotizaciones abiertas, pasarela de pagos Paralela, e IA en español."
    ),
    docs_url="/docs",
    redoc_url="/redoc",
)

# Middleware Multi-tenant (extrae tenant_id del JWT)
app.middleware("http")(tenant_middleware)

# CORS para Angular y Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permite conexiones desde cualquier origen (Celular, Web, etc.)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Servir archivos estáticos (uploads)
os.makedirs(settings.upload_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.upload_dir), name="uploads")

# Registrar routers REST
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(vehicles.router)
app.include_router(incidents.router)
app.include_router(workshops.router)
app.include_router(payments.router)
app.include_router(notifications.router)
app.include_router(quotations.router)
app.include_router(analytics.router)
app.include_router(tenants.router)
app.include_router(ai_router.router)
app.include_router(backup.router)
app.include_router(voice_assistant.router)
app.include_router(tow_truck.router)
app.include_router(reports.router)

# Registrar router WebSocket
app.include_router(ws_router.router)


@app.on_event("startup")
def on_startup():
    """Crear tablas en la base de datos al iniciar."""
    Base.metadata.create_all(bind=engine)


@app.get("/", tags=["Health"])
def health_check():
    return {
        "status": "ok",
        "app": settings.app_name,
        "version": "2.0.0",
        "features": [
            "multi-tenant",
            "websockets",
            "real-time-tracking",
            "offline-sync",
            "kpis-analytics",
            "quotations",
            "paralela-payments",
            "ai-cost-estimation",
        ],
    }


@app.get("/api/health", tags=["Health"])
def api_health():
    from app.services.websocket_manager import ws_manager
    return {
        "status": "healthy",
        "database": "connected",
        "websockets": ws_manager.get_connected_count(),
        "active_keys": list(ws_manager.active_connections.keys()),
    }
