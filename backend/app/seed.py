"""
Script para inicializar la base de datos con datos de prueba.
Ejecutar: python -m app.seed
"""
from app.database import engine, SessionLocal, Base
from app.models import *
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
        w1 = Workshop(
            name="Taller Mecánico El Rápido",
            email="elrapido@example.com",
            password_hash=hash_password("taller123"),
            phone="+591 73456789",
            address="Av. 6 de Agosto #1234, La Paz",
            latitude=-16.5000,
            longitude=-68.1500,
            capacity=10,
            specialties=["battery", "engine", "tire", "overheating"],
        )
        w2 = Workshop(
            name="AutoServicio López",
            email="lopez@example.com",
            password_hash=hash_password("taller123"),
            phone="+591 74567890",
            address="Calle Comercio #567, La Paz",
            latitude=-16.5100,
            longitude=-68.1300,
            capacity=5,
            specialties=["tire", "crash", "keys_lost", "keys_locked"],
        )
        w3 = Workshop(
            name="Taller Premium Motors",
            email="premium@example.com",
            password_hash=hash_password("taller123"),
            phone="+591 75678901",
            address="Zona Sur, Calle 21 #890, La Paz",
            latitude=-16.5300,
            longitude=-68.0800,
            capacity=15,
            specialties=["battery", "engine", "crash", "tire", "overheating"],
        )
        db.add_all([w1, w2, w3])
        db.flush()

        # === Técnicos ===
        techs = [
            Technician(workshop_id=w1.id, name="Juan Pérez", specialties=["battery", "engine"], is_available=True),
            Technician(workshop_id=w1.id, name="Pedro Quispe", specialties=["tire", "overheating"], is_available=True),
            Technician(workshop_id=w1.id, name="Samuel Mamani", specialties=["engine"], is_available=False),
            
            Technician(workshop_id=w2.id, name="Miguel Torres", specialties=["tire", "keys_lost"], is_available=True),
            Technician(workshop_id=w2.id, name="Roberto Mamani", specialties=["crash"], is_available=True),
            
            Technician(workshop_id=w3.id, name="Luis Vargas", specialties=["engine", "crash"], is_available=True),
            Technician(workshop_id=w3.id, name="Diego Flores", specialties=["battery", "tire"], is_available=True),
            Technician(workshop_id=w3.id, name="Andrés Choque", specialties=["engine"], is_available=False),
            Technician(workshop_id=w3.id, name="Carlos Ruiz", specialties=["overheating", "tire"], is_available=True),
        ]
        db.add_all(techs)
        db.flush()

        # === Incidentes ===
        import datetime
        from app.models.enums import IncidentStatus, IncidentPriority

        now = datetime.datetime.utcnow()

        incidents = [
            # PENDIENTES
            Incident(
                user_id=user1.id, vehicle_id=v1.id, incident_type="battery",
                description="Mi auto no arranca en el parqueo de mi casa. No hay señal de luces.",
                audio_transcription="Hola, estoy en mi garaje y mi Toyota no enciende. Creo que la batería murió porque dejé las luces prendidas toda la noche.",
                priority=IncidentPriority.MEDIUM, status=IncidentStatus.PENDING,
                address="Sopocachi, Calle Aspiazu", latitude=-16.5120, longitude=-68.1280,
                ai_summary="Fallo de sistema eléctrico por descarga profunda de batería.",
                ai_classification="Sistema Eléctrico / Batería", ai_confidence=98.5,
                created_at=now - datetime.timedelta(minutes=10)
            ),
            Incident(
                user_id=user2.id, vehicle_id=v3.id, incident_type="overheating",
                description="Sale vapor del capó en plena subida.",
                audio_transcription="¡Ayuda! Mi Tucson está echando humo blanco por el motor y la aguja de temperatura está al máximo. Me detuve a un lado de la vía.",
                priority=IncidentPriority.CRITICAL, status=IncidentStatus.PENDING,
                address="Autopista La Paz - El Alto, km 5", latitude=-16.4800, longitude=-68.1600,
                ai_summary="Sobrecalentamiento crítico. Posible rotura de manguera o falla en termostato.",
                ai_classification="Motor / Refrigeración", ai_confidence=92.0,
                created_at=now - datetime.timedelta(minutes=5)
            ),
            
            # ASIGNADOS (A w1 - El Rápido)
            Incident(
                user_id=user3.id, vehicle_id=v4.id, workshop_id=w1.id,
                incident_type="tire", description="Llantas pinchadas por clavos.",
                audio_transcription="Buenas tardes, pisé una tabla con clavos y tengo dos llantas bajas. Estoy cerca de la Pérez Velasco.",
                priority=IncidentPriority.HIGH, status=IncidentStatus.ASSIGNED,
                address="Av. Mariscal Santa Cruz, Plaza Pérez Velasco", latitude=-16.4950, longitude=-68.1350,
                ai_summary="Daños múltiples en neumáticos por agentes externos. Requiere equipo de parchado o reposición.",
                ai_classification="Neumáticos", ai_confidence=95.0,
                created_at=now - datetime.timedelta(minutes=45), assigned_at=now - datetime.timedelta(minutes=10)
            ),

            # EN PROGRESO (w1)
            Incident(
                user_id=user1.id, vehicle_id=v2.id, workshop_id=w1.id, technician_id=techs[0].id,
                incident_type="engine", description="Ruido metálico en el motor.",
                audio_transcription="Siento un golpeteo fuerte abajo del motor cuando acelero. Preferí no moverlo más.",
                priority=IncidentPriority.HIGH, status=IncidentStatus.IN_PROGRESS,
                address="Zona de San Pedro, Calle Cañada Strongest", latitude=-16.5050, longitude=-68.1380,
                ai_summary="Ruido mecánico anómalo. Inspección necesaria para descartar biela o válvulas.",
                ai_classification="Motor Mecánico", ai_confidence=88.0,
                created_at=now - datetime.timedelta(hours=1), assigned_at=now - datetime.timedelta(minutes=40)
            ),

            # COMPLETADOS (w1)
            Incident(
                user_id=user2.id, vehicle_id=v3.id, workshop_id=w1.id, technician_id=techs[1].id,
                incident_type="tire", description="Cambio de llanta de auxilio.",
                priority=IncidentPriority.LOW, status=IncidentStatus.COMPLETED,
                address="Obrajes, Calle 5", latitude=-16.5250, longitude=-68.1120,
                ai_summary="Asistencia de cambio de neumático completada con éxito.",
                ai_classification="Servicio Rápido", ai_confidence=100.0,
                final_cost=80.0,
                created_at=now - datetime.timedelta(days=1), assigned_at=now - datetime.timedelta(days=1, hours=-1),
                completed_at=now - datetime.timedelta(days=1, hours=-2)
            ),

            # OTROS TALLERES (Para que no esté vacío el sistema global)
            Incident(
                user_id=user3.id, vehicle_id=v4.id, workshop_id=w2.id,
                incident_type="crash", description="Choque por alcance.",
                priority=IncidentPriority.MEDIUM, status=IncidentStatus.IN_PROGRESS,
                address="Av. Busch, Miraflores", latitude=-16.5000, longitude=-68.1200,
                ai_summary="Colisión frontal moderada. Requiere peritaje de chapa y pintura.",
                ai_classification="Carrocería / Choque", ai_confidence=94.5,
                created_at=now - datetime.timedelta(hours=2), assigned_at=now - datetime.timedelta(hours=1)
            ),
        ]
        
        # Agregar datos históricos para llenar el dashboard
        for i in range(10):
            old_date = now - datetime.timedelta(days=i+2, hours=i)
            incidents.append(Incident(
                user_id=user1.id, vehicle_id=v1.id, workshop_id=w1.id, technician_id=techs[0].id,
                incident_type="battery" if i % 2 == 0 else "tire",
                description=f"Incidente histórico de prueba #{i}",
                priority=IncidentPriority.LOW, status=IncidentStatus.COMPLETED,
                address="Centro, La Paz", latitude=-16.4900, longitude=-68.1400,
                ai_summary="Servicio de mantenimiento preventivo regular.",
                final_cost=120.5 + (i * 10),
                created_at=old_date, completed_at=old_date + datetime.timedelta(hours=1)
            ))

        db.add_all(incidents)
        db.commit()
        
        # Evidencias simuladas (una para el incidente pendiente)
        ev1 = Evidence(
            incident_id=incidents[0].id,
            evidence_type="text",
            content="El cliente menciona que el tablero no enciende al girar la llave.",
            ai_analysis="Confirmación visual de fallo en flujo eléctrico primario."
        )
        db.add(ev1)
        db.commit()

        print("✅ Base de datos RE-POBLADA con dataset realista para defensa.")
        print(f"   - 3 Talleres, 9 Técnicos, 20+ Incidentes.")
        print(f"   - Workshop principal TEST: elrapido@example.com / taller123")

    except Exception as e:
        db.rollback()
        print(f"❌ Error durante el seed: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
