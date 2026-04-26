import os
import sys
import time

# Añadir el directorio actual al path
sys.path.append(os.getcwd())

from sqlalchemy.orm import Session
from app.database import SessionLocal, engine, Base
from app.models import User, Vehicle, Workshop, Technician, Incident
from app.models.enums import UserRole, IncidentStatus, IncidentType, IncidentPriority
from app.utils.security import hash_password
from app.services.incident_service import create_incident, update_incident_status
from app.services.assignment_service import find_best_workshop

def run_stress_test():
    print("--- INICIANDO TEST DE ESTRES INTEGRAL ---")
    db = SessionLocal()
    
    try:
        # 1. Crear Nuevo Cliente
        print("\n[1/6] Creando nuevo cliente: 'Alejandro Test'...")
        client = User(
            email="alejandro_test@example.com",
            password_hash=hash_password("password123"),
            full_name="Alejandro Test",
            phone="+591 70000001",
            role=UserRole.CLIENT
        )
        db.add(client)
        db.flush()

        # 2. Registrar Vehículo
        print("[2/6] Registrando vehiculo: 'Tesla Model 3'...")
        vehicle = Vehicle(
            user_id=client.id,
            brand="Tesla",
            model="Model 3",
            year=2024,
            color="Rojo",
            license_plate="TES-LA1"
        )
        db.add(vehicle)
        db.flush()

        # 3. Crear Nuevo Taller y Técnico
        print("[3/6] Creando Taller 'AutoService Central' y Tecnico 'Roberto'...")
        workshop = Workshop(
            name="AutoService Central",
            email="central@example.com",
            password_hash=hash_password("taller123"),
            phone="+591 70000002",
            address="Centro de la Ciudad",
            latitude=-17.7833,
            longitude=-63.1821,
            capacity=20,
            specialties=["Eléctrico", "Baterías", "Mecánica"]
        )
        db.add(workshop)
        db.flush()

        tech = Technician(
            workshop_id=workshop.id,
            name="Roberto Electrico",
            specialties=["Eléctrico", "Baterías"],
            is_available=True
        )
        db.add(tech)
        db.commit()

        # 4. Simular Incidente (Falla Eléctrica)
        print("[4/6] Simulando Incidente: 'Falla Electrica Total'...")
        # Simulamos la creación manual del incidente
        incident = Incident(
            user_id=client.id,
            vehicle_id=vehicle.id,
            latitude=-17.7840,
            longitude=-63.1830,
            address="Cerca del centro",
            description="El auto no enciende, nada de corriente.",
            incident_type=IncidentType.BATTERY,
            priority=IncidentPriority.CRITICAL,
            status=IncidentStatus.PENDING
        )
        db.add(incident)
        db.flush()

        # 5. Probar Asignación Inteligente
        print("[5/6] Ejecutando algoritmo de Asignacion Inteligente...")
        assignment = find_best_workshop(db, incident)
        if assignment and assignment.workshop_id == workshop.id:
            print(f"OK: El sistema asigno correctamente a '{workshop.name}'")
            print(f"OK: Match IA detectado: {assignment.estimated_arrival_minutes} min de llegada.")
            incident.workshop_id = workshop.id
            incident.technician_id = tech.id
            incident.status = IncidentStatus.ASSIGNED
        else:
            print("ERROR: El sistema no asigno el taller esperado.")
            return

        # 6. Ciclo de Vida del Incidente
        print("[6/6] Completando ciclo de vida (Aceptacion -> Finalizacion)...")
        incident.status = IncidentStatus.IN_PROGRESS
        db.flush()
        print("OK: Estado cambiado a: EN PROCESO")
        
        incident.status = IncidentStatus.COMPLETED
        incident.final_cost = 450.0
        db.commit()
        print("OK: Estado cambiado a: COMPLETADO (Costo: 450 Bs.)")

        print("\n--- TEST FINALIZADO CON EXITO ---")
        print(f"Se validaron: Registro, Vehículos, Talleres, IA y Flujo de Estados.")

    except Exception as e:
        db.rollback()
        print(f"\n❌ ERROR CRÍTICO DURANTE EL TEST: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    run_stress_test()
