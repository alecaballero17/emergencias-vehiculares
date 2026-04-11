# Emergencias Vehiculares - Backend API

## Plataforma Inteligente de Atención de Emergencias Vehiculares

### Stack
- **Backend**: FastAPI (Python)
- **Base de datos**: PostgreSQL
- **IA**: OpenAI (Whisper + GPT-4o)
- **Notificaciones**: Firebase Cloud Messaging

### Estructura del proyecto
```
backend/
├── app/
│   ├── main.py              # Aplicación FastAPI principal
│   ├── config.py             # Configuración (variables de entorno)
│   ├── database.py           # Conexión a PostgreSQL
│   ├── models/               # Modelos SQLAlchemy
│   │   ├── user.py           # Usuarios/clientes
│   │   ├── vehicle.py        # Vehículos
│   │   ├── workshop.py       # Talleres
│   │   ├── technician.py     # Técnicos
│   │   ├── incident.py       # Incidentes/emergencias
│   │   ├── evidence.py       # Evidencias (imagen, audio, texto)
│   │   ├── service_history.py # Historial de servicio
│   │   ├── payment.py        # Pagos y comisiones
│   │   └── notification.py   # Notificaciones
│   ├── schemas/              # Esquemas Pydantic (validación)
│   ├── routers/              # Endpoints API REST
│   │   ├── auth.py           # Autenticación (registro/login)
│   │   ├── users.py          # Gestión de usuarios
│   │   ├── vehicles.py       # CRUD vehículos
│   │   ├── incidents.py      # Reporte y gestión de incidentes
│   │   ├── workshops.py      # Operaciones de talleres
│   │   ├── payments.py       # Pagos
│   │   └── notifications.py  # Notificaciones
│   ├── services/             # Lógica de negocio
│   │   ├── incident_service.py    # Orquestación de incidentes
│   │   ├── assignment_service.py  # Motor de asignación inteligente
│   │   └── notification_service.py # Servicio de notificaciones
│   ├── ai/                   # Módulos de inteligencia artificial
│   │   ├── audio_processor.py     # Transcripción de audio (Whisper)
│   │   ├── image_classifier.py    # Clasificación de imágenes (GPT-4o Vision)
│   │   ├── incident_classifier.py # Clasificación multimodal de incidentes
│   │   └── summary_generator.py   # Generación de resúmenes automáticos
│   └── utils/                # Utilidades
│       ├── security.py       # JWT, hashing, autenticación
│       └── geolocation.py    # Cálculos de distancia (Haversine)
├── alembic/                  # Migraciones de BD
├── uploads/                  # Archivos subidos
├── requirements.txt
├── alembic.ini
└── .env
```

### Instalación y ejecución

```bash
# 1. Crear entorno virtual (ya creado en venv/)
python -m venv venv
venv\Scripts\activate

# 2. Instalar dependencias (ya instaladas)
pip install -r requirements.txt

# 3. Crear base de datos PostgreSQL
# Abrir pgAdmin o ejecutar en psql:
# CREATE DATABASE emergencias_vehiculares;
# 
# IMPORTANTE: Editar .env con la contraseña correcta de tu usuario postgres:
# DATABASE_URL=postgresql://postgres:TU_PASSWORD@localhost:5432/emergencias_vehiculares

# 4. Cargar datos de prueba
python -m app.seed

# 5. Ejecutar servidor
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 6. Abrir documentación: http://localhost:8000/docs
```

### Credenciales de prueba (después de ejecutar seed)
- **Usuarios**: `carlos@example.com` / `maria@example.com` (password: `password123`)
- **Talleres**: `elrapido@example.com` / `lopez@example.com` / `premium@example.com` (password: `taller123`)

### Documentación API
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### Endpoints principales

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | /api/auth/register/user | Registro de usuario |
| POST | /api/auth/register/workshop | Registro de taller |
| POST | /api/auth/login | Login unificado |
| GET | /api/users/me | Perfil del usuario |
| POST | /api/vehicles/ | Registrar vehículo |
| GET | /api/vehicles/ | Listar vehículos |
| POST | /api/incidents/ | Reportar emergencia (multimodal) |
| GET | /api/incidents/ | Listar mis incidentes |
| GET | /api/incidents/{id} | Detalle de incidente |
| GET | /api/workshops/me | Perfil del taller |
| POST | /api/workshops/technicians | Agregar técnico |
| GET | /api/workshops/incidents | Incidentes del taller |
| PUT | /api/workshops/incidents/{id}/accept | Aceptar incidente |
| PUT | /api/workshops/incidents/{id}/complete | Completar servicio |
| POST | /api/payments/{incident_id} | Realizar pago |
| GET | /api/notifications/user | Notificaciones usuario |
| GET | /api/notifications/workshop | Notificaciones taller |
