"""
Script para inicializar la base de datos con datos de prueba realistas ("inteligentes").
Ejecutar: python -m app.seed
"""
import random
import datetime
from app.database import engine, SessionLocal, Base
from app.models import User, Vehicle, Workshop, Technician, Incident, Evidence
from app.models.enums import UserRole, IncidentStatus, IncidentPriority
from app.utils.security import hash_password

def seed():
    # Re-crear tablas desde cero
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # === Usuarios de prueba ===
        user1 = User(
            email="carlos@example.com",
            password_hash=hash_password("password123"),
            full_name="Carlos Mendoza",
            phone="+591 71234567",
            role=UserRole.CLIENT,
        )
        user2 = User(
            email="maria@example.com",
            password_hash=hash_password("password123"),
            full_name="María Gutiérrez",
            phone="+591 72345678",
            role=UserRole.CLIENT,
        )
        user3 = User(
            email="jorge@example.com",
            password_hash=hash_password("password123"),
            full_name="Jorge Villca",
            phone="+591 76543210",
            role=UserRole.CLIENT,
        )
        db.add_all([user1, user2, user3])
        db.flush()

        # === Vehículos ===
        v1 = Vehicle(user_id=user1.id, brand="Toyota", model="Corolla", year=2020, color="Blanco", license_plate="ABC-1234")
        v2 = Vehicle(user_id=user1.id, brand="Honda", model="Civic", year=2019, color="Negro", license_plate="DEF-5678")
        v3 = Vehicle(user_id=user2.id, brand="Hyundai", model="Tucson", year=2021, color="Rojo", license_plate="GHI-9012")
        v4 = Vehicle(user_id=user3.id, brand="Nissan", model="Patrol", year=2018, color="Azul", license_plate="JKL-3456")
        db.add_all([v1, v2, v3, v4])

        # === Talleres ===
        w1_id = 1
        w1 = Workshop(
            name="Taller Mecánico El Rápido",
            email="elrapido@example.com",
            password_hash=hash_password("taller123"),
            phone="+591 73456789",
            address="Av. Banzer y 3er Anillo, Santa Cruz",
            latitude=-17.7650,
            longitude=-63.1800,
            capacity=10,
            specialties=["Eléctrico", "Baterías", "Motor", "Mecánica", "Llantas", "Refrigeración"],
        )
        w2 = Workshop(
            name="AutoServicio López",
            email="lopez@example.com",
            password_hash=hash_password("taller123"),
            phone="+591 74567890",
            address="Av. Santos Dumont, Santa Cruz",
            latitude=-17.8000,
            longitude=-63.1850,
            capacity=5,
            specialties=["Llantas", "Neumáticos", "Carrocería", "Colisión", "Cerrajería", "Llaves"],
        )
        db.add_all([w1, w2])
        db.flush()

        # === Técnicos ===
        techs = [
            Technician(workshop_id=w1.id, name="Juan Pérez", specialties=["Baterías", "Eléctrico"], is_available=True),
            Technician(workshop_id=w1.id, name="Pedro Quispe", specialties=["Mecánica", "Motor", "Radiador"], is_available=True),
            Technician(workshop_id=w1.id, name="Samuel Mamani", specialties=["Llantas", "Neumáticos", "Mecánica"], is_available=True),
            Technician(workshop_id=w1.id, name="Diego Torrez", specialties=["General", "Motor"], is_available=False),
            
            Technician(workshop_id=w2.id, name="Miguel Vargas", specialties=["Cerrajería", "Llaves"], is_available=True),
            Technician(workshop_id=w2.id, name="Roberto Flores", specialties=["Carrocería", "Chasis", "Remolque"], is_available=True),
        ]
        db.add_all(techs)
        db.flush()

        # === Incidentes ===
        now = datetime.datetime.utcnow()

        incidents = []

        # --- 1. Incidentes PENDIENTES (Para probar la vista Available Incidents con IA) ---
        pendientes_data = [
            {
                "type": "battery", 
                "desc": "El auto no prende, hace un sonido de 'click click' al girar la llave y las luces del tablero parpadean débilmente.",
                "transcrip": "Traté de encender el carro esta mañana para ir al trabajo. Sólo suena click, click, click y las luces se apagan. Creo que dejé algo encendido.",
                "ai_sum": "Fallo en sistema de encendido. Los síntomas (sonido 'click' y caída de voltaje en luces) indican una batería descargada o falla en solenoide/alternador.",
                "prio": IncidentPriority.MEDIUM,
                "ai_class": "Sistema Eléctrico (Batería)",
                "conf": 96.5,
                "address": "Equipetrol, Calle 5",
                "lat": -17.7650, "lon": -63.1950
            },
            {
                "type": "crash", 
                "desc": "Me chocaron por detrás en el semáforo. El maletero está hundido y el auto no avanza bien, parece que algo roza la llanta trasera.",
                "transcrip": "Acabo de tener un accidente en la avenida. Un trufi me golpeó por detrás. Necesito grúa porque la llanta trasera izquierda está bloqueada.",
                "ai_sum": "Choque por alcance severo con compromiso de tren de rodaje trasero. Requiere servicio de remolque y posterior trabajo de chapistería y chasis.",
                "prio": IncidentPriority.CRITICAL,
                "ai_class": "Colisión Estructural Alta Gravedad",
                "conf": 98.2,
                "address": "Doble Vía La Guardia, Km 4",
                "lat": -17.8100, "lon": -63.2000
            },
            {
                "type": "tire", 
                "desc": "Caí en un bache gigante y la llanta se reventó. No tengo mi gata hidráulica para cambiarla por la de repuesto.",
                "transcrip": "Hola, estoy en la Avenida San Martín, pasé por un hueco que no vi por la lluvia y mi llanta delantera derecha explotó. El aro parece doblado también.",
                "ai_sum": "Reventón de neumático por impacto. Daño estructural posible en el aro/rin. Requiere asistencia en sitio para reemplazo por rueda de repuesto o grúa si el rin está inoperable.",
                "prio": IncidentPriority.HIGH,
                "ai_class": "Desperfecto Neumático",
                "conf": 92.0,
                "address": "Av. San Martín, esquina 4to Anillo",
                "lat": -17.7600, "lon": -63.1900
            },
            {
                "type": "keys_locked", 
                "desc": "Dejé las llaves puestas en el contacto y al cerrar la puerta saltó el seguro.",
                "transcrip": "Estoy en el parqueo del supermercado Fidalga. Bajé un segundo, cerré la puerta y me di cuenta que las llaves están adentro. El motor está apagado.",
                "ai_sum": "Confinamiento de llaves al interior del habitáculo. No hay riesgo humano inmediato. Requiere técnico cerrajero de emergencia.",
                "prio": IncidentPriority.LOW,
                "ai_class": "Cerrajería Automotriz",
                "conf": 99.0,
                "address": "Supermercado Fidalga, Urubó",
                "lat": -17.7500, "lon": -63.2100
            },
            {
                "type": "overheating",
                "desc": "Humo blanco intenso sale del capó, temperatura al máximo.",
                "transcrip": "Iba manejando y empezó a oler a dulce, de repente salió mucho vapor blanco. Me detuve inmediatamente.",
                "ai_sum": "Fuga crítica de refrigerante / sobrecalentamiento. El olor a refrigerante evaporado sugiere manguera rota o falla severa del radiador. NO encender motor.",
                "prio": IncidentPriority.CRITICAL,
                "ai_class": "Fallo Sistema Refrigeración",
                "conf": 95.5,
                "address": "Plan 3000, Rotonda",
                "lat": -17.8300, "lon": -63.1400
            },
            {
                "type": "engine",
                "desc": "Pérdida súbita de potencia y luz de 'Check Engine' parpadeando.",
                "transcrip": "Estaba yendo normal y el auto empezó a cascabelear horrible, la luz del motor parpadea y no tiene fuerza para avanzar.",
                "ai_sum": "Misfire (fallo de encendido) múltiple detectado. Luz parpadeante indica daño inminente al catalizador. Requiere escáner OBD2 y posible grúa.",
                "prio": IncidentPriority.HIGH,
                "ai_class": "Mecánica de Motor",
                "conf": 91.2,
                "address": "Av. Roca y Coronado, 2do Anillo",
                "lat": -17.7900, "lon": -63.2000
            }
        ]

        # Añadir pendientes a la DB
        for i, pd in enumerate(pendientes_data):
            time_offset = now - datetime.timedelta(minutes=5 + (i * 12))
            inc = Incident(
                user_id=user1.id if i % 2 == 0 else user2.id,
                vehicle_id=v1.id if i % 2 == 0 else v3.id,
                incident_type=pd["type"],
                description=pd["desc"],
                audio_transcription=pd["transcrip"],
                priority=pd["prio"],
                status=IncidentStatus.PENDING,
                address=pd["address"],
                latitude=pd["lat"],
                longitude=pd["lon"],
                ai_summary=pd["ai_sum"],
                ai_classification=pd["ai_class"],
                ai_confidence=pd["conf"],
                created_at=time_offset,
                updated_at=time_offset
            )
            incidents.append(inc)

        # --- 2. Incidentes COMPLETADOS (Para probar pestaña de FINANZAS) ---
        # Se asignarán a 'Taller Mecánico El Rápido' (w1)
        tipos_base = ["battery", "tire", "engine", "overheating"]
        for i in range(1, 26):  # 25 completados para historial rico
            dias_atras = random.randint(0, 30)
            horas_atras = random.randint(1, 23)
            time_created = now - datetime.timedelta(days=dias_atras, hours=horas_atras)
            time_completed = time_created + datetime.timedelta(hours=random.uniform(1.0, 3.5))
            
            tipo = random.choice(tipos_base)
            
            base_cost = {
                "battery": random.uniform(100.0, 350.0),
                "tire": random.uniform(50.0, 150.0),
                "engine": random.uniform(200.0, 1500.0),
                "overheating": random.uniform(150.0, 800.0)
            }
            
            final_cost = round(base_cost[tipo], 2)
            
            inc = Incident(
                user_id=user3.id,
                vehicle_id=v4.id,
                workshop_id=w1.id,
                technician_id=techs[0].id if tipo == "battery" else techs[1].id, # Machea técnicos de w1
                incident_type=tipo,
                description=f"Atención programada/emergencia histórica #{i}",
                priority=IncidentPriority.LOW,
                status=IncidentStatus.COMPLETED,
                address="Servicio en ubicación registrada",
                latitude=-16.5000 + random.uniform(-0.05, 0.05),
                longitude=-68.1500 + random.uniform(-0.05, 0.05),
                final_cost=final_cost,
                created_at=time_created,
                assigned_at=time_created + datetime.timedelta(minutes=15),
                completed_at=time_completed
            )
            incidents.append(inc)

        # --- 3. Incidentes EN PROGRESO ---
        inc_prog = Incident(
            user_id=user1.id, vehicle_id=v2.id, workshop_id=w1.id, technician_id=techs[1].id,
            incident_type="engine", description="Mantenimiento correctivo en ruta.",
            priority=IncidentPriority.MEDIUM, status=IncidentStatus.IN_PROGRESS,
            address="Av. Busch", latitude=-16.5050, longitude=-68.1380,
            ai_summary="Falla de sistema de admisión. El técnico está en el lugar evaluando.",
            created_at=now - datetime.timedelta(hours=1), assigned_at=now - datetime.timedelta(minutes=40)
        )
        incidents.append(inc_prog)

        db.add_all(incidents)
        db.commit()

        print("Base de datos RE-POBLADA con dataset realista para defensa.")
        print(f"   - 2 Talleres, 6 Técnicos, {len(incidents)} Incidentes.")
        print(f"   - Workshop principal TEST: elrapido@example.com / taller123")

    except Exception as e:
        db.rollback()
        print(f"Error durante el seed: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
