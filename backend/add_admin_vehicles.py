import os
import sys
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add backend directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.models.user import User
from app.models.vehicle import Vehicle

load_dotenv()

database_url = os.getenv("DATABASE_URL")
if not database_url:
    print("Error: DATABASE_URL not found in .env")
    sys.exit(1)

engine = create_engine(database_url)
Session = sessionmaker(bind=engine)
db = Session()

try:
    admin = db.query(User).filter(User.email == "admin@demo.com").first()
    if not admin:
        print("Error: No se encontró al usuario admin@demo.com. Ejecuta primero insert_admin.py")
        sys.exit(1)

    vehicles_to_add = [
        {
            "brand": "Toyota",
            "model": "Hilux 4x4",
            "year": 2021,
            "color": "Rojo",
            "license_plate": "SCZ-2244",
        },
        {
            "brand": "Suzuki",
            "model": "Grand Vitara",
            "year": 2022,
            "color": "Plateado",
            "license_plate": "SCZ-8899",
        }
    ]

    for v_data in vehicles_to_add:
        # Check if plate already exists
        existing = db.query(Vehicle).filter(Vehicle.license_plate == v_data["license_plate"]).first()
        if existing:
            print(f"El vehículo con placa {v_data['license_plate']} ya existe.")
        else:
            v = Vehicle(
                tenant_id=admin.tenant_id,
                user_id=admin.id,
                brand=v_data["brand"],
                model=v_data["model"],
                year=v_data["year"],
                color=v_data["color"],
                license_plate=v_data["license_plate"],
            )
            db.add(v)
            print(f"Vehículo {v_data['brand']} {v_data['model']} agregado para el admin.")
            
    db.commit()
    print("Vehículos del administrador sincronizados con éxito.")
except Exception as e:
    db.rollback()
    print(f"Error al agregar vehículos: {e}")
finally:
    db.close()
