"""
Seed de datos demo para Fase 2 — Multi-tenant con datos históricos para KPIs.
Crea 2 tenants, usuarios, talleres, técnicos e incidentes con timestamps reales.
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timedelta
import random
import pytz
from app.database import SessionLocal, engine, Base
from app.models import *
from app.utils.security import hash_password

BOL_TZ = pytz.timezone('America/La_Paz')


def seed():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # === TENANTS ===
        t1 = Tenant(name="Auxilio Norte", slug="auxilio-norte", is_active=True)
        t2 = Tenant(name="Mecánicos Express", slug="mecanicos-express", is_active=True)
        db.add_all([t1, t2])
        db.flush()
        print(f"[OK] Tenants creados: {t1.name} (id={t1.id}), {t2.name} (id={t2.id})")

        # === USUARIOS (Tenant 1) ===
        users_t1 = []
        user_list_t1 = [
            ("Juan Pérez", "juan@demo.com"),
            ("María García", "maria@demo.com"),
            ("Carlos López", "carlos@demo.com"),
            ("Alejandra Caballero", "alejandra@demo.com"),
            ("Roberto Rojas", "roberto@demo.com"),
            ("Patricia Ortiz", "patricia@demo.com"),
            ("Daniel Salvatierra", "daniel@demo.com"),
        ]
        for i, (name, email) in enumerate(user_list_t1):
            u = User(
                tenant_id=t1.id, email=email,
                password_hash=hash_password("123456"),
                full_name=name, phone=f"7000000{i}", role=UserRole.CLIENT,
            )
            db.add(u)
            users_t1.append(u)

        # === PLATFORM ADMINISTRATOR (Super Admin) ===
        admin = User(
            tenant_id=t1.id,
            email="admin@demo.com",
            password_hash=hash_password("123456"),
            full_name="Super Administrador",
            phone="79999999",
            role=UserRole.ADMIN,
        )
        db.add(admin)

        # === USUARIOS (Tenant 2) ===
        users_t2 = []
        user_list_t2 = [
            ("Ana Rodríguez", "ana@demo.com"),
            ("Pedro Martínez", "pedro@demo.com"),
            ("Grover Pinto", "grover@demo.com"),
            ("Luciana Suarez", "luciana@demo.com"),
        ]
        for i, (name, email) in enumerate(user_list_t2):
            u = User(
                tenant_id=t2.id, email=email,
                password_hash=hash_password("123456"),
                full_name=name, phone=f"7100000{i}", role=UserRole.CLIENT,
            )
            db.add(u)
            users_t2.append(u)
        db.flush()
        print(f"[OK] Usuarios creados: {len(users_t1) + len(users_t2)}")

        # === TALLERES (Tenant 1) ===
        workshops_t1 = []
        workshop_data_t1 = [
            ("Taller Automotriz Central", "taller1@demo.com", -17.7833, -63.1822, ["battery", "engine", "crash"]),
            ("Mecánica Rápida Sur", "taller2@demo.com", -17.8000, -63.1700, ["tire", "battery", "other"]),
            ("AutoService Premium", "taller3@demo.com", -17.7700, -63.1900, ["engine", "crash", "tire"]),
            ("Mecánica Integral El Chaco", "taller4@demo.com", -17.7910, -63.1620, ["battery", "tire", "engine"]),
            ("Taller ElectroAuto", "taller5@demo.com", -17.7610, -63.1810, ["battery", "other"]),
            ("Multiservicios Banzer", "taller6@demo.com", -17.7520, -63.1950, ["crash", "engine", "tire", "other"]),
        ]
        for name, email, lat, lng, specs in workshop_data_t1:
            w = Workshop(
                tenant_id=t1.id, name=name, email=email,
                password_hash=hash_password("123456"),
                phone="71234567", address=f"Av. Principal, Santa Cruz",
                latitude=lat, longitude=lng, capacity=5, specialties=specs,
            )
            db.add(w)
            workshops_t1.append(w)

        # === TALLERES (Tenant 2) ===
        workshops_t2 = []
        workshop_data_t2 = [
            ("Express Mecánica", "express1@demo.com", -17.7850, -63.1750, ["battery", "tire", "engine"]),
            ("TallerPro 24h", "express2@demo.com", -17.7950, -63.1850, ["crash", "engine", "other"]),
            ("Mecánica Veloz Equipetrol", "express3@demo.com", -17.7680, -63.1920, ["tire", "battery", "other"]),
            ("Doctor Auto", "express4@demo.com", -17.7890, -63.1680, ["engine", "crash", "battery"]),
        ]
        for name, email, lat, lng, specs in workshop_data_t2:
            w = Workshop(
                tenant_id=t2.id, name=name, email=email,
                password_hash=hash_password("123456"),
                phone="72234567", address=f"Zona Norte, Santa Cruz",
                latitude=lat, longitude=lng, capacity=4, specialties=specs,
            )
            db.add(w)
            workshops_t2.append(w)
        db.flush()
        print(f"[OK] Talleres creados: {len(workshops_t1) + len(workshops_t2)}")

        # === TÉCNICOS ===
        all_techs = []
        tech_names = [
            "Roberto Sánchez", "Fernando Vargas", "Miguel Quispe",
            "Diego Flores", "Oscar Mamani", "Luis Rojas",
            "Sergio Gutiérrez", "Andrés Montaño", "Carlos Villagómez",
            "Pedro Justiniano", "Hugo Salvatierra", "Mauricio Antelo",
            "Eduardo Suárez", "Jorge Melgar", "Marcelo Montero",
            "Fabián Prado", "Julio Céspedes", "René Justiniano"
        ]
        idx = 0
        for w in workshops_t1 + workshops_t2:
            # 3 técnicos por taller
            for j in range(3):
                t = Technician(
                    tenant_id=w.tenant_id, workshop_id=w.id,
                    name=tech_names[idx % len(tech_names)],
                    phone=f"7300{idx:04d}",
                    specialties=w.specialties[:2] if w.specialties else ["other"],
                    is_available=True,
                    latitude=w.latitude + random.uniform(-0.005, 0.005),
                    longitude=w.longitude + random.uniform(-0.005, 0.005),
                )
                db.add(t)
                all_techs.append(t)
                idx += 1
        db.flush()
        print(f"[OK] Técnicos creados: {len(all_techs)}")

        # === VEHÍCULOS ===
        vehicles = []
        vehicle_data = [
            ("Toyota", "Corolla", 2020, "Blanco", "SCZ-1234"),
            ("Hyundai", "Tucson", 2022, "Negro", "SCZ-5678"),
            ("Nissan", "Sentra", 2019, "Gris", "SCZ-9012"),
            ("Suzuki", "Swift", 2021, "Rojo", "CBB-3456"),
            ("Kia", "Sportage", 2023, "Azul", "CBB-7890"),
            ("Mitsubishi", "Lancer", 2018, "Plateado", "LPZ-1122"),
            ("Chevrolet", "Tracker", 2021, "Dorado", "LPZ-3344"),
            ("Ford", "Ranger", 2020, "Azul Marino", "SCZ-5566"),
            ("Honda", "Civic", 2022, "Blanco", "CBB-7788"),
            ("Mazda", "CX-5", 2021, "Rojo", "SCZ-9900"),
        ]
        all_users = users_t1 + users_t2
        for i, (brand, model, year, color, plate) in enumerate(vehicle_data):
            user = all_users[i % len(all_users)]
            v = Vehicle(
                tenant_id=user.tenant_id, user_id=user.id,
                brand=brand, model=model, year=year, color=color, license_plate=plate,
            )
            db.add(v)
            vehicles.append(v)
        db.flush()
        print(f"[OK] Vehículos creados: {len(vehicles)}")

        # === INCIDENTES HISTÓRICOS (para KPIs) ===
        incident_types = [IncidentType.BATTERY, IncidentType.TIRE, IncidentType.CRASH, IncidentType.ENGINE, IncidentType.OTHER]
        
        now = datetime.now(BOL_TZ)
        incident_count = 0

        # Generar incidentes para Tenant 1 (45 incidentes)
        for i in range(45):
            user = random.choice(users_t1)
            ws = random.choice(workshops_t1)
            inc_type = random.choice(incident_types)
            base_time = now - timedelta(days=random.randint(1, 45), hours=random.randint(0, 23))

            created = base_time
            searching = created + timedelta(minutes=random.randint(1, 3))
            assigned = searching + timedelta(minutes=random.randint(2, 15))
            en_route = assigned + timedelta(minutes=random.randint(1, 5))
            eta = random.randint(5, 30)
            attending = en_route + timedelta(minutes=random.randint(eta - 5, eta + 10))
            completed = attending + timedelta(minutes=random.randint(30, 120))

            is_cancelled = random.random() < 0.12
            final_status = IncidentStatus.CANCELLED if is_cancelled else IncidentStatus.COMPLETED

            # 35% requiere grúa (sobre todo accidentes y fallas de motor)
            requires_tow = (inc_type in [IncidentType.CRASH, IncidentType.ENGINE]) and (random.random() < 0.7)
            requires_tow = requires_tow or (random.random() < 0.2)

            inc = Incident(
                tenant_id=t1.id, user_id=user.id,
                vehicle_id=vehicles[i % len(vehicles)].id,
                workshop_id=ws.id,
                latitude=ws.latitude + random.uniform(-0.03, 0.03),
                longitude=ws.longitude + random.uniform(-0.03, 0.03),
                address=f"Calle {random.randint(1, 100)}, Zona {random.choice(['Norte', 'Sur', 'Este', 'Oeste', 'Centro'])}",
                description=f"Emergencia de tipo {inc_type.value} reportada. Se requiere asistencia en ruta.",
                incident_type=inc_type,
                priority=random.choice([IncidentPriority.LOW, IncidentPriority.MEDIUM, IncidentPriority.HIGH]),
                status=final_status,
                ai_summary=f"SITUACION: Emergencia de {inc_type.value}\nDIAGNOSTICO: Requiere asistencia inmediata.",
                ai_confidence=random.uniform(70, 99),
                ai_cost_estimate_min=random.randint(50, 200),
                ai_cost_estimate_max=random.randint(300, 1000),
                estimated_arrival_minutes=eta,
                final_cost=random.uniform(120, 850) if not is_cancelled else None,
                cancellation_fee=50.0 if is_cancelled and random.random() < 0.5 else None,
                requires_tow_truck=requires_tow,
                created_at=created.replace(tzinfo=None),
                searching_at=searching,
                assigned_at=assigned,
                en_route_at=en_route if not is_cancelled else None,
                attending_at=attending if not is_cancelled else None,
                completed_at=completed if not is_cancelled else None,
                cancelled_at=assigned + timedelta(minutes=5) if is_cancelled else None,
            )
            db.add(inc)
            incident_count += 1

        # Generar incidentes para Tenant 2 (25 incidentes)
        for i in range(25):
            user = random.choice(users_t2)
            ws = random.choice(workshops_t2)
            inc_type = random.choice(incident_types)
            base_time = now - timedelta(days=random.randint(1, 30), hours=random.randint(0, 23))

            created = base_time
            searching = created + timedelta(minutes=random.randint(1, 3))
            assigned = searching + timedelta(minutes=random.randint(2, 10))
            en_route = assigned + timedelta(minutes=random.randint(1, 5))
            eta = random.randint(5, 25)
            attending = en_route + timedelta(minutes=random.randint(eta - 3, eta + 5))
            completed = attending + timedelta(minutes=random.randint(20, 90))

            is_cancelled = random.random() < 0.1
            final_status = IncidentStatus.CANCELLED if is_cancelled else IncidentStatus.COMPLETED
            
            requires_tow = (inc_type in [IncidentType.CRASH, IncidentType.ENGINE]) and (random.random() < 0.6)

            inc = Incident(
                tenant_id=t2.id, user_id=user.id,
                vehicle_id=vehicles[(i + 5) % len(vehicles)].id,
                workshop_id=ws.id,
                latitude=ws.latitude + random.uniform(-0.03, 0.03),
                longitude=ws.longitude + random.uniform(-0.03, 0.03),
                address=f"Av. {random.randint(1, 80)}, Zona {random.choice(['Equipetrol', 'Plan 3000', 'Urbari', 'Las Palmas'])}",
                description=f"Reporte de {inc_type.value} en vía pública.",
                incident_type=inc_type,
                priority=random.choice([IncidentPriority.MEDIUM, IncidentPriority.HIGH]),
                status=final_status,
                ai_summary=f"Emergencia clasificada como {inc_type.value}",
                ai_confidence=random.uniform(75, 98),
                ai_cost_estimate_min=random.randint(80, 250),
                ai_cost_estimate_max=random.randint(400, 1200),
                estimated_arrival_minutes=eta,
                final_cost=random.uniform(150, 950) if not is_cancelled else None,
                requires_tow_truck=requires_tow,
                created_at=created.replace(tzinfo=None),
                searching_at=searching,
                assigned_at=assigned,
                en_route_at=en_route if not is_cancelled else None,
                attending_at=attending if not is_cancelled else None,
                completed_at=completed if not is_cancelled else None,
                cancelled_at=assigned + timedelta(minutes=3) if is_cancelled else None,
            )
            db.add(inc)
            incident_count += 1

        db.flush()
        print(f"[OK] Incidentes históricos creados: {incident_count}")

        # === SERVICE HISTORY para los incidentes ===
        all_incidents = db.query(Incident).all()
        history_count = 0
        for inc in all_incidents:
            states = [
                (IncidentStatus.PENDING, inc.created_at, "Incidente creado"),
                (IncidentStatus.SEARCHING, inc.searching_at, "Buscando talleres cercanos"),
                (IncidentStatus.ASSIGNED, inc.assigned_at, f"Asignado a taller {inc.workshop.name if inc.workshop else '#' + str(inc.workshop_id)}"),
            ]
            if inc.en_route_at:
                states.append((IncidentStatus.EN_ROUTE, inc.en_route_at, "Mecánico en camino"))
            if inc.attending_at:
                states.append((IncidentStatus.ATTENDING, inc.attending_at, "Mecánico atendiendo la emergencia"))
            if inc.completed_at:
                states.append((IncidentStatus.COMPLETED, inc.completed_at, "Servicio finalizado con éxito"))
            if inc.cancelled_at:
                states.append((IncidentStatus.CANCELLED, inc.cancelled_at, "Servicio cancelado por el usuario"))

            for status, ts, notes in states:
                if ts:
                    sh = ServiceHistory(
                        tenant_id=inc.tenant_id, incident_id=inc.id,
                        status=status.value, notes=notes, created_by="sistema",
                        created_at=ts.replace(tzinfo=None) if hasattr(ts, 'replace') else ts,
                    )
                    db.add(sh)
                    history_count += 1

        print(f"[OK] Historial de servicio creado: {history_count} registros")

        # === PAGOS para incidentes completados ===
        payment_count = 0
        for inc in all_incidents:
            if inc.status == IncidentStatus.COMPLETED and inc.final_cost:
                # Si requiere grúa, sumar un costo extra al pago final
                tow_cost = 0.0
                if inc.requires_tow_truck:
                    tow_cost = round(50.0 + (random.uniform(2.0, 15.0) * 8.0), 2)
                    inc.final_cost = round(inc.final_cost + tow_cost, 2)
                
                commission = inc.final_cost * 0.10
                p = Payment(
                    tenant_id=inc.tenant_id, incident_id=inc.id,
                    amount=round(inc.final_cost, 2),
                    commission_amount=round(commission, 2),
                    commission_percent=10.0,
                    payment_status=PaymentStatus.COMPLETED,
                    payment_method=random.choice([PaymentMethod.MOBILE_PAYMENT, PaymentMethod.CREDIT_CARD, PaymentMethod.PARALELA]),
                    paid_at=inc.completed_at,
                )
                db.add(p)
                payment_count += 1

        print(f"[OK] Pagos creados: {payment_count}")

        db.commit()
        print("\n[SUCCESS] Seed completado exitosamente con datos ricos y realistas!")
        print(f"   Tenants: 2")
        print(f"   Usuarios clientes: {len(users_t1) + len(users_t2)}")
        print(f"   Talleres mecánicos: {len(workshops_t1) + len(workshops_t2)}")
        print(f"   Técnicos de auxilio: {len(all_techs)}")
        print(f"   Vehículos registrados: {len(vehicles)}")
        print(f"   Incidentes registrados: {incident_count}")
        print(f"   Pagos procesados: {payment_count}")
        print(f"\nCredenciales demo:")
        print(f"   Super Admin: admin@demo.com / 123456")
        print(f"   Cliente T1: juan@demo.com / 123456")
        print(f"   Cliente T2: ana@demo.com / 123456")
        print(f"   Taller T1: taller1@demo.com / 123456")
        print(f"   Taller T2: express1@demo.com / 123456")

    except Exception as e:
        db.rollback()
        print(f"[ERROR] Error en seed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()


if __name__ == "__main__":
    seed()
