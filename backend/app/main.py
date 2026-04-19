"""
Plataforma Inteligente de Atención de Emergencias Vehiculares
Backend API - FastAPI
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from app.config import get_settings
from app.database import engine, Base
from app.routers import auth, users, vehicles, incidents, workshops, payments, notifications

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description=(
        "API para la Plataforma Inteligente de Atención de Emergencias Vehiculares. "
        "Conecta usuarios con talleres mecánicos mediante análisis automatizado de incidentes "
        "usando datos multimodales (imagen, audio, texto y geolocalización)."
    ),
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS para Angular y Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1):.*",  # Permite cualquier puerto de localhost o 127.0.0.1
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Servir archivos estáticos (uploads)
os.makedirs(settings.upload_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.upload_dir), name="uploads")

# Registrar routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(vehicles.router)
app.include_router(incidents.router)
app.include_router(workshops.router)
app.include_router(payments.router)
app.include_router(notifications.router)


@app.on_event("startup")
def on_startup():
    """Crear tablas en la base de datos al iniciar."""
    Base.metadata.create_all(bind=engine)


@app.get("/", tags=["Health"])
def health_check():
    return {
        "status": "ok",
        "app": settings.app_name,
        "version": settings.app_version,
    }


@app.get("/api/health", tags=["Health"])
def api_health():
    return {"status": "healthy", "database": "connected"}
