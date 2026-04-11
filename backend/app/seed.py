"""
Script para inicializar la base de datos con datos de prueba.
Ejecutar: python -m app.seed
"""
from app.database import engine, SessionLocal, Base
from app.models import *
from app.utils.security import hash_password


def seed():
    # Crear tablas
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # Verificar si ya hay datos
        if db.query(User).first():
            print("La base de datos ya tiene datos. Abortando seed.")
            return

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
        db.add_all([user1, user2])
        db.flush()

        # === Vehículos ===
        vehicle1 = Vehicle(
            user_id=user1.id,
            brand="Toyota",
            model="Corolla",
            year=2020,
            color="Blanco",
            license_plate="ABC-1234",
        )
        vehicle2 = Vehicle(
            user_id=user1.id,
            brand="Honda",
            model="Civic",
            year=2019,
            color="Negro",
            license_plate="DEF-5678",
        )
        vehicle3 = Vehicle(
            user_id=user2.id,
            brand="Hyundai",
            model="Tucson",
            year=2021,
            color="Rojo",
            license_plate="GHI-9012",
        )
        db.add_all([vehicle1, vehicle2, vehicle3])

        # === Talleres ===
        workshop1 = Workshop(
            name="Taller Mecánico El Rápido",
            email="elrapido@example.com",
            password_hash=hash_password("taller123"),
            phone="+591 73456789",
            address="Av. 6 de Agosto #1234, La Paz",
            latitude=-16.5000,
            longitude=-68.1500,
            capacity=5,
            specialties=["battery", "engine", "tire", "overheating"],
        )
        workshop2 = Workshop(
            name="AutoServicio López",
            email="lopez@example.com",
            password_hash=hash_password("taller123"),
            phone="+591 74567890",
            address="Calle Comercio #567, La Paz",
            latitude=-16.5100,
            longitude=-68.1300,
            capacity=3,
            specialties=["tire", "crash", "keys_lost", "keys_locked"],
        )
        workshop3 = Workshop(
            name="Taller Premium Motors",
            email="premium@example.com",
            password_hash=hash_password("taller123"),
            phone="+591 75678901",
            address="Zona Sur, Calle 21 #890, La Paz",
            latitude=-16.5300,
            longitude=-68.0800,
            capacity=8,
            specialties=["battery", "engine", "crash", "tire", "overheating"],
        )
        db.add_all([workshop1, workshop2, workshop3])
        db.flush()

        # === Técnicos ===
        technicians = [
            Technician(workshop_id=workshop1.id, name="Juan Pérez", phone="+591 71111111",
                       specialties=["battery", "engine"], is_available=True,
                       latitude=-16.5010, longitude=-68.1490),
            Technician(workshop_id=workshop1.id, name="Pedro Quispe", phone="+591 71111112",
                       specialties=["tire", "overheating"], is_available=True,
                       latitude=-16.4990, longitude=-68.1510),
            Technician(workshop_id=workshop2.id, name="Miguel Torres", phone="+591 72222221",
                       specialties=["tire", "keys_lost", "keys_locked"], is_available=True,
                       latitude=-16.5110, longitude=-68.1310),
            Technician(workshop_id=workshop2.id, name="Roberto Mamani", phone="+591 72222222",
                       specialties=["crash"], is_available=True,
                       latitude=-16.5090, longitude=-68.1290),
            Technician(workshop_id=workshop3.id, name="Luis Vargas", phone="+591 73333331",
                       specialties=["battery", "engine", "crash"], is_available=True,
                       latitude=-16.5310, longitude=-68.0810),
            Technician(workshop_id=workshop3.id, name="Diego Flores", phone="+591 73333332",
                       specialties=["tire", "overheating"], is_available=True,
                       latitude=-16.5290, longitude=-68.0790),
            Technician(workshop_id=workshop3.id, name="Andrés Choque", phone="+591 73333333",
                       specialties=["engine", "battery"], is_available=False,
                       latitude=-16.5320, longitude=-68.0820),
        ]
        db.add_all(technicians)

        db.commit()
        print("✅ Base de datos inicializada con datos de prueba:")
        print(f"   - 2 usuarios (carlos@example.com, maria@example.com)")
        print(f"   - 3 vehículos")
        print(f"   - 3 talleres (elrapido@example.com, lopez@example.com, premium@example.com)")
        print(f"   - 7 técnicos")
        print(f"\n   Contraseñas: usuarios='password123', talleres='taller123'")

    except Exception as e:
        db.rollback()
        print(f"❌ Error: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
