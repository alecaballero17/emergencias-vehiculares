import os
import sys

# Añadir el directorio actual al path para que encuentre el paquete 'app'
sys.path.append(os.getcwd())

try:
    from app.database import Base, engine
    # Importar los modelos para que SQLAlchemy los reconozca al hacer drop/create
    import app.models 
    
    print("--- Iniciando Reinicio de Base de Datos ---")
    
    # Borrar todas las tablas
    print("Borrando tablas existentes...")
    Base.metadata.drop_all(bind=engine)
    
    # Crear todas las tablas
    print("Recreando tablas...")
    Base.metadata.create_all(bind=engine)
    
    print("--- ¡Base de Datos Reiniciada con Éxito! ---")
    print("Ya puedes iniciar el servidor y crear tus datos de prueba.")

except Exception as e:
    print(f"ERROR: No se pudo reiniciar la base de datos: {e}")
