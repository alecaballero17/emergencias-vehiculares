<p align="center">
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/Angular_18-DD0031?style=for-the-badge&logo=angular&logoColor=white" alt="Angular"/>
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
- [Nuevas Características (Fase 2)](#-nuevas-características-fase-2)
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
│    📱 Flutter App     │      │   🖥️ Angular 18 Web   │
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
| **Backend** | FastAPI + Uvicorn (Python 3.12) | API REST, arquitectura Multi-tenant SaaS |
| **ORM** | SQLAlchemy 2.x + Alembic | Mapeo de datos y migraciones con tenant_id |
| **Base de Datos** | PostgreSQL 16 | Persistencia relacional aislada por tenant |
| **Frontend Web** | Angular 18 (PWA + Service Worker) | Dashboard de talleres, instalable y con caché offline |
| **App Móvil** | Flutter 3.x (Dart + Hive) | App de cliente con soporte Offline y base de datos Hive |
| **IA Multimodal** | Google Gemini 1.5 Flash | Diagnóstico multimodal, IA en español y estimador de costos en Bs. |
| **Geocodificación** | Nominatim (OpenStreetMap) | Dirección legible desde coordenadas |
| **Notificaciones** | flutter_local_notifications | Notificaciones instantáneas y vibración en-app |
| **Sincronización** | WebSockets (Bidireccional) | Tracking en vivo y transiciones de estado en tiempo real |
| **Autenticación** | JWT (HS256) + bcrypt | Autenticación robusta con tenant_id embebido en el token |
| **Estilos** | SCSS + Google Fonts (Inter) | UI premium con dark theme (Glassmorphism) |

---

## 🧠 Módulos de Inteligencia Artificial

### Procesamiento Multimodal (Gemini 1.5 Flash)

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

## 🚀 Nuevas Características (Fase 2)

#### 🏢 Arquitectura Multi-tenant SaaS
La plataforma ha evolucionado a un modelo SaaS multi-inquilino.
* **Aislamiento a Nivel de Base de Datos:** Todas las tablas principales cuentan con un campo `tenant_id` indexado. Las consultas y escrituras se filtran estrictamente a nivel de base de datos para evitar fugas de información entre inquilinos.
* **Detección de Inquilinos:** El backend detecta el inquilino a través del token JWT (que incluye el `tenant_id` en su payload) o mediante el encabezado HTTP `X-Tenant-ID`.
* **Registro Dinámico:** En la app móvil, el usuario puede seleccionar dinámicamente su red/inquilino al registrarse, consultando la lista de tenants activos en `/api/tenants/`.

#### 🤖 Estimador de Costos con IA en Bolivianos (Bs.)
Se incorporó el endpoint `POST /api/ai/estimate-cost` que utiliza **Google Gemini 1.5 Flash** para proporcionar una estimación de precios realista para el contexto boliviano.
* **Contexto Local:** La IA calcula costos mínimos y máximos en Bolivianos (Bs.) para servicios en el departamento de Santa Cruz de la Sierra.
* **Entrada de Datos:** Analiza el tipo de incidente, severidad, descripción textual y factores de mercado.
* **Formato Estructurado:** Retorna un JSON con `min_cost` y `max_cost` listos para ser mostrados como referencia en la cotización.

#### ⚙️ Máquina de 7 Estados y Política de Cancelación
Se implementó un flujo riguroso para la gestión del ciclo de vida del incidente:
1. `pending` (Pendiente): Incidente registrado, esperando ofertas.
2. `searching` (Buscando taller): Taller analizando/enviando cotizaciones.
3. `assigned` (Taller asignado): Cliente acepta una oferta; se cancelan las demás y se asigna el técnico.
4. `en_route` (En camino): El técnico inicia su traslado al punto del cliente.
5. `attending` (En atención): El técnico ha llegado al lugar y está trabajando.
6. `completed` (Finalizado): Servicio culminado, cobro registrado y procesado.
7. `cancelled` (Cancelado): Reporte suspendido.
* **Tarifa de Cancelación:** Si el cliente cancela un incidente después de que ya ha sido asignado un taller (`assigned`, `en_route` o `attending`), el sistema aplica automáticamente una **tarifa de penalización fija de Bs. 50**, la cual se registra en el modelo de pagos y se descuenta/acumula en el historial de deudas del cliente.

#### 📡 Sincronización Offline con Hive (App Móvil)
Soporte de resiliencia de red avanzado:
* **Persistencia Local:** Los vehículos registrados, reportes de incidentes activos e histórico de emergencias se almacenan localmente en cajas de **Hive** en el celular.
* **Cola de Sincronización:** Si el usuario no tiene conexión de red al presionar el botón de pánico SOS, la app almacena el incidente localmente generando un `local_uuid` temporal.
* **Sincronización en Segundo Plano:** Mediante un servicio de monitoreo de conectividad, en cuanto se recupera el acceso a Internet, los incidentes pendientes en la cola local se envían al backend de forma segura y se reemplazan localmente con la respuesta oficial del servidor.

#### 📍 Tracking en Vivo vía WebSockets
* **Comunicación en Tiempo Real:** Canal WebSocket bidireccional en `/api/incidents/{incident_id}/track`.
* **Intercambio de Ubicación:** Transmite de forma fluida las coordenadas geográficas del mecánico (latitud/longitud) hacia la app del conductor en tiempo real.
* **Simulación de Ruta:** Movimiento interactivo del técnico con estimaciones dinámicas de distancia, tiempo de llegada (ETA) y visualización del avance del estado del servicio.

#### 📊 PWA & Panel de Analíticas con Mapa de Calor (Angular)
El panel web de administración de talleres se transformó en una Aplicación Web Progresiva instalable y se le agregaron capacidades analíticas robustas:
* **Instalabilidad PWA:** Soporte completo de Service Worker y manifiesto con logos optimizados (`icon-192.png`, `icon-512.png`), permitiendo la instalación en escritorio o móviles y caché offline del shell de la aplicación.
* **Mapa de Calor (Heatmap Leaflet):** Integración dinámica de Leaflet y Leaflet.heat (vía CDN) para representar geográficamente la densidad y puntos calientes de los incidentes viales.
* **Métricas Clave (KPIs):** Tasa de cumplimiento de acuerdos de nivel de servicio (SLA), tiempo promedio de llegada, tiempo promedio de asignación, costo acumulado de comisiones y análisis del total de cancelaciones.

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
├── 📂 frontend-web/                 # Panel Web - Angular 18
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
| Angular CLI | 18+ | `npm install -g @angular/cli` |
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
| 🌐 API (Nube) | https://emergencias-api.onrender.com |
| 📖 Swagger (Docs) | https://emergencias-api.onrender.com/docs |
| 🔀 ReDoc | https://emergencias-api.onrender.com/redoc |

### Terminal 2 — Panel Web (Talleres)

```bash
cd frontend-web
npm start
```

| Recurso | URL |
|---------|-----|
| 🖥️ Dashboard de Talleres | https://emergencias-web.onrender.com |

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

### 🔐 Autenticación y Tenants
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET`  | `/api/tenants/` | Listar todas las redes de talleres activas (Público) |
| `POST` | `/api/auth/register/user` | Registro de nuevo cliente con `tenant_id` |
| `POST` | `/api/auth/register/workshop` | Registro de nuevo taller con `tenant_id` |
| `POST` | `/api/auth/login` | Inicio de sesión → JWT Token con `tenant_id` |

### 👤 Usuarios
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/users/me` | Obtener perfil autenticado (filtrado por tenant) |
| `PUT` | `/api/users/me` | Actualizar perfil |

### 🚙 Vehículos
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/vehicles/` | Listar vehículos del usuario |
| `POST` | `/api/vehicles/` | Registrar nuevo vehículo con `tenant_id` |
| `PUT` | `/api/vehicles/{id}` | Editar vehículo |
| `DELETE` | `/api/vehicles/{id}` | Eliminar vehículo |

### 🆘 Incidentes (Emergencias)
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/api/incidents/` | Reportar emergencia (foto + audio + GPS + `local_uuid` offline) |
| `GET` | `/api/incidents/` | Listar incidentes del usuario |
| `GET` | `/api/incidents/{id}` | Detalle completo con evidencias y cotizaciones |
| `PUT` | `/api/incidents/{id}/cancel` | Cancelar emergencia (calcula recargo de Bs. 50 si aplica) |

### 🔧 Cotizaciones (Ofertas de Talleres)
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/api/quotations/{incident_id}` | Taller envía cotización (monto + tiempo estimado) |
| `GET`  | `/api/quotations/{incident_id}` | Cliente visualiza ofertas recibidas |
| `PUT`  | `/api/quotations/{quotation_id}/accept` | Cliente acepta oferta (auto-rechaza las demás, asigna taller) |

### 🔧 Talleres
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/workshops/profile` | Perfil del taller autenticado |
| `PUT` | `/api/workshops/profile` | Actualizar perfil |
| `GET` | `/api/workshops/incidents/available` | Incidentes disponibles en zona filtrados por especialidad |
| `GET` | `/api/workshops/incidents/assigned` | Incidentes asignados al taller |
| `PUT` | `/api/workshops/incidents/{id}/accept` | Aceptar incidente + asignar técnico |
| `PUT` | `/api/workshops/incidents/{id}/reject` | Rechazar y devolver a búsqueda general |
| `PUT` | `/api/workshops/incidents/{id}/arrive` | Reportar llegada del técnico a la ubicación (Atención) |
| `PUT` | `/api/workshops/incidents/{id}/complete` | Completar servicio + registrar costo final |
| `GET` | `/api/workshops/technicians` | Listar técnicos del taller |
| `POST` | `/api/workshops/technicians` | Registrar técnico |

### 💳 Pagos
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/api/payments/{incident_id}` | Registrar intención de pago o pago directo alternativo |
| `POST` | `/api/payments/{incident_id}/confirm` | Confirmar pago simulando pasarela Paralela |

### 📊 KPIs y Analíticas
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET`  | `/api/analytics/summary` | Totales y tasa de finalización |
| `GET`  | `/api/analytics/assignment-time` | Tiempo promedio de asignación |
| `GET`  | `/api/analytics/arrival-time` | Tiempo promedio de llegada |
| `GET`  | `/api/analytics/incidents-by-type` | Distribución por tipo de incidente |
| `GET`  | `/api/analytics/top-workshops` | Talleres eficientes y tasas de éxito |
| `GET`  | `/api/analytics/incident-heatmap` | Geolocalizaciones críticas para mapa de calor |
| `GET`  | `/api/analytics/cancelled-cases` | Detalle e importes de cancelaciones |
| `GET`  | `/api/analytics/sla-compliance` | % de cumplimiento de tiempos estimados (SLA) |

### 🤖 Inteligencia Artificial
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/api/ai/estimate-cost` | Estimar costos en bolivianos (Bs.) con Gemini Flash |

### 🔔 Notificaciones
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/notifications/` | Listar notificaciones del usuario |
| `PUT` | `/api/notifications/{id}/read` | Marcar como leída |

---

## 🔐 Credenciales de Prueba (Multi-tenant)

### 📱 Clientes (App Móvil)

| Tenant | Cliente | Email | Contraseña |
|--------|---------|-------|------------|
| **Auxilio Norte (T1)** | Juan Pérez | `juan@demo.com` | `123456` |
| **Auxilio Norte (T1)** | María García | `maria@demo.com` | `123456` |
| **Mecánicos Express (T2)** | Ana Rodríguez | `ana@demo.com` | `123456` |

### 🖥️ Talleres (Panel Web)

| Tenant | Taller | Email | Contraseña |
|--------|--------|-------|------------|
| **Auxilio Norte (T1)** | Taller Automotriz Central | `taller1@demo.com` | `123456` |
| **Auxilio Norte (T1)** | Mecánica Rápida Sur | `taller2@demo.com` | `123456` |
| **Mecánicos Express (T2)** | Express Mecánica | `express1@demo.com` | `123456` |

---

## 📊 Modelos de Datos (Evolución Fase 2)

El sistema cuenta con **11 modelos** y **8 enumeraciones**:

| Modelo | Descripción | Relaciones |
|--------|-------------|------------|
| `Tenant` | Redes de talleres aisladas SaaS | → Users, Workshops, Incidents |
| `User` | Clientes vinculados a un tenant | → Vehículos, Incidentes |
| `Vehicle` | Vehículos del cliente | → Incidentes |
| `Workshop` | Talleres mecánicos del tenant con ubicación y especialidades | → Técnicos, Incidentes |
| `Technician` | Técnicos asignados del taller | → Taller |
| `Quotation` | Ofertas económicas enviadas a incidentes | → Taller, Incidente |
| `Incident` | Emergencias con diagnóstico IA, timestamps y recargos | → Usuario, Vehículo, Taller, Evidencias, Pago, Quotations |
| `Evidence` | Evidencia multimedia (imágenes, audio, texto) | → Incidente |
| `Payment` | Pagos directos o via pasarela Paralela con comisiones | → Incidente |
| `Notification` | Notificaciones push, en-app y WebSocket | → Usuario/Taller |
| `ServiceHistory` | Historial de cambios de estado detallados | → Incidente |

### Tipos de Incidente

| Tipo | Emoji | Descripción |
|------|-------|-------------|
| `battery` | 🔋 | Batería descargada / Problemas eléctricos |
| `tire` | 🛞 | Pinchazo / Llanta dañada |
| `crash` | 💥 | Accidente / Colisión vehicular |
| `engine` | 🔧 | Falla de motor / Sobrecalentamiento |
| `other` | ❓ | Otro problema (p. ej. pérdida de llaves) |

### Flujo y Máquina de 7 Estados

```
pendiente ──▶ buscando_taller ──▶ taller_asignado ──▶ en_camino ──▶ en_atencion ──▶ finalizado
   │                 │                  │               │               │
   └─────────────────┴──────────────────┴───────────────┴───────────────┴──────▶ cancelado
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
