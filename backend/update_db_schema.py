import sys
from sqlalchemy import text
from app.database import engine
from app.config import get_settings

def run_migration():
    settings = get_settings()
    print(f"Conectando a base de datos para migración: {settings.database_url}")
    
    query = "ALTER TABLE quotations ADD COLUMN IF NOT EXISTS estimated_arrival_hours FLOAT;"
    
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            print("Ejecutando: ALTER TABLE quotations ADD COLUMN IF NOT EXISTS estimated_arrival_hours FLOAT;")
            conn.execute(text(query))
            trans.commit()
            print("¡Columna 'estimated_arrival_hours' agregada/verificada con éxito!")
        except Exception as e:
            trans.rollback()
            print(f"Error al realizar la migración: {e}")
            sys.exit(1)

if __name__ == "__main__":
    run_migration()
