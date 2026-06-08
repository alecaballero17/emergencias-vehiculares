import sys
from sqlalchemy import text
from app.database import engine
from app.config import get_settings

def run_migration():
    settings = get_settings()
    print(f"Conectando a base de datos para migración: {settings.database_url}")
    
    query = "ALTER TABLE incidents ADD COLUMN IF NOT EXISTS requires_tow_truck BOOLEAN DEFAULT FALSE;"
    
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            print("Ejecutando: ALTER TABLE incidents ADD COLUMN IF NOT EXISTS requires_tow_truck BOOLEAN DEFAULT FALSE;")
            conn.execute(text(query))
            trans.commit()
            print("¡Columna 'requires_tow_truck' agregada/verificada con éxito!")
        except Exception as e:
            trans.rollback()
            print(f"Error al realizar la migración: {e}")
            sys.exit(1)

if __name__ == "__main__":
    run_migration()
