import os
import sys

# Añadir el directorio actual al path para que encuentre el paquete 'app'
sys.path.append(os.getcwd())

from app.database import engine, SessionLocal, Base
from app.models import User, Vehicle, Workshop, Technician
from app.models.enums import UserRole
from app.utils.security import hash_password

def seed_demo():
    print("--- Iniciando Preparación de la Demo ---")
    
    # Reiniciar base de datos
    print("Limpiando datos previos...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    try:
        # 1. Crear Cliente
        print("Registrando Cliente de prueba...")
        u = User(
            email="carlos@example.com", 
            password_hash=hash_password("password123"), 
            full_name="Carlos Mendoza", 
            phone="+591 71234567", 
            role=UserRole.CLIENT
        )
        db.add(u)
        db.flush() # Para obtener el ID
        
        # 2. Registrar Vehículo
        print("Asignando vehículo Toyota Corolla...")
        v = Vehicle(
            user_id=u.id, 
            brand="Toyota", 
            model="Corolla", 
            year=2024, 
            color="Blanco", 
            license_plate="ABC-1234"
        )
        db.add(v)
        
        # 3. Crear Taller
        print("Registrando Taller Mecánico 'El Rápido'...")
        w = Workshop(
            name="Taller Mecánico El Rápido", 
            email="elrapido@example.com", 
            password_hash=hash_password("taller123"), 
            phone="+591 73456789",
            address="Av. Banzer y 3er Anillo", 
            latitude=-17.7650, 
            longitude=-63.1800,
            capacity=10, 
            specialties=["Llantas", "Mecánica", "Motor", "Baterías"]
        )
        db.add(w)
        db.flush()
        
        # 4. Crear Técnicos
        print("Asignando técnicos al taller...")
        tech1 = Technician(
            workshop_id=w.id, 
            name="Juan Pérez", 
            specialties=["Baterías", "Eléctrico"], 
            is_available=True
        )
        tech2 = Technician(
            workshop_id=w.id, 
            name="Samuel Mamani", 
            specialties=["Llantas", "Pinchazo", "Auxilio"], 
            is_available=True
        )
        tech3 = Technician(
            workshop_id=w.id, 
            name="Pedro Quispe", 
            specialties=["Motor", "Mecánica General"], 
            is_available=True
        )
        
        db.add_all([tech1, tech2, tech3])
        db.commit()
        
        print("\n--- ¡Demo preparada con éxito! ---")
        print("Cliente: carlos@example.com / password123")
        print("Taller:  elrapido@example.com / taller123")
        print("\nYa puedes iniciar el servidor con 'uvicorn app.main:app --reload'")

    except Exception as e:
        db.rollback()
        print(f"ERROR: No se pudo preparar la demo: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_demo()
