<p align="center">
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/Angular_20-DD0031?style=for-the-badge&logo=angular&logoColor=white" alt="Angular"/>
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/PostgreSQL_16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/Google_Gemini-8E75B2?style=for-the-badge&logo=googlegemini&logoColor=white" alt="Gemini"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
</p>

<h1 align="center">🚗 Plataforma Inteligente de Atención de Emergencias Vehiculares</h1>

<p align="center">
  <strong>Sistema multiplataforma con IA que conecta conductores con emergencias mecánicas a talleres especializados cercanos, en tiempo real.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/versión-1.0.0-blue?style=flat-square" alt="Versión"/>
  <img src="https://img.shields.io/badge/estado-Producción-success?style=flat-square" alt="Estado"/>
  <img src="https://img.shields.io/badge/licencia-Académico-orange?style=flat-square" alt="Licencia"/>
</p>

---

## 📋 Tabla de Contenidos

- [Descripción del Problema](#-descripción-del-problema)
- [Flujo del Sistema](#-flujo-del-sistema)
- [Arquitectura](#-arquitectura)
- [Tecnologías](#-tecnologías)
- [Módulos de IA](#-módulos-de-inteligencia-artificial)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación y Configuración](#-instalación-y-configuración)
- [Ejecución](#-ejecución)
- [API Endpoints](#-api-endpoints)
- [Credenciales de Prueba](#-credenciales-de-prueba)
- [Modelos de Datos](#-modelos-de-datos)
- [Autores](#-autores)

---

## 📖 Descripción del Problema

En entornos urbanos y carreteras, los conductores frecuentemente enfrentan situaciones imprevistas como fallas mecánicas, pinchazos de llanta, problemas de batería, sobrecalentamiento del motor o accidentes leves. El proceso actual de conseguir ayuda es **ineficiente, lento y poco confiable**.

### Problemas que resuelve

| Para el Conductor | Para el Taller |
|---|---|
| ❌ Dependencia de llamadas telefónicas | ❌ Sin plataforma para recibir solicitudes |
| ❌ Falta de información clara sobre el problema | ❌ Dificultad para evaluar la naturaleza del problema |
| ❌ Tiempos de respuesta impredecibles | ❌ No puede priorizar casos urgentes |
| ❌ Dificultad para encontrar el taller adecuado | ❌ Sin trazabilidad del servicio |
| ❌ Ausencia de seguimiento en tiempo real | ❌ Sin sistema de cobro integrado |

### Nuestra Solución

Una plataforma inteligente que utiliza **Inteligencia Artificial (Google Gemini)** para analizar automáticamente la emergencia del conductor a partir de fotos, audio y ubicación GPS, clasificar el tipo de incidente y su prioridad, y asignar el taller más adecuado considerando distancia, especialidad y disponibilidad.

---

## 🔄 Flujo del Sistema

```
  📱 CLIENTE (App Móvil)                    🖥️ TALLER (Panel Web)

  ┌─────────────────────┐
  │ 1. Reporta emergencia│
  │    📸 Foto + 🎤 Audio│
  │    📍 GPS automático │
  │    📝 Descripción    │
  └──────────┬──────────┘
             │
             ▼
  ┌─────────────────────┐
  │ 2. IA Gemini analiza │
  │    • Transcribe audio│
  │    • Analiza imagen  │
  │    • Clasifica tipo  │
  │    • Asigna prioridad│
  └──────────┬──────────┘
             │
             ▼
  ┌─────────────────────┐         ┌─────────────────────┐
  │ 3. Motor de          │────────▶│ 4. Taller recibe     │
  │    Asignación         │         │    notificación      │
  │    Inteligente        │         │    con diagnóstico IA│
  └──────────────────────┘         └──────────┬──────────┘
                                              │
                                              ▼
  ┌─────────────────────┐         ┌─────────────────────┐
  │ 6. Cliente ve        │◀────────│ 5. Taller acepta,    │
  │    seguimiento y     │         │    asigna técnico,   │
  │    paga desde la app │         │    completa servicio │
  └─────────────────────┘         └─────────────────────┘
```

---

## 🏗 Arquitectura

```
┌──────────────────────┐      ┌──────────────────────┐
│    📱 Flutter App     │      │   🖥️ Angular 20 Web   │
│    (Clientes)         │      │   (Panel de Talleres) │
│                       │      │                       │
│  • Reporte SOS        │      │  • Dashboard          │
│  • Historial          │      │  • Gestión Incidentes │
│  • Pagos              │      │  • Técnicos           │
│  • Seguimiento        │      │  • Finanzas           │
└───────────┬───────────┘      └───────────┬───────────┘
            │         HTTPS + JWT          │
            └──────────────┬───────────────┘
                           │
                ┌──────────▼──────────┐
                │   ⚙️ FastAPI Backend │
                │     Puerto 8000     │
                ├─────────────────────┤
                │  🧠 Motor de IA     │
                │  ├─ Gemini Flash    │
                │  ├─ Análisis Imagen │
                │  ├─ Transcripción   │
                │  ├─ Clasificación   │
                │  └─ Resumen         │
                ├─────────────────────┤
                │  🔧 Servicios       │
                │  ├─ Asignación      │
                │  ├─ Notificaciones  │
                │  ├─ Pagos           │
                │  └─ Geolocalización │
                └──────────┬──────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐  ┌─────▼──────┐  ┌──────▼──────┐
   │ 🗄️ PostgreSQL│  │ 🤖 Google  │  │ 🔔 Firebase │
   │     16       │  │   Gemini   │  │    FCM      │
   │  (10 tablas) │  │  (IA API)  │  │  (Push)     │
   └─────────────┘  └────────────┘  └─────────────┘
```

---

## 🛠 Tecnologías

| Capa | Tecnología | Propósito |
|------|-----------|-----------|
| **Backend** | FastAPI + Uvicorn (Python 3.12) | API REST, lógica de negocio |
| **ORM** | SQLAlchemy 2.x + Alembic | Mapeo de datos y migraciones |
| **Base de Datos** | PostgreSQL 16 | Persistencia relacional |
| **Frontend Web** | Angular 20 (Standalone) | Dashboard de talleres |
| **App Móvil** | Flutter 3.x (Dart) | Aplicación del cliente |
| **IA Multimodal** | Google Gemini 2.5 Flash | Análisis de imagen, audio y texto |
| **Geocodificación** | Nominatim (OpenStreetMap) | Dirección legible desde coordenadas |
| **Notificaciones** | flutter_local_notifications + FCM | Notificaciones push nativas con vibración y sonido |
| **Sincronización** | Polling Asíncrono (Timer) | Sincronización en tiempo real cada 3-5s sin WebSockets |
| **Autenticación** | JWT (HS256) + bcrypt | Tokens con expiración 24h |
| **Estilos** | SCSS + Google Fonts (Inter) | UI premium con dark theme (Glassmorphism) |

---

## 🧠 Módulos de Inteligencia Artificial

### Procesamiento Multimodal (Gemini 2.5 Flash)

El sistema utiliza **Google Gemini** como motor de IA unificado para procesar múltiples tipos de evidencia en una sola llamada:

| Capacidad | Descripción |
|-----------|-------------|
| 🎤 **Transcripción de Audio** | Convierte grabaciones de voz del conductor a texto |
| 📸 **Análisis de Imágenes** | Identifica daños, componentes afectados y severidad |
| 🧾 **Generación de Ficha** | Produce un reporte estructurado: Situación, Diagnóstico, Recomendación |

### Clasificación Inteligente por Votación Ponderada

El sistema combina las tres fuentes de información para determinar el tipo de incidente:

| Fuente | Peso |
|--------|------|
| 📝 Texto descriptivo | 30% |
| 🎤 Audio transcrito | 35% |
| 📸 Imágenes analizadas | 35% |

**Resultado:** Tipo de incidente (8 categorías), prioridad (Baja/Media/Alta/Crítica) y nivel de confianza (0-100%).

### Motor de Asignación Inteligente

Algoritmo multifactor para encontrar el mejor taller disponible:

| Factor | Peso | Método |
|--------|------|--------|
| 📍 Distancia geográfica | 35% | Fórmula de Haversine |
| 🔧 Especialidad del taller | 25% | Match tipo de incidente |
| 👷 Disponibilidad de técnicos | 20% | Técnicos libres |
| 🏭 Capacidad del taller | 10% | Slots disponibles |
| 📊 Carga de trabajo actual | 10% | Incidentes activos |

> 📍 Radio máximo de búsqueda: **50 km**

---

## 📁 Estructura del Proyecto

```
emergencias-vehiculares/
│
├── 📂 backend/                      # API REST - FastAPI (Python)
│   ├── app/
│   │   ├── main.py                  # Punto de entrada + CORS
│   │   ├── config.py                # Variables de entorno
│   │   ├── database.py              # Conexión PostgreSQL
│   │   ├── seed.py                  # Datos de prueba
│   │   ├── ai/                      # 🧠 Módulos de IA
│   │   │   ├── multimodal_processor.py   # Procesador Gemini unificado
│   │   │   ├── audio_processor.py        # Transcripción de audio
│   │   │   ├── image_classifier.py       # Análisis de imágenes
│   │   │   ├── incident_classifier.py    # Votación ponderada
│   │   │   └── summary_generator.py      # Generación de fichas
│   │   ├── models/                  # Modelos SQLAlchemy (10 tablas)
│   │   ├── routers/                 # Endpoints API (7 routers)
│   │   │   ├── auth.py              # Registro e inicio de sesión
│   │   │   ├── users.py             # Perfil de usuario
│   │   │   ├── vehicles.py          # CRUD de vehículos
│   │   │   ├── incidents.py         # Gestión de emergencias
│   │   │   ├── workshops.py         # Operaciones de talleres
│   │   │   ├── payments.py          # Sistema de pagos
│   │   │   └── notifications.py     # Notificaciones
│   │   ├── schemas/                 # Validación Pydantic
│   │   ├── services/                # Lógica de negocio
│   │   │   ├── incident_service.py  # Procesamiento de incidentes
│   │   │   ├── assignment_service.py # Asignación inteligente
│   │   │   └── notification_service.py # Notificaciones push
│   │   └── utils/                   # Utilidades
│   │       ├── security.py          # JWT + bcrypt
│   │       └── geocoding.py         # Coordenadas → dirección
│   ├── alembic/                     # Migraciones de BD
│   ├── uploads/                     # Archivos multimedia
│   ├── requirements.txt
│   └── .env                         # Variables de entorno
│
├── 📂 frontend-web/                 # Panel Web - Angular 20
│   ├── src/app/
│   │   ├── guards/                  # AuthGuard (protección de rutas)
│   │   ├── interceptors/            # JWT Interceptor automático
│   │   ├── layout/                  # Sidebar + Navegación
│   │   ├── models/                  # Interfaces TypeScript
│   │   ├── pages/                   # 8 páginas
│   │   │   ├── login/               # Inicio de sesión
│   │   │   ├── dashboard/           # Métricas y estadísticas
│   │   │   ├── available/           # Incidentes disponibles
│   │   │   ├── incidents/           # Mis incidentes
│   │   │   ├── incident-detail/     # Detalle + asignación IA
│   │   │   ├── technicians/         # Gestión de técnicos
│   │   │   ├── notifications/       # Centro de notificaciones
│   │   │   ├── finances/            # Reporte financiero
│   │   │   └── profile/             # Perfil del taller
│   │   └── services/                # Comunicación con API
│   └── src/styles.scss              # Sistema de diseño global
│
├── 📂 mobile_app/                   # App Móvil - Flutter
│   ├── lib/
│   │   ├── main.dart                # Punto de entrada
│   │   ├── core/
│   │   │   ├── app_theme.dart       # Tema dark premium
│   │   │   └── api_constants.dart   # URLs del backend
│   │   ├── screens/
│   │   │   ├── login_screen.dart    # Inicio de sesión
│   │   │   ├── register_screen.dart # Registro de usuario
│   │   │   ├── home_screen.dart     # Pantalla principal + SOS
│   │   │   ├── report_incident_screen.dart  # Reporte con foto/audio/GPS
│   │   │   ├── incident_detail_screen.dart  # Detalle + pagos
│   │   │   ├── incident_history_screen.dart # Historial de reportes
│   │   │   └── vehicles_screen.dart # Gestión de vehículos
│   │   └── services/
│   │       ├── auth_service.dart     # Autenticación
│   │       ├── incident_service.dart # Reportes y pagos
│   │       └── vehicle_service.dart  # CRUD vehículos
│   └── pubspec.yaml                 # Dependencias Flutter
│
├── 📂 docs/                         # Documentación
│   └── diagramas-puds.md            # Diagramas UML
│
└── .gitignore
```

---

## 📌 Requisitos Previos

| Software | Versión Mínima | Descarga |
|----------|---------------|----------|
| Python | 3.12+ | [python.org](https://www.python.org/downloads/) |
| Node.js | 18+ | [nodejs.org](https://nodejs.org/) |
| PostgreSQL | 16+ | [postgresql.org](https://www.postgresql.org/download/) |
| Flutter SDK | 3.x | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Angular CLI | 20+ | `npm install -g @angular/cli` |
| Git | 2.x | [git-scm.com](https://git-scm.com/) |

---

## 🚀 Instalación y Configuración

### 1. Clonar el repositorio

```bash
git clone https://github.com/alecaballero17/emergencias-vehiculares.git
cd emergencias-vehiculares
```

### 2. Crear la Base de Datos

```sql
-- Desde psql o pgAdmin:
CREATE DATABASE emergencias_vehiculares;
```

### 3. Configurar el Backend

```bash
cd backend

# Crear y activar entorno virtual
python -m venv venv

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
# === Base de Datos ===
DATABASE_URL=postgresql://postgres:123456@localhost:5432/emergencias_vehiculares

# === JWT ===
SECRET_KEY=tu-clave-secreta-segura
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# === Google Gemini (IA) ===
GEMINI_API_KEY=tu-api-key-de-gemini

# === Firebase (Notificaciones Push) ===
FIREBASE_CREDENTIALS_PATH=firebase-credentials.json

# === Configuración ===
UPLOAD_DIR=uploads
MAX_IMAGE_SIZE_MB=10
MAX_AUDIO_SIZE_MB=25
PLATFORM_COMMISSION_PERCENT=10.0
```

### 5. Ejecutar migraciones y datos de prueba

```bash
# Aplicar migraciones
alembic upgrade head

# Cargar datos de prueba (talleres, técnicos, usuarios)
python -m app.seed
```

### 6. Configurar el Frontend Web

```bash
cd ../frontend-web
npm install
```

### 7. Configurar la App Móvil

```bash
cd ../mobile_app
flutter pub get
```

---

## ▶️ Ejecución

Abrir **tres terminales** y ejecutar cada componente:

### Terminal 1 — Backend (API + IA)

```bash
cd backend
.\venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

| Recurso | URL |
|---------|-----|
| 🌐 API | http://localhost:8000 |
| 📖 Swagger (Documentación) | http://localhost:8000/docs |
| 🔀 ReDoc | http://localhost:8000/redoc |

### Terminal 2 — Panel Web (Talleres)

```bash
cd frontend-web
npm start
```

| Recurso | URL |
|---------|-----|
| 🖥️ Dashboard de Talleres | http://localhost:4200 |

### Terminal 3 — App Móvil (Clientes)

```bash
cd mobile_app
flutter run -d chrome
```

> 💡 También puedes ejecutar en un emulador Android o dispositivo físico con `flutter run`.

---

## 📱 Despliegue en Dispositivo Físico

Para ejecutar la aplicación móvil en un teléfono físico conectado por USB, el proyecto incluye varias optimizaciones:

### 1. Túnel de Comunicación (ADB Reverse)
Para que el celular físico pueda comunicarse con el backend local (`localhost:8000`), ejecutamos:
```bash
adb reverse tcp:8000 tcp:8000
```
*Esto enruta las peticiones del celular directamente al servidor FastAPI de la computadora.*

### 2. Soporte y Compatibilidad (Android 15+)
- **Core Library Desugaring**: Habilitado en `build.gradle` para soportar APIs modernas de Java en dispositivos antiguos.
- **Permisos Nativos Avanzados**: Solicitud explícita en tiempo de ejecución (Android 13+) para `POST_NOTIFICATIONS`, `VIBRATE`, `ACCESS_FINE_LOCATION`, etc.
- **NDK y AGP**: Fijación de versión NDK a `25.1.8937393` y actualización a Android Gradle Plugin `8.3.2` para resolver conflictos de plugins de Flutter.

---

## 📡 API Endpoints

### 🔐 Autenticación
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/api/auth/register` | Registro de nuevo usuario |
| `POST` | `/api/auth/login` | Inicio de sesión → JWT Token |

### 👤 Usuarios
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/users/me` | Obtener perfil autenticado |
| `PUT` | `/api/users/me` | Actualizar perfil |

### 🚙 Vehículos
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/vehicles/` | Listar vehículos del usuario |
| `POST` | `/api/vehicles/` | Registrar nuevo vehículo |
| `PUT` | `/api/vehicles/{id}` | Editar vehículo |
| `DELETE` | `/api/vehicles/{id}` | Eliminar vehículo |

### 🆘 Incidentes (Emergencias)
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/api/incidents/` | Crear reporte multimedia (foto + audio + GPS) |
| `GET` | `/api/incidents/` | Listar incidentes del usuario |
| `GET` | `/api/incidents/{id}` | Detalle completo con análisis IA |
| `PUT` | `/api/incidents/{id}/cancel` | Cancelar emergencia |

### 🔧 Talleres
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/workshops/profile` | Perfil del taller autenticado |
| `PUT` | `/api/workshops/profile` | Actualizar perfil |
| `GET` | `/api/workshops/incidents/available` | Incidentes disponibles en zona |
| `GET` | `/api/workshops/incidents/assigned` | Incidentes asignados al taller |
| `PUT` | `/api/workshops/incidents/{id}/accept` | Aceptar + asignar técnico |
| `PUT` | `/api/workshops/incidents/{id}/reject` | Rechazar solicitud |
| `PUT` | `/api/workshops/incidents/{id}/complete` | Completar servicio + monto |
| `GET` | `/api/workshops/technicians` | Listar técnicos |
| `POST` | `/api/workshops/technicians` | Registrar técnico |
| `PUT` | `/api/workshops/technicians/{id}` | Actualizar técnico |
| `DELETE` | `/api/workshops/technicians/{id}` | Eliminar técnico |

### 💳 Pagos
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/api/payments/{incident_id}` | Cliente realiza pago (QR/Efectivo/Tarjeta/Transferencia) |
| `GET` | `/api/payments/{incident_id}` | Consultar estado del pago |

### 🔔 Notificaciones
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/notifications/` | Listar notificaciones del usuario |
| `PUT` | `/api/notifications/{id}/read` | Marcar como leída |

---

## 🔐 Credenciales de Prueba

### 📱 Clientes (App Móvil)

| Usuario | Email | Contraseña |
|---------|-------|------------|
| Carlos Mendoza | `carlos@example.com` | `password123` |
| María García | `maria@example.com` | `password123` |

### 🖥️ Talleres (Panel Web)

| Taller | Email | Contraseña |
|--------|-------|------------|
| Taller Mecánico El Rápido | `elrapido@example.com` | `taller123` |
| Taller Mecánico López | `lopez@example.com` | `taller123` |
| Servicio Automotriz Premium | `premium@example.com` | `taller123` |

---

## 📊 Modelos de Datos

El sistema cuenta con **10 modelos** y **7 enumeraciones**:

| Modelo | Descripción | Relaciones |
|--------|-------------|------------|
| `User` | Clientes registrados | → Vehículos, Incidentes |
| `Vehicle` | Vehículos del cliente | → Incidentes |
| `Workshop` | Talleres mecánicos con ubicación y especialidades | → Técnicos, Incidentes |
| `Technician` | Técnicos con especialidades | → Taller |
| `Incident` | Emergencias con análisis IA, prioridad y estado | → Usuario, Vehículo, Taller, Evidencias, Pago |
| `Evidence` | Evidencia multimedia (imágenes, audio, texto) | → Incidente |
| `Payment` | Pagos con comisión y método de pago | → Incidente |
| `Notification` | Notificaciones push y en-app | → Usuario/Taller |
| `ServiceHistory` | Historial de cambios de estado por incidente | → Incidente |

### Tipos de Incidente

| Tipo | Emoji | Descripción |
|------|-------|-------------|
| `tire` | 🛞 | Llanta ponchada |
| `engine` | 🔧 | Falla de motor |
| `battery` | 🔋 | Batería descargada |
| `crash` | 💥 | Accidente/Colisión |
| `keys_lost` | 🔑 | Llave perdida |
| `keys_locked` | 🔐 | Llave dentro del vehículo |
| `overheating` | 🌡️ | Sobrecalentamiento |
| `other` | ❓ | Otro |

### Flujo de Estados

```
PENDIENTE → ASIGNADO → EN PROCESO → COMPLETADO → PAGADO
                                  ↘ CANCELADO
```

---

## 💰 Modelo de Comisión

La plataforma opera con un modelo de comisión del **10%** que se descuenta al taller:

| Concepto | Ejemplo |
|----------|---------|
| Costo del servicio (fijado por el taller) | Bs. 500 |
| **Cliente paga** | **Bs. 500** |
| Comisión plataforma (10%) | - Bs. 50 |
| **Taller recibe** | **Bs. 450** |

> El cliente paga únicamente el monto del servicio. La comisión es transparente y se refleja en el panel financiero del taller.

---

## 👥 Autores

| Nombre | GitHub | Rol |
|--------|--------|-----|
| Ale Caballero | [@alecaballero17](https://github.com/alecaballero17) | Desarrollador Full Stack |

---

## 📄 Licencia

Este proyecto fue desarrollado como **trabajo de grado** para la materia de Sistemas de Información en la Universidad Autónoma Gabriel René Moreno (UAGRM), Santa Cruz de Bolivia.

---

<p align="center">
  <sub>Desarrollado con ❤️ en Santa Cruz, Bolivia — 2026</sub>
</p>
<p align="center">
  <img src="https://img.shields.io/badge/FastAPI-009688?style=flat-square&logo=fastapi&logoColor=white" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/Angular-DD0031?style=flat-square&logo=angular&logoColor=white" alt="Angular"/>
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Gemini-8E75B2?style=flat-square&logo=googlegemini&logoColor=white" alt="Gemini"/>
</p>
