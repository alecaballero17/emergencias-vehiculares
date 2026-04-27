# Reporte de Auditoría Técnica: Plataforma de Emergencias Vehiculares

**Fecha:** 26 de abril de 2026  
**Auditor:** Antigravity (Senior Software Engineer)  
**Proyecto:** Emergencias Vehiculares Inteligentes  
**Objetivo:** Validación técnica para defensa académica.

---

## 1. BACKEND (FastAPI)

El sistema utiliza una arquitectura modular basada en **FastAPI**, organizada en routers para la gestión de recursos y servicios para la lógica de negocio.

### Lista de Endpoints

| Módulo | Método | Ruta | Descripción |
| :--- | :--- | :--- | :--- |
| **Autenticación** | `POST` | `/api/auth/register/user` | Registro de clientes. |
| | `POST` | `/api/auth/register/workshop` | Registro de talleres mecánicos. |
| | `POST` | `/api/auth/login` | Inicio de sesión unificado (JWT). |
| **Usuarios** | `GET` | `/api/users/me` | Obtener perfil del usuario actual. |
| **Vehículos** | `POST` | `/api/vehicles/` | Registrar un nuevo vehículo. |
| | `GET` | `/api/vehicles/` | Listar vehículos del usuario. |
| **Incidentes** | `POST` | `/api/incidents/` | **Reportar emergencia (Multimodal: Audio, Imagen, Texto).** |
| | `GET` | `/api/incidents/` | Historial de incidentes del usuario. |
| | `GET` | `/api/incidents/{id}` | Detalle completo de un incidente. |
| **Talleres** | `GET` | `/api/workshops/me` | Perfil del taller. |
| | `GET` | `/api/workshops/incidents` | Ver solicitudes asignadas al taller. |
| | `PUT` | `/api/workshops/incidents/{id}/accept` | Aceptar incidente y asignar técnico. |
| | `PUT` | `/api/workshops/incidents/{id}/complete` | Marcar servicio como finalizado. |
| **Pagos** | `POST` | `/api/payments/{incident_id}` | Registrar pago y calcular comisión. |
| **Notificaciones**| `GET` | `/api/notifications/user` | Listar notificaciones del cliente. |

### Ubicación de la Lógica Core
- **IA (Procesamiento):** `app/ai/multimodal_processor.py` y `app/ai/incident_classifier.py`.
- **Asignación:** `app/services/assignment_service.py`.
- **Notificaciones:** `app/services/notification_service.py`.
- **Pagos:** `app/routers/payments.py`.

---

## 2. BASE DE DATOS

El sistema utiliza **PostgreSQL** (vía SQLAlchemy) con un esquema relacional normalizado.

### Tablas Reales e Implementación
- `users`: Almacena clientes y administradores con roles.
- `workshops`: Talleres registrados con geolocalización y especialidades.
- `vehicles`: Vehículos asociados a usuarios para contexto en la emergencia.
- `incidents`: Tabla central. Almacena ubicación, clasificación IA (tipo, prioridad), y estados.
- `evidences`: Enlaces a archivos (imágenes/audio) subidos al servidor.
- `payments`: Registro de transacciones, montos y comisiones de plataforma.
- `notifications`: Almacén de alertas para usuarios y talleres.
- `technicians`: Personal técnico de cada taller.
- `service_history`: Log de auditoría de cada cambio de estado del incidente.

**Validación:** El modelo coincide con el diseño teórico, implementando relaciones 1:N (Usuario-Incidentes) y 1:1 (Incidente-Pago) de manera robusta.

---

## 3. IA (SISTEMA MULTIMODAL)

El componente de IA es el corazón del sistema, utilizando **Google Gemini Flash 2.0** para análisis en tiempo real.

### Procesamiento por Modalidad
1. **Texto:** Analiza la descripción del usuario y el contexto del vehículo (marca/modelo).
2. **Audio:** Se recibe en formato `.webm`/`.m4a`, se envía como *inline bytes* a Gemini. La IA realiza la transcripción y extrae el sentimiento de urgencia.
3. **Imágenes:** Procesa múltiples fotografías simultáneamente para identificar daños visuales (choques, llantas desinfladas, humo).

### Votación Ponderada (Weighted Voting)
El sistema implementa una lógica de decisión basada en pesos cuando se requiere mayor granularidad o como fallback:
- **Prioridad Visual:** Si el audio contradice a la imagen, el sistema otorga mayor peso a la evidencia visual (0.35 vs 0.30).
- **Cálculo de Confianza:** Se promedia la confianza de cada modalidad para emitir un veredicto final.

**Ejemplo de Código (`app/ai/multimodal_processor.py`):**
```python
prompt = """
Cruza la información: si el audio dice algo pero las fotos muestran otra cosa, 
prioriza la evidencia visual. Identifica: choque, pinchazo, motor, etc.
"""
# Gemini procesa Audio + Imágenes + Texto en un solo tensor de contexto.
```

---

## 4. ASIGNACIÓN INTELIGENTE

El sistema no elige el taller al azar; utiliza un **Algoritmo de Scoring Multicriterio**.

### Criterios de Selección (Pesos)
- **Distancia (35%):** Calculada con la fórmula de **Haversine** (distancia en círculo máximo sobre la Tierra).
- **Especialidad (25%):** Match entre el tipo de incidente detectado por IA y las especialidades del taller.
- **Disponibilidad (20%):** Técnicos libres en ese momento.
- **Capacidad y Carga (20%):** Cantidad de incidentes activos para evitar saturación.

**Lógica de Distancia (`app/utils/geolocation.py`):**
```python
def haversine_distance(lat1, lon1, lat2, lon2):
    # Implementación matemática para precisión GPS en KM
    ...
```

---

## 5. NOTIFICACIONES

### Flujo Firebase (FCM)
1. **Evento:** Se crea un incidente o cambia su estado (ej. "Taller en camino").
2. **Persistencia:** Se guarda en la tabla `notifications`.
3. **Despacho:** Si el usuario tiene un `firebase_token` registrado, el servicio `notification_service.py` envía un mensaje push vía `firebase_admin`.

---

## 6. PAGOS Y COMISIONES

### Registro y Cálculo
- El pago se activa cuando el incidente pasa a estado `COMPLETED`.
- **Comisión:** El sistema calcula automáticamente el porcentaje de la plataforma (ej. 10%) antes de registrar el pago.
- **Estados:** `PENDING` -> `COMPLETED` -> `REFUNDED`.

---

## 7. FLUJO COMPLETO DEL SISTEMA (End-to-End)

1. **Cliente:** Reporta emergencia enviando audio de un motor fallando y una foto del capó abierto.
2. **IA:** Gemini analiza el audio ("ruido metálico") y la foto ("humo"), clasifica como `ENGINE_FAILURE` con prioridad `HIGH`.
3. **Asignación:** El sistema busca talleres a < 50km con especialidad en "Motor", selecciona al de mejor score.
4. **Taller:** Recibe notificación push, acepta y asigna un técnico. El cliente ve el ETA en el mapa.
5. **Finalización:** El técnico repara, el taller marca como completado y define el costo final.
6. **Pago:** El cliente paga desde la app; el sistema registra la transacción y deduce la comisión.

---

## 8. ESTRUCTURA DEL PROYECTO

```text
backend/
├── app/
│   ├── ai/          # Lógica de Gemini y clasificadores
│   ├── models/      # Definición de tablas (SQLAlchemy)
│   ├── routers/     # Endpoints de la API
│   ├── services/    # Lógica de negocio (Asignación, Incidentes)
│   ├── utils/       # Seguridad, Geolocalización
│   └── main.py      # Punto de entrada FastAPI
docs/                # Diagramas y documentación técnica
frontend-web/        # Panel administrativo para talleres y admin
mobile_app/          # Aplicación Flutter para clientes
```

### Arquitectura General
El sistema sigue una arquitectura **Layered Architecture (N-Tier)**:
- **Presentation Layer:** FastAPI Routers.
- **Service Layer:** Business logic uncoupled from the API.
- **Data Access Layer:** SQLAlchemy Models.
- **AI Engine:** External integration with Google Generative AI.

---
**Reporte generado exitosamente para validación académica.**
