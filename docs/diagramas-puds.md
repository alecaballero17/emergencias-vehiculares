# Diagramas UML - PUDS
# Plataforma Inteligente de Atención de Emergencias Vehiculares

> **Instrucciones**: Cada diagrama está en formato Mermaid. Puedes:
> 1. Copiar el código y pegarlo en [Mermaid Live Editor](https://mermaid.live) para exportar como PNG/SVG
> 2. Pegarlo directamente en documentos que soporten Mermaid (Notion, GitHub, Confluence)
> 3. Usar en Word/Google Docs: exportar como imagen desde mermaid.live y luego insertar

---

## 1. Diagrama de Casos de Uso - Cliente

```mermaid
graph LR
    subgraph Sistema["🚗 Plataforma de Emergencias Vehiculares"]
        UC1["Registrarse"]
        UC2["Iniciar sesión"]
        UC3["Gestionar perfil"]
        UC4["Registrar vehículos"]
        UC5["Editar vehículo"]
        UC6["Eliminar vehículo"]
        UC7["Reportar emergencia"]
        UC7a["Adjuntar fotos"]
        UC7b["Grabar audio"]
        UC7c["Enviar ubicación GPS"]
        UC7d["Describir problema (texto)"]
        UC8["Ver estado del incidente"]
        UC9["Cancelar solicitud"]
        UC10["Realizar pago"]
        UC11["Ver historial de servicios"]
        UC12["Recibir notificaciones push"]
        UC13["Ver resumen IA del incidente"]
    end

    Cliente["👤 Cliente<br/>(App Móvil)"]

    Cliente --- UC1
    Cliente --- UC2
    Cliente --- UC3
    Cliente --- UC4
    Cliente --- UC5
    Cliente --- UC6
    Cliente --- UC7
    Cliente --- UC8
    Cliente --- UC9
    Cliente --- UC10
    Cliente --- UC11
    Cliente --- UC12
    Cliente --- UC13

    UC7 -.->|incluye| UC7a
    UC7 -.->|incluye| UC7b
    UC7 -.->|incluye| UC7c
    UC7 -.->|incluye| UC7d
    UC4 -.->|extiende| UC5
    UC4 -.->|extiende| UC6
```

---

## 2. Diagrama de Casos de Uso - Taller

```mermaid
graph LR
    subgraph Sistema["🔧 Plataforma de Emergencias Vehiculares"]
        UT1["Registrarse como taller"]
        UT2["Iniciar sesión"]
        UT3["Ver incidentes disponibles"]
        UT4["Ver detalle de incidente"]
        UT5["Aceptar solicitud de servicio"]
        UT6["Rechazar solicitud"]
        UT7["Asignar técnico"]
        UT8["Actualizar estado del servicio"]
        UT9["Completar servicio"]
        UT10["Gestionar técnicos"]
        UT10a["Agregar técnico"]
        UT10b["Editar técnico"]
        UT10c["Cambiar disponibilidad"]
        UT11["Ver historial de servicios"]
        UT12["Ver análisis IA"]
        UT13["Recibir notificaciones"]
        UT14["Gestionar perfil del taller"]
        UT15["Ver pagos y comisiones"]
    end

    Taller["🔧 Taller<br/>(Web Angular)"]

    Taller --- UT1
    Taller --- UT2
    Taller --- UT3
    Taller --- UT4
    Taller --- UT5
    Taller --- UT6
    Taller --- UT7
    Taller --- UT8
    Taller --- UT9
    Taller --- UT10
    Taller --- UT11
    Taller --- UT12
    Taller --- UT13
    Taller --- UT14
    Taller --- UT15

    UT10 -.->|incluye| UT10a
    UT10 -.->|incluye| UT10b
    UT10 -.->|incluye| UT10c
    UT5 -.->|incluye| UT7
    UT9 -.->|extiende| UT15
```

---

## 3. Diagrama de Casos de Uso - Sistema/IA

```mermaid
graph LR
    subgraph Sistema["🤖 Módulos Inteligentes del Sistema"]
        US1["Transcribir audio (Whisper)"]
        US2["Extraer keywords del audio"]
        US3["Analizar imágenes (GPT-4o Vision)"]
        US4["Clasificar tipo de incidente"]
        US5["Determinar prioridad"]
        US6["Generar resumen estructurado"]
        US7["Asignación inteligente de taller"]
        US7a["Calcular distancia (Haversine)"]
        US7b["Evaluar especialidad"]
        US7c["Calcular ETA"]
        US8["Enviar notificación push (Firebase)"]
    end

    IA["🤖 Sistema IA<br/>(Automatizado)"]
    OpenAI["☁️ OpenAI API"]
    Firebase["☁️ Firebase"]

    IA --- US1
    IA --- US2
    IA --- US3
    IA --- US4
    IA --- US5
    IA --- US6
    IA --- US7
    IA --- US8

    US1 -.->|usa| OpenAI
    US3 -.->|usa| OpenAI
    US4 -.->|usa| OpenAI
    US6 -.->|usa| OpenAI
    US8 -.->|usa| Firebase

    US7 -.->|incluye| US7a
    US7 -.->|incluye| US7b
    US7 -.->|incluye| US7c

    US4 -.->|"votación ponderada<br/>texto 30% + audio 35% + imagen 35%"| US5
```

---

## 4. Diagrama de Clases - Modelo de Datos

```mermaid
classDiagram
    class User {
        +int id
        +String full_name
        +String email
        +String hashed_password
        +String phone
        +UserRole role
        +String firebase_token
        +DateTime created_at
        +DateTime updated_at
    }

    class Vehicle {
        +int id
        +int owner_id
        +String brand
        +String model
        +int year
        +String color
        +String plate_number
        +String vin
        +DateTime created_at
    }

    class Workshop {
        +int id
        +int admin_id
        +String name
        +String address
        +Float latitude
        +Float longitude
        +String phone
        +String[] specialties
        +int capacity
        +boolean is_active
        +DateTime created_at
    }

    class Technician {
        +int id
        +int workshop_id
        +String full_name
        +String phone
        +String specialty
        +boolean is_available
        +DateTime created_at
    }

    class Incident {
        +int id
        +int user_id
        +int vehicle_id
        +int workshop_id
        +int technician_id
        +IncidentType incident_type
        +IncidentPriority priority
        +IncidentStatus status
        +String description
        +Float latitude
        +Float longitude
        +String address
        +String ai_summary
        +String ai_classification
        +Float ai_confidence
        +String rejection_reason
        +Float estimated_cost
        +Float final_cost
        +DateTime created_at
        +DateTime updated_at
    }

    class Evidence {
        +int id
        +int incident_id
        +EvidenceType evidence_type
        +String file_path
        +String transcription
        +String ai_analysis
        +DateTime created_at
    }

    class Payment {
        +int id
        +int incident_id
        +Float amount
        +Float commission
        +Float workshop_amount
        +PaymentMethod payment_method
        +PaymentStatus status
        +String transaction_id
        +DateTime created_at
    }

    class Notification {
        +int id
        +int user_id
        +int incident_id
        +String title
        +String message
        +boolean is_read
        +DateTime created_at
    }

    class ServiceHistory {
        +int id
        +int incident_id
        +int workshop_id
        +int technician_id
        +String action
        +String details
        +DateTime created_at
    }

    User "1" --> "*" Vehicle : posee
    User "1" --> "*" Incident : reporta
    User "1" --> "*" Notification : recibe
    Workshop "1" --> "*" Technician : emplea
    Workshop "1" --> "*" Incident : atiende
    Workshop "1" --> "1" User : administrado por
    Incident "1" --> "*" Evidence : tiene
    Incident "1" --> "1" Payment : genera
    Incident "1" --> "*" ServiceHistory : registra
    Incident "*" --> "1" Vehicle : involucra
    Incident "*" --> "0..1" Technician : asignado a
    ServiceHistory "*" --> "1" Workshop : realizado por
    ServiceHistory "*" --> "1" Technician : ejecutado por
```

---

## 5. Diagrama de Enumeraciones

```mermaid
classDiagram
    class UserRole {
        <<enumeration>>
        client
        workshop_admin
    }

    class IncidentType {
        <<enumeration>>
        flat_tire
        engine_failure
        battery_dead
        accident
        lockout
        fuel_empty
        overheating
        other
    }

    class IncidentPriority {
        <<enumeration>>
        low
        medium
        high
        critical
    }

    class IncidentStatus {
        <<enumeration>>
        pending
        assigned
        in_progress
        completed
        cancelled
    }

    class EvidenceType {
        <<enumeration>>
        image
        audio
        document
    }

    class PaymentStatus {
        <<enumeration>>
        pending
        processing
        completed
        failed
    }

    class PaymentMethod {
        <<enumeration>>
        cash
        card
        transfer
        mobile_payment
    }
```

---

## 6. Diagrama de Secuencia - Reporte de Emergencia

```mermaid
sequenceDiagram
    actor Cliente as 👤 Cliente (Flutter)
    participant API as 🖥️ FastAPI Backend
    participant Audio as 🎙️ AudioProcessor
    participant Image as 📷 ImageClassifier
    participant Classify as 🧠 IncidentClassifier
    participant Summary as 📋 SummaryGenerator
    participant Assign as 🔍 AssignmentService
    participant DB as 🗄️ PostgreSQL
    participant Notif as 🔔 NotificationService

    Cliente->>API: POST /incidents (description, GPS, vehicle_id)
    API->>DB: Crear incidente (status: PENDING)

    Cliente->>API: POST /incidents/{id}/evidence (fotos)
    API->>DB: Guardar evidencia tipo IMAGE

    Cliente->>API: POST /incidents/{id}/evidence (audio)
    API->>DB: Guardar evidencia tipo AUDIO

    Note over API: Procesamiento IA en paralelo

    API->>Audio: process_audio(archivo.wav)
    Audio->>Audio: OpenAI Whisper → Transcripción
    Audio->>Audio: GPT-4o-mini → Análisis y keywords
    Audio-->>API: {transcription, keywords, incident_type, severity}

    API->>Image: classify_image(foto.jpg)
    Image->>Image: GPT-4o Vision → Análisis visual
    Image-->>API: {description, incident_type, severity, details}

    API->>Classify: classify(text_data, audio_data, image_data)
    Classify->>Classify: Votación ponderada (texto 30%, audio 35%, imagen 35%)
    Classify-->>API: {incident_type, priority, confidence}

    API->>Summary: generate_summary(all_data)
    Summary-->>API: Resumen estructurado

    API->>DB: Actualizar incidente con resultados IA

    API->>Assign: find_best_workshop(incident)
    Assign->>DB: Buscar talleres activos en radio 50km
    Assign->>Assign: Puntuación multifactor por taller
    Note over Assign: Distancia 35% + Especialidad 25%<br/>Disponibilidad 20% + Capacidad 10%<br/>Carga trabajo 10%
    Assign->>Assign: Seleccionar mejor técnico disponible
    Assign-->>API: {workshop_id, technician_id, score, eta}

    API->>DB: Asignar taller y técnico (status: ASSIGNED)

    API->>Notif: Notificar taller asignado
    API->>Notif: Notificar cliente con ETA
    Notif->>DB: Guardar notificaciones
    Notif-->>Cliente: 🔔 Push: Taller asignado, ETA X min
```

---

## 7. Diagrama de Secuencia - Taller Aceptar/Rechazar/Completar

```mermaid
sequenceDiagram
    actor Taller as 🔧 Taller (Angular)
    participant API as 🖥️ FastAPI Backend
    participant DB as 🗄️ PostgreSQL
    participant Notif as 🔔 Notificaciones
    actor Cliente as 👤 Cliente (Flutter)

    Note over Taller: Ve incidente asignado en Dashboard

    Taller->>API: GET /workshops/incidents/{id}
    API->>DB: Consultar detalle incidente
    API-->>Taller: Detalle + IA + Evidencias + Historial

    alt Aceptar Solicitud
        Taller->>API: PUT /workshops/incidents/{id}/accept {technician_id}
        API->>DB: Status: ASSIGNED → IN_PROGRESS
        API->>DB: Registrar en ServiceHistory
        API->>Notif: Notificar al cliente
        Notif->>Cliente: 🔔 Push: Servicio en camino
        API-->>Taller: Confirmación

        Note over Taller: Técnico llega y realiza servicio

        Taller->>API: PUT /workshops/incidents/{id}/complete {final_cost, notes}
        API->>DB: Status: IN_PROGRESS → COMPLETED
        API->>DB: Registrar costo final
        API->>Notif: Notificar al cliente
        Notif->>Cliente: 🔔 Push: Servicio completado

        Cliente->>API: POST /payments/{incident_id} {amount, method}
        API->>DB: Crear pago con comisión 10%
        API-->>Cliente: Confirmación de pago

    else Rechazar Solicitud
        Taller->>API: PUT /workshops/incidents/{id}/reject {reason}
        API->>DB: Status: ASSIGNED → PENDING
        API->>DB: Quitar asignación taller/técnico
        API-->>Taller: Confirmación
        Note over API: Incidente vuelve a estar disponible
    end
```

---

## 8. Diagrama de Secuencia - Autenticación JWT

```mermaid
sequenceDiagram
    actor User as 👤 Usuario
    participant App as 📱 App (Flutter/Angular)
    participant API as 🖥️ FastAPI Backend
    participant Auth as 🔐 Security (JWT+bcrypt)
    participant DB as 🗄️ PostgreSQL

    Note over User,DB: REGISTRO DE USUARIO
    User->>App: Ingresa datos de registro
    App->>API: POST /auth/register {name, email, password, role, phone}
    API->>Auth: hash_password(password)
    Auth-->>API: bcrypt hash
    API->>DB: INSERT usuario con password hasheado
    DB-->>API: Usuario creado
    API-->>App: 201 Created {user_id, email}
    App-->>User: ✅ Registro exitoso

    Note over User,DB: LOGIN
    User->>App: Ingresa email + contraseña
    App->>API: POST /auth/login {email, password}
    API->>DB: SELECT usuario por email
    DB-->>API: Usuario encontrado
    API->>Auth: verify_password(plain, hash)

    alt Credenciales válidas
        Auth-->>API: ✅ Verificado
        API->>Auth: create_access_token({sub: user_id, role})
        Auth-->>API: JWT (HS256, 24h expiry)
        API-->>App: 200 OK {access_token, token_type: "bearer"}
        App->>App: Almacenar token en localStorage
        App-->>User: ✅ Redirigir a Dashboard
    else Credenciales inválidas
        Auth-->>API: ❌ No coincide
        API-->>App: 401 Unauthorized
        App-->>User: ❌ Error de credenciales
    end

    Note over User,DB: PETICIÓN AUTENTICADA
    User->>App: Solicita recurso protegido
    App->>App: authInterceptor añade Bearer token
    App->>API: GET /resource (Authorization: Bearer {JWT})
    API->>Auth: decode JWT, validar exp

    alt Token válido
        Auth-->>API: {user_id, role}
        API->>DB: Consultar recurso
        DB-->>API: Datos
        API-->>App: 200 OK {data}
    else Token expirado/inválido
        Auth-->>API: ❌ Token inválido
        API-->>App: 401 Unauthorized
        App->>App: Limpiar token, redirigir a login
    end
```

---

## 9. Diagrama de Componentes - Arquitectura del Sistema

```mermaid
graph TB
    subgraph Clients["🖥️ CAPA DE PRESENTACIÓN"]
        direction LR
        subgraph Angular["Angular 20 (Web - Talleres)"]
            A1[AuthService]
            A2[WorkshopService]
            A3[AuthGuard]
            A4[AuthInterceptor]
            A5["Pages:<br/>Dashboard, Incidents,<br/>Technicians, Profile,<br/>Notifications"]
        end
        subgraph Flutter["Flutter (Móvil - Clientes)"]
            F1[AuthProvider]
            F2[IncidentProvider]
            F3[VehicleProvider]
            F4["Screens:<br/>Home, Report,<br/>Status, History,<br/>Payments"]
        end
    end

    subgraph Backend["⚙️ CAPA DE NEGOCIO - FastAPI"]
        direction TB
        subgraph Routers["Routers (API REST)"]
            R1["/auth"]
            R2["/users"]
            R3["/vehicles"]
            R4["/incidents"]
            R5["/workshops"]
            R6["/payments"]
            R7["/notifications"]
        end
        subgraph Services["Servicios"]
            S1["IncidentService<br/>(Orquestación)"]
            S2["AssignmentService<br/>(Asignación Inteligente)"]
            S3["NotificationService<br/>(Push + DB)"]
        end
        subgraph AI["Módulos IA"]
            AI1["AudioProcessor<br/>(Whisper + GPT-4o-mini)"]
            AI2["ImageClassifier<br/>(GPT-4o Vision)"]
            AI3["IncidentClassifier<br/>(Votación Ponderada)"]
            AI4["SummaryGenerator<br/>(GPT-4o-mini)"]
        end
        subgraph Utils["Utilidades"]
            U1["Security<br/>(JWT + bcrypt)"]
            U2["Geolocation<br/>(Haversine + ETA)"]
        end
    end

    subgraph Data["🗄️ CAPA DE DATOS"]
        DB[(PostgreSQL 16<br/>SQLAlchemy ORM)]
        Alembic["Alembic<br/>(Migraciones)"]
    end

    subgraph External["☁️ SERVICIOS EXTERNOS"]
        OpenAI["OpenAI API<br/>(Whisper, GPT-4o,<br/>GPT-4o-mini)"]
        Firebase["Firebase<br/>Cloud Messaging"]
    end

    Angular -->|HTTP + JWT| Routers
    Flutter -->|HTTP + JWT| Routers
    Routers --> Services
    Routers --> U1
    Services --> AI
    Services --> S3
    S2 --> U2
    AI --> OpenAI
    S3 --> Firebase
    Services --> DB
    Routers --> DB
    Alembic --> DB
```

---

## 10. Diagrama de Actividades - Flujo Completo de Emergencia

```mermaid
flowchart TD
    Start([🚗 Cliente detecta emergencia]) --> Login{¿Está autenticado?}
    Login -->|No| DoLogin[Iniciar sesión / Registrarse]
    DoLogin --> Login
    Login -->|Sí| SelectVehicle[Seleccionar vehículo registrado]
    SelectVehicle --> ReportForm[Abrir formulario de reporte]

    ReportForm --> InputText[Escribir descripción del problema]
    ReportForm --> InputPhoto[Tomar fotos del incidente]
    ReportForm --> InputAudio[Grabar audio describiendo situación]
    ReportForm --> InputGPS[Capturar ubicación GPS automática]

    InputText --> Submit[Enviar reporte de emergencia]
    InputPhoto --> Submit
    InputAudio --> Submit
    InputGPS --> Submit

    Submit --> ProcessAI{Procesamiento IA paralelo}

    ProcessAI --> Whisper["🎙️ Whisper: Transcribir audio"]
    ProcessAI --> Vision["📷 GPT-4o Vision: Analizar imágenes"]
    ProcessAI --> TextAnalysis["📝 GPT-4o-mini: Extraer keywords de texto"]

    Whisper --> Classify["🧠 Clasificador: Votación ponderada<br/>Texto 30% + Audio 35% + Imágenes 35%"]
    Vision --> Classify
    TextAnalysis --> Classify

    Classify --> TypeResult["Resultado: Tipo + Prioridad + Confianza"]
    TypeResult --> Summary["📋 Generar resumen estructurado"]
    Summary --> Assignment["🔍 Motor de asignación inteligente"]

    Assignment --> FindWorkshops["Buscar talleres en radio 50km<br/>(Fórmula Haversine)"]
    FindWorkshops --> HasWorkshops{¿Talleres disponibles?}

    HasWorkshops -->|No| NoAssign["⚠️ Sin taller disponible<br/>Status: PENDING"]
    NoAssign --> NotifyClient1["🔔 Notificar: Buscando taller"]

    HasWorkshops -->|Sí| Score["Calcular puntuación multifactor:<br/>Distancia 35% + Especialidad 25%<br/>+ Disponibilidad 20% + Capacidad 10%<br/>+ Carga 10%"]
    Score --> BestMatch["Seleccionar mejor taller + técnico"]
    BestMatch --> Assign["Asignar incidente<br/>Status: ASSIGNED"]
    Assign --> NotifyWorkshop["🔔 Notificar taller asignado"]
    Assign --> NotifyClient2["🔔 Notificar cliente: Taller asignado"]

    NotifyWorkshop --> WorkshopDecision{¿Taller acepta?}
    WorkshopDecision -->|Rechazar| RejectReason["Ingresar motivo de rechazo"]
    RejectReason --> BackToPending["Status: PENDING<br/>Volver a buscar"]
    BackToPending --> Assignment

    WorkshopDecision -->|Aceptar| SelectTech["Seleccionar técnico disponible"]
    SelectTech --> InProgress["Status: IN_PROGRESS<br/>Técnico en camino"]
    InProgress --> NotifyClient3["🔔 Notificar: Técnico en camino + ETA"]

    NotifyClient3 --> ServiceDone["✅ Técnico completa servicio"]
    ServiceDone --> EnterCost["Ingresar costo final + notas"]
    EnterCost --> Complete["Status: COMPLETED"]
    Complete --> NotifyClient4["🔔 Notificar: Servicio completado"]

    NotifyClient4 --> PayDecision{Cliente realiza pago}
    PayDecision --> SelectMethod["Seleccionar método de pago"]
    SelectMethod --> ProcessPay["Procesar pago<br/>(Comisión plataforma 10%)"]
    ProcessPay --> PayConfirm["Pago confirmado ✅"]

    PayConfirm --> EndNode([🏁 Fin del flujo])
    NotifyClient1 --> WaitNode["Esperar asignación manual"]
    WaitNode --> Assignment
```

---

## 11. Diagrama de Despliegue - Arquitectura Física

```mermaid
graph TB
    subgraph ClientDevices["📱 Dispositivos Cliente"]
        direction LR
        Mobile["📱 Smartphone<br/>(Android/iOS)<br/>Flutter App"]
        Browser["🖥️ Navegador Web<br/>(Chrome/Firefox)<br/>Angular 20 SPA"]
    end

    subgraph AppServer["🖧 Servidor de Aplicación"]
        direction TB
        subgraph Runtime["Python 3.12 Runtime"]
            Uvicorn["Uvicorn ASGI Server<br/>Puerto 8000"]
            FastAPI["FastAPI Framework"]
            SQLAlchemy["SQLAlchemy ORM<br/>Pool: 10 conexiones<br/>Max overflow: 20"]
        end
        subgraph Storage["📂 Almacenamiento Local"]
            Uploads["uploads/<br/>├── images/<br/>└── audio/"]
        end
    end

    subgraph DBServer["🗄️ Servidor de Base de Datos"]
        PostgreSQL["PostgreSQL 16<br/>Puerto 5432<br/>DB: emergencias_vehiculares"]
        AlembicMig["Alembic Migrations"]
    end

    subgraph CloudServices["☁️ Servicios en la Nube"]
        direction LR
        subgraph OpenAI["OpenAI API"]
            WhisperAPI["Whisper API<br/>(Audio → Texto)"]
            GPT4oVision["GPT-4o Vision<br/>(Análisis imágenes)"]
            GPT4oMini["GPT-4o-mini<br/>(Clasificación, Resumen)"]
        end
        subgraph Google["Google Cloud"]
            FCM["Firebase Cloud Messaging<br/>(Push Notifications)"]
        end
    end

    Mobile -->|HTTPS REST API<br/>JWT Bearer Auth| Uvicorn
    Browser -->|HTTPS REST API<br/>JWT Bearer Auth| Uvicorn
    Uvicorn --> FastAPI
    FastAPI --> SQLAlchemy
    FastAPI --> Uploads
    SQLAlchemy -->|TCP 5432<br/>Connection Pool| PostgreSQL
    AlembicMig -->|Schema Management| PostgreSQL
    FastAPI -->|HTTPS API Key| OpenAI
    FastAPI -->|HTTPS Service Account| FCM
```
