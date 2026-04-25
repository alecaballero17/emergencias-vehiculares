# Casos de Uso del Sistema - Emergencias Vehiculares

A continuación, se detallan todos los Casos de Uso actualizados de la plataforma, divididos por el tipo de actor que interactúa con el sistema. Esta lista refleja el funcionamiento final del proyecto.

## 👤 Actor: Cliente (App Móvil - Flutter)
Los clientes son los usuarios finales que experimentan problemas con sus vehículos y solicitan auxilio a través de la aplicación móvil.

| ID | Nombre del Caso de Uso | Descripción |
|---|---|---|
| **UC-C01** | Registrarse | El cliente crea una cuenta proporcionando nombre, correo, teléfono y contraseña. |
| **UC-C02** | Iniciar sesión | El cliente accede a la aplicación usando su correo y contraseña. |
| **UC-C03** | Gestionar perfil | El cliente puede ver y actualizar su información personal de contacto. |
| **UC-C04** | Registrar vehículo | El cliente añade un nuevo vehículo a su garaje virtual (marca, modelo, año, placa, color). |
| **UC-C05** | Gestionar vehículos | El cliente puede editar o eliminar vehículos de su garaje. |
| **UC-C06** | Reportar emergencia (Multimodal) | El cliente reporta un incidente seleccionando un vehículo e ingresando datos mediante texto, audio (micrófono) y fotos (cámara/galería). |
| **UC-C07** | Enviar ubicación GPS | Durante el reporte, el sistema captura automáticamente las coordenadas GPS del cliente. |
| **UC-C08** | Ver seguimiento en tiempo real | El cliente ve el estado de su emergencia (Pendiente, Asignado, En Proceso, Completado). |
| **UC-C09** | Recibir Notificaciones Push | El cliente recibe alertas vibratorias y sonoras cuando un taller acepta el servicio o el técnico va en camino. |
| **UC-C10** | Ver Tiempo Estimado (ETA) | El cliente visualiza en cuántos minutos llegará el técnico a su ubicación. |
| **UC-C11** | Cancelar solicitud | El cliente puede cancelar la emergencia antes de que un técnico llegue al lugar. |
| **UC-C12** | Ver Historial de Servicios | El cliente puede consultar todos los auxilios previos, diagnósticos de la IA y costos. |

---

## 🔧 Actor: Taller Mecánico (Panel Web - Angular)
Los talleres mecánicos (administradores) utilizan el dashboard web para gestionar las emergencias entrantes y a su personal.

| ID | Nombre del Caso de Uso | Descripción |
|---|---|---|
| **UC-T01** | Registrarse como Taller | El taller crea una cuenta especificando su ubicación GPS, capacidad y especialidades (baterías, grúa, motor, etc.). |
| **UC-T02** | Iniciar sesión | El administrador del taller accede al panel web. |
| **UC-T03** | Ver incidentes disponibles | El taller ve en tiempo real una lista de las emergencias cercanas que la IA le ha sugerido o que están libres. |
| **UC-T04** | Ver detalle con Análisis IA | El taller abre un incidente y lee el análisis inteligente (tipo de falla, resumen, nivel de confianza) extraído de los audios y fotos del cliente. |
| **UC-T05** | Aceptar Servicio | El taller acepta tomar una emergencia y compromete a su personal a asistir. |
| **UC-T06** | Asignar Técnico | Al aceptar el servicio, el taller selecciona cuál de sus técnicos disponibles irá al rescate. |
| **UC-T07** | Rechazar Servicio | El taller descarta una emergencia si no tiene capacidad o no es de su especialidad. |
| **UC-T08** | Completar Servicio | Una vez solucionado el problema, el taller finaliza el incidente ingresando el costo total cobrado. |
| **UC-T09** | Gestionar Técnicos | El taller puede registrar, editar o eliminar técnicos de su planilla. |
| **UC-T10** | Cambiar Disponibilidad | El taller marca a sus técnicos como "disponibles" u "ocupados". |
| **UC-T11** | Ver Historial Financiero | El taller revisa todos los servicios completados y los costos generados. |

---

## 🤖 Actor: Sistema de Inteligencia Artificial (Backend Python)
Módulos automatizados que procesan datos sin intervención humana.

| ID | Nombre del Caso de Uso | Descripción |
|---|---|---|
| **UC-S01** | Transcribir Audio | El sistema recibe el audio del cliente y usa Whisper de OpenAI para convertirlo a texto. |
| **UC-S02** | Analizar Imágenes | El sistema usa GPT-4o Vision para inspeccionar las fotos de la emergencia en busca de daños estructurales o problemas mecánicos. |
| **UC-S03** | Clasificar Incidente | El sistema realiza una votación ponderada (audio, imagen, texto) para determinar la categoría de la falla y su prioridad. |
| **UC-S04** | Generar Resumen | El sistema redacta un resumen ejecutivo de la situación y las herramientas recomendadas para el mecánico. |
| **UC-S05** | Calcular ETA y Distancias | El sistema cruza las coordenadas GPS del cliente y los talleres usando la fórmula de Haversine para estimar el tiempo de llegada. |
| **UC-S06** | Disparar Notificaciones | El sistema se comunica con Firebase (FCM) para despertar el celular del cliente con alertas push nativas. |
