import os
import sys
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add backend directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.models.user import User
from app.models.enums import UserRole
from app.utils.security import hash_password

load_dotenv()

database_url = os.getenv("DATABASE_URL")
if not database_url:
    print("Error: DATABASE_URL not found in .env")
    sys.exit(1)

engine = create_engine(database_url)
Session = sessionmaker(bind=engine)
db = Session()

try:
    # check if admin@demo.com already exists
    existing = db.query(User).filter(User.email == "admin@demo.com").first()
    if existing:
        print("El usuario admin@demo.com ya existe en la base de datos.")
    else:
        # We need a tenant_id, let's find the first tenant id or use 1
        from app.models.tenant import Tenant
        tenant = db.query(Tenant).first()
        tenant_id = tenant.id if tenant else 1
        
        admin = User(
            tenant_id=tenant_id,
            email="admin@demo.com",
            password_hash=hash_password("123456"),
            full_name="Super Administrador",
            phone="79999999",
            role=UserRole.ADMIN,
        )
        db.add(admin)
        db.commit()
        print("Usuario admin@demo.com insertado exitosamente como Super Administrador.")
except Exception as e:
    db.rollback()
    print(f"Error al insertar admin: {e}")
finally:
    db.close()
