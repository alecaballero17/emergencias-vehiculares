<p align="center">
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white" alt="Angular"/>
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/OpenAI-412991?style=for-the-badge&logo=openai&logoColor=white" alt="OpenAI"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
</p>

# 🚗 Plataforma Inteligente de Atención de Emergencias Vehiculares

> Sistema multiplataforma que conecta a conductores con emergencias mecánicas en carretera con talleres especializados cercanos.

---

## 🚀 Preparación Rápida para la Defensa

Para iniciar la demostración completa, abre **tres terminales** y ejecuta los siguientes comandos:

### 1. Backend (Cerebro IA)
```powershell
cd backend
.\venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
📍 Swagger: [http://localhost:8000/docs](http://localhost:8000/docs)

### 2. Panel Web (Administración de Talleres)
```powershell
cd frontend-web
npm start
```
📍 Web: [http://localhost:4200](http://localhost:4200)

### 3. App Móvil (Reportero SOS)
```powershell
cd mobile_app
flutter run -d chrome
```

---

## 📋 Tabla de Contenidos

- [Descripción](#-descripción)
- [Arquitectura](#-arquitectura)
- [Tecnologías](#-tecnologías)
- [Módulos de IA](#-módulos-de-ia)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación y Configuración](#-instalación-y-configuración)
- [Ejecución](#-ejecución)
- [API Endpoints](#-api-endpoints)
- [Credenciales de Prueba](#-credenciales-de-prueba)
- [Capturas de Pantalla](#-capturas-de-pantalla)
- [Autores](#-autores)

---

## 📖 Descripción

La plataforma resuelve el problema que enfrentan los conductores al sufrir una avería mecánica en carretera: desconocen qué talleres están cerca, no pueden evaluar su especialidad o disponibilidad, y carecen de un canal eficiente para comunicar la naturaleza exacta del problema.

### ¿Cómo funciona?

1. **El cliente reporta** una emergencia desde la app móvil con texto, fotos, audio y GPS.
2. **La IA procesa** automáticamente toda la evidencia multimedia.
3. **El sistema clasifica** el tipo de incidente y su prioridad mediante votación ponderada.
4. **El motor de asignación** encuentra el mejor taller según distancia, especialidad, disponibilidad y carga de trabajo.
5. **El taller recibe** la notificación, acepta el servicio y envía a su técnico.
6. **El cliente paga** al finalizar el servicio, con una comisión del 10% para la plataforma.

---

## 🏗 Arquitectura

```
┌─────────────────┐     ┌─────────────────┐
│   📱 Flutter     │     │  🖥️ Angular 20   │
│   (Clientes)     │     │   (Talleres)     │
└────────┬────────┘     └────────┬────────┘
         │    HTTPS + JWT        │
         └──────────┬────────────┘
                    │
          ┌─────────▼─────────┐
          │  ⚙️ FastAPI        │
          │  Backend API       │
          │  Puerto 8000       │
          ├────────────────────┤
          │ 🧠 Módulos IA      │
          │ • AudioProcessor   │
          │ • ImageClassifier  │
          │ • IncidentClassif. │
          │ • SummaryGenerator │
          ├────────────────────┤
          │ 🔍 Servicios       │
          │ • IncidentService  │
          │ • AssignmentService│
          │ • NotificationServ.│
          └─────────┬─────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
  ┌─────▼─────┐ ┌──▼───┐ ┌────▼─────┐
  │🗄️ Postgres│ │☁️ Open│ │🔔 Firebase│
  │   SQL 16  │ │  AI  │ │   FCM    │
  └───────────┘ └──────┘ └──────────┘
```

---

## 🛠 Tecnologías

| Capa | Tecnología | Versión |
|------|-----------|---------|
| **Backend** | FastAPI + Uvicorn | Python 3.12 |
| **ORM** | SQLAlchemy | 2.x |
| **Migraciones** | Alembic | - |
| **Base de Datos** | PostgreSQL | 16 |
| **Frontend Web** | Angular (Standalone) | 20 |
| **App Móvil** | Flutter | 3.x |
| **IA - Audio** | OpenAI Whisper | API |
| **IA - Imágenes** | GPT-4o Vision | API |
| **IA - Texto** | GPT-4o-mini | API |
| **Notificaciones** | Firebase Cloud Messaging | - |
| **Autenticación** | JWT (HS256) + bcrypt | 24h expiry |
| **Estilos** | SCSS + Google Fonts (Inter) | - |

---

## 🧠 Módulos de IA

### Procesamiento de Audio
- **Whisper API**: Transcribe grabaciones de audio del conductor a texto.
- **GPT-4o-mini**: Extrae palabras clave, tipo de incidente y severidad de la transcripción.

### Análisis de Imágenes
- **GPT-4o Vision**: Analiza fotografías del vehículo para identificar el tipo de daño, componentes afectados y nivel de severidad.

### Clasificación Inteligente
Sistema de **votación ponderada** que combina las tres fuentes de información:

| Fuente | Peso |
|--------|------|
| Texto descriptivo | 30% |
| Audio transcrito | 35% |
| Imágenes analizadas | 35% |

Determina: **tipo de incidente** (8 categorías), **prioridad** (baja/media/alta/crítica) y **nivel de confianza**.

### Motor de Asignación Inteligente
Algoritmo multifactor para seleccionar el mejor taller:

| Factor | Peso |
|--------|------|
| Distancia geográfica (Haversine) | 35% |
| Especialidad del taller | 25% |
| Disponibilidad de técnicos | 20% |
| Capacidad del taller | 10% |
| Carga de trabajo actual | 10% |

> Radio máximo de búsqueda: **50 km**

---

## 📁 Estructura del Proyecto

```
emergencias-vehiculares/
├── 📂 backend/                  # API REST - FastAPI
│   ├── app/
│   │   ├── main.py              # Punto de entrada
│   │   ├── config.py            # Variables de entorno
│   │   ├── database.py          # Conexión PostgreSQL
│   │   ├── seed.py              # Datos de prueba
│   │   ├── ai/                  # Módulos de IA
│   │   │   ├── audio_processor.py
│   │   │   ├── image_classifier.py
│   │   │   ├── incident_classifier.py
│   │   │   └── summary_generator.py
│   │   ├── models/              # Modelos SQLAlchemy (10)
│   │   ├── routers/             # Endpoints API (7 routers)
│   │   ├── schemas/             # Validación Pydantic
│   │   ├── services/            # Lógica de negocio
│   │   └── utils/               # Seguridad y geolocalización
│   ├── alembic/                 # Migraciones de BD
│   ├── uploads/                 # Archivos multimedia
│   ├── requirements.txt
│   └── alembic.ini
│
├── 📂 frontend-web/             # App Web - Angular 20
│   ├── src/app/
│   │   ├── guards/              # AuthGuard
│   │   ├── interceptors/        # JWT Interceptor
│   │   ├── layout/              # Sidebar + Navigation
│   │   ├── models/              # Interfaces TypeScript
│   │   ├── pages/               # 8 páginas
│   │   │   ├── login/
│   │   │   ├── dashboard/
│   │   │   ├── available/
│   │   │   ├── incidents/
│   │   │   ├── incident-detail/
│   │   │   ├── technicians/
│   │   │   ├── notifications/
│   │   │   └── profile/
│   │   └── services/            # AuthService, WorkshopService
│   └── src/environments/
│
├── 📂 docs/                     # Documentación y diagramas
│   └── diagramas-puds.md
│
└── .gitignore
```

---

## 📌 Requisitos Previos

| Software | Versión mínima | Descarga |
|----------|---------------|----------|
| Python | 3.12+ | [python.org](https://www.python.org/downloads/) |
| Node.js | 18+ | [nodejs.org](https://nodejs.org/) |
| PostgreSQL | 16 | [postgresql.org](https://www.postgresql.org/download/) |
| Angular CLI | 20+ | `npm install -g @angular/cli` |
| Git | 2.x | [git-scm.com](https://git-scm.com/) |

---

## 🚀 Instalación y Configuración

### 1. Clonar el repositorio

```bash
git clone https://github.com/alecaballero17/emergencias-vehiculares.git
cd emergencias-vehiculares
```

### 2. Configurar la Base de Datos

```sql
-- Desde psql o pgAdmin:
CREATE DATABASE emergencias_vehiculares;
```

### 3. Configurar el Backend

```bash
cd backend

# Crear entorno virtual
python -m venv venv

# Activar entorno virtual
# Windows:
.\venv\Scripts\Activate.ps1
# Linux/Mac:
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt
```

### 4. Configurar variables de entorno

Crear archivo `backend/.env`:

```env
DATABASE_URL=postgresql://postgres:123456@localhost:5432/emergencias_vehiculares
JWT_SECRET_KEY=tu_clave_secreta_jwt
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
OPENAI_API_KEY=sk-tu-clave-de-openai
FIREBASE_CREDENTIALS_PATH=path/to/firebase-credentials.json
UPLOAD_DIR=uploads
MAX_UPLOAD_SIZE=10485760
COMMISSION_RATE=0.10
```

### 5. Ejecutar migraciones y datos de prueba

```bash
# Aplicar migraciones
alembic upgrade head

# Cargar datos de prueba
python -m app.seed
```

### 6. Configurar el Frontend Web

```bash
cd ../frontend-web

# Instalar dependencias
npm install
```

---

## ▶️ Ejecución

### Backend (API)

```bash
cd backend
.\venv\Scripts\Activate.ps1
uvicorn app.main:app --reload --port 8000
```

📍 API disponible en: **http://localhost:8000**
📍 Documentación Swagger: **http://localhost:8000/docs**

### Frontend Web (Talleres)

```bash
cd frontend-web
ng serve
```

📍 Aplicación disponible en: **http://localhost:4200**

---

## 📡 API Endpoints

### Autenticación
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/auth/register` | Registro de usuario |
| POST | `/api/auth/login` | Inicio de sesión (retorna JWT) |

### Usuarios
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/users/me` | Perfil del usuario autenticado |
| PUT | `/api/users/me` | Actualizar perfil |

### Vehículos
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/vehicles` | Listar vehículos del usuario |
| POST | `/api/vehicles` | Registrar vehículo |
| PUT | `/api/vehicles/{id}` | Editar vehículo |
| DELETE | `/api/vehicles/{id}` | Eliminar vehículo |

### Incidentes
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/incidents` | Crear reporte de emergencia |
| GET | `/api/incidents/{id}` | Detalle del incidente |
| POST | `/api/incidents/{id}/evidence` | Subir evidencia (foto/audio) |
| PUT | `/api/incidents/{id}/cancel` | Cancelar solicitud |

### Talleres
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/workshops/profile` | Perfil del taller |
| GET | `/api/workshops/incidents/available` | Incidentes disponibles |
| GET | `/api/workshops/incidents/assigned` | Incidentes asignados |
| PUT | `/api/workshops/incidents/{id}/accept` | Aceptar solicitud |
| PUT | `/api/workshops/incidents/{id}/reject` | Rechazar solicitud |
| PUT | `/api/workshops/incidents/{id}/complete` | Completar servicio |
| GET | `/api/workshops/technicians` | Listar técnicos |
| POST | `/api/workshops/technicians` | Registrar técnico |

### Pagos
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/payments` | Registrar pago |
| GET | `/api/payments/{incident_id}` | Consultar pago |

### Notificaciones
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/notifications` | Listar notificaciones |
| PUT | `/api/notifications/{id}/read` | Marcar como leída |

---

## 🔐 Credenciales de Prueba

### Clientes (App Móvil)

| Email | Contraseña |
|-------|-----------|
| carlos@example.com | password123 |
| maria@example.com | password123 |

### Administradores de Taller (Web)

| Taller | Email | Contraseña |
|--------|-------|-----------|
| Taller El Rápido | elrapido@example.com | taller123 |
| Taller López | lopez@example.com | taller123 |
| Servicio Premium | premium@example.com | taller123 |

---

## 📊 Modelos de Datos

El sistema cuenta con **10 modelos** y **7 enumeraciones**:

| Modelo | Descripción |
|--------|-------------|
| User | Usuarios (clientes y administradores de taller) |
| Vehicle | Vehículos registrados por los clientes |
| Workshop | Talleres mecánicos con ubicación y especialidades |
| Technician | Técnicos asociados a cada taller |
| Incident | Emergencias reportadas con información de IA |
| Evidence | Evidencia multimedia (imágenes, audio) |
| Payment | Pagos con comisión de plataforma |
| Notification | Notificaciones push y en app |
| ServiceHistory | Historial de acciones por incidente |

**Tipos de incidente:** Llanta ponchada, Falla de motor, Batería descargada, Accidente, Bloqueo de llaves, Combustible vacío, Sobrecalentamiento, Otro.

**Estados:** Pendiente → Asignado → En Progreso → Completado / Cancelado.

---

## 👥 Autores

| Nombre | GitHub | Rol |
|--------|--------|-----|
| Ale Caballero | [@alecaballero17](https://github.com/alecaballero17) | Desarrollador |

---

## 📄 Licencia

Este proyecto fue desarrollado como proyecto académico universitario.

---

<p align="center">
  Desarrollado con ❤️ usando FastAPI, Angular y Flutter
</p>
