import os
import sys
from datetime import datetime, date
import enum
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

# Añadir el directorio backend al path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import Base
# Importar todos los modelos para registrarlos en Base.metadata
from app.models import *

load_dotenv()

database_url = os.getenv("DATABASE_URL")
if not database_url:
    print("Error: DATABASE_URL no encontrada en el archivo .env")
    sys.exit(1)

# Usar postgresql o sqlite según la URL
engine = create_engine(database_url)
metadata = Base.metadata

output_file = "emergencias_vehiculares_dump.sql"

print(f"Generando script SQL desde: {database_url}")
print(f"Guardando archivo en: {output_file}")

with open(output_file, "w", encoding="utf-8") as f:
    f.write("-- =====================================================\n")
    f.write("-- SCRIPT DE ESTRUCTURA Y DATOS DE LA BASE DE DATOS\n")
    f.write(f"-- Generado el: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write("-- =====================================================\n\n")
    
    # Desactivar llaves foráneas temporalmente para la importación fácil
    f.write("-- Desactivar restricciones de integridad\n")
    f.write("SET session_replication_role = 'replica';\n\n")
    
    # 1. Generar DDL (Estructura de Tablas)
    f.write("-- === ESTRUCTURA DE TABLAS (DDL) ===\n\n")
    
    for table in metadata.sorted_tables:
        f.write(f"-- Estructura de la tabla: {table.name}\n")
        from sqlalchemy.schema import CreateTable
        ddl = CreateTable(table).compile(bind=engine)
        ddl_str = str(ddl).strip()
        f.write(f"{ddl_str};\n\n")
        
    # 2. Generar DML (Inserción de Datos)
    f.write("-- === DATOS DE LAS TABLAS (DML) ===\n\n")
    
    with engine.connect() as conn:
        for table in metadata.sorted_tables:
            f.write(f"-- Datos de la tabla: {table.name}\n")
            rows = conn.execute(table.select()).fetchall()
            if not rows:
                f.write(f"-- (Sin datos)\n\n")
                continue
                
            columns = table.columns.keys()
            for row in rows:
                values_str = []
                for val in row:
                    if val is None:
                        values_str.append("NULL")
                    elif isinstance(val, (datetime, date)):
                        values_str.append(f"'{val.isoformat()}'")
                    elif isinstance(val, bool):
                        values_str.append("TRUE" if val else "FALSE")
                    elif isinstance(val, (int, float)):
                        values_str.append(str(val))
                    elif isinstance(val, enum.Enum):
                        values_str.append(f"'{val.value}'")
                    else:
                        escaped_val = str(val).replace("'", "''")
                        values_str.append(f"'{escaped_val}'")
                
                cols_joined = ", ".join(columns)
                vals_joined = ", ".join(values_str)
                f.write(f"INSERT INTO {table.name} ({cols_joined}) VALUES ({vals_joined});\n")
            f.write("\n")
            
    f.write("-- Reactivar restricciones de integridad\n")
    f.write("SET session_replication_role = 'origin';\n")

print("¡Script generado exitosamente!")
