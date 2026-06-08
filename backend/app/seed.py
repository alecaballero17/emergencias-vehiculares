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
        print(f"✅ Tenants creados: {t1.name} (id={t1.id}), {t2.name} (id={t2.id})")

        # === USUARIOS (Tenant 1) ===
        users_t1 = []
        for i, (name, email) in enumerate([
            ("Juan Pérez", "juan@demo.com"),
            ("María García", "maria@demo.com"),
            ("Carlos López", "carlos@demo.com"),
        ]):
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
        for i, (name, email) in enumerate([
            ("Ana Rodríguez", "ana@demo.com"),
            ("Pedro Martínez", "pedro@demo.com"),
        ]):
            u = User(
                tenant_id=t2.id, email=email,
                password_hash=hash_password("123456"),
                full_name=name, phone=f"7100000{i}", role=UserRole.CLIENT,
            )
            db.add(u)
            users_t2.append(u)
        db.flush()
        print(f"✅ Usuarios creados: {len(users_t1) + len(users_t2)}")

        # === TALLERES (Tenant 1) ===
        workshops_t1 = []
        workshop_data_t1 = [
            ("Taller Automotriz Central", "taller1@demo.com", -17.7833, -63.1822, ["battery", "engine", "crash"]),
            ("Mecánica Rápida Sur", "taller2@demo.com", -17.8000, -63.1700, ["tire", "battery", "other"]),
            ("AutoService Premium", "taller3@demo.com", -17.7700, -63.1900, ["engine", "crash", "tire"]),
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
        print(f"✅ Talleres creados: {len(workshops_t1) + len(workshops_t2)}")

        # === TÉCNICOS ===
        all_techs = []
        tech_names = ["Roberto Sánchez", "Fernando Vargas", "Miguel Quispe",
                       "Diego Flores", "Oscar Mamani", "Luis Rojas",
                       "Sergio Gutiérrez", "Andrés Montaño"]
        idx = 0
        for w in workshops_t1 + workshops_t2:
            for j in range(2):
                t = Technician(
                    tenant_id=w.tenant_id, workshop_id=w.id,
                    name=tech_names[idx % len(tech_names)],
                    phone=f"7300{idx:04d}",
                    specialties=w.specialties[:2] if w.specialties else [],
                    is_available=True,
                    latitude=w.latitude + random.uniform(-0.005, 0.005),
                    longitude=w.longitude + random.uniform(-0.005, 0.005),
                )
                db.add(t)
                all_techs.append(t)
                idx += 1
        db.flush()
        print(f"✅ Técnicos creados: {len(all_techs)}")

        # === VEHÍCULOS ===
        vehicles = []
        vehicle_data = [
            ("Toyota", "Corolla", 2020, "Blanco", "SCZ-1234"),
            ("Hyundai", "Tucson", 2022, "Negro", "SCZ-5678"),
            ("Nissan", "Sentra", 2019, "Gris", "SCZ-9012"),
            ("Suzuki", "Swift", 2021, "Rojo", "CBB-3456"),
            ("Kia", "Sportage", 2023, "Azul", "CBB-7890"),
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
        print(f"✅ Vehículos creados: {len(vehicles)}")

        # === INCIDENTES HISTÓRICOS (para KPIs) ===
        incident_types = [IncidentType.BATTERY, IncidentType.TIRE, IncidentType.CRASH, IncidentType.ENGINE, IncidentType.OTHER]
        statuses_completed = [
            IncidentStatus.PENDING, IncidentStatus.SEARCHING, IncidentStatus.ASSIGNED,
            IncidentStatus.EN_ROUTE, IncidentStatus.ATTENDING, IncidentStatus.COMPLETED
        ]

        now = datetime.now(BOL_TZ)
        incident_count = 0

        # Generar incidentes para Tenant 1 (15 incidentes)
        for i in range(15):
            user = random.choice(users_t1)
            ws = random.choice(workshops_t1)
            inc_type = random.choice(incident_types)
            base_time = now - timedelta(days=random.randint(1, 30), hours=random.randint(0, 23))

            # Timestamps realistas de la máquina de estados
            created = base_time
            searching = created + timedelta(minutes=random.randint(1, 3))
            assigned = searching + timedelta(minutes=random.randint(2, 15))
            en_route = assigned + timedelta(minutes=random.randint(1, 5))
            eta = random.randint(5, 30)
            attending = en_route + timedelta(minutes=random.randint(eta - 5, eta + 10))
            completed = attending + timedelta(minutes=random.randint(30, 120))

            # Algunos cancelados
            is_cancelled = random.random() < 0.15
            final_status = IncidentStatus.CANCELLED if is_cancelled else IncidentStatus.COMPLETED

            inc = Incident(
                tenant_id=t1.id, user_id=user.id,
                vehicle_id=vehicles[i % len(vehicles)].id if i < len(vehicles) else None,
                workshop_id=ws.id,
                latitude=-17.78 + random.uniform(-0.05, 0.05),
                longitude=-63.18 + random.uniform(-0.05, 0.05),
                address=f"Calle {random.randint(1, 50)}, Zona {random.choice(['Norte', 'Sur', 'Este', 'Centro'])}",
                description=f"Emergencia de tipo {inc_type.value} reportada automáticamente",
                incident_type=inc_type,
                priority=random.choice([IncidentPriority.LOW, IncidentPriority.MEDIUM, IncidentPriority.HIGH]),
                status=final_status,
                ai_summary=f"🚨 SITUACIÓN: Emergencia de {inc_type.value}\n🛠️ DIAGNÓSTICO: Requiere atención",
                ai_confidence=random.uniform(70, 99),
                ai_cost_estimate_min=random.randint(50, 200),
                ai_cost_estimate_max=random.randint(300, 1000),
                estimated_arrival_minutes=eta,
                final_cost=random.uniform(100, 800) if not is_cancelled else None,
                cancellation_fee=50.0 if is_cancelled and random.random() < 0.5 else None,
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

        # Generar incidentes para Tenant 2 (10 incidentes)
        for i in range(10):
            user = random.choice(users_t2)
            ws = random.choice(workshops_t2)
            inc_type = random.choice(incident_types)
            base_time = now - timedelta(days=random.randint(1, 20), hours=random.randint(0, 23))

            created = base_time
            searching = created + timedelta(minutes=random.randint(1, 3))
            assigned = searching + timedelta(minutes=random.randint(2, 10))
            en_route = assigned + timedelta(minutes=random.randint(1, 5))
            eta = random.randint(5, 25)
            attending = en_route + timedelta(minutes=random.randint(eta - 3, eta + 5))
            completed = attending + timedelta(minutes=random.randint(20, 90))

            is_cancelled = random.random() < 0.1
            final_status = IncidentStatus.CANCELLED if is_cancelled else IncidentStatus.COMPLETED

            inc = Incident(
                tenant_id=t2.id, user_id=user.id,
                workshop_id=ws.id,
                latitude=-17.79 + random.uniform(-0.04, 0.04),
                longitude=-63.17 + random.uniform(-0.04, 0.04),
                address=f"Av. {random.randint(1, 30)}, Zona {random.choice(['Equipetrol', 'Plan 3000', 'Urbari'])}",
                description=f"Reporte de {inc_type.value}",
                incident_type=inc_type,
                priority=random.choice([IncidentPriority.MEDIUM, IncidentPriority.HIGH]),
                status=final_status,
                ai_summary=f"🚨 Emergencia clasificada como {inc_type.value}",
                ai_confidence=random.uniform(75, 98),
                ai_cost_estimate_min=random.randint(80, 250),
                ai_cost_estimate_max=random.randint(400, 1200),
                estimated_arrival_minutes=eta,
                final_cost=random.uniform(150, 900) if not is_cancelled else None,
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
        print(f"✅ Incidentes históricos creados: {incident_count}")

        # === SERVICE HISTORY para los incidentes ===
        all_incidents = db.query(Incident).all()
        history_count = 0
        for inc in all_incidents:
            states = [
                (IncidentStatus.PENDING, inc.created_at, "Incidente creado"),
                (IncidentStatus.SEARCHING, inc.searching_at, "Buscando talleres"),
                (IncidentStatus.ASSIGNED, inc.assigned_at, f"Asignado a taller #{inc.workshop_id}"),
            ]
            if inc.en_route_at:
                states.append((IncidentStatus.EN_ROUTE, inc.en_route_at, "Mecánico en camino"))
            if inc.attending_at:
                states.append((IncidentStatus.ATTENDING, inc.attending_at, "Mecánico atendiendo"))
            if inc.completed_at:
                states.append((IncidentStatus.COMPLETED, inc.completed_at, "Servicio completado"))
            if inc.cancelled_at:
                states.append((IncidentStatus.CANCELLED, inc.cancelled_at, "Cancelado"))

            for status, ts, notes in states:
                if ts:
                    sh = ServiceHistory(
                        tenant_id=inc.tenant_id, incident_id=inc.id,
                        status=status.value, notes=notes, created_by="sistema",
                        created_at=ts.replace(tzinfo=None) if hasattr(ts, 'replace') else ts,
                    )
                    db.add(sh)
                    history_count += 1

        print(f"✅ Historial de servicio creado: {history_count} registros")

        # === PAGOS para incidentes completados ===
        payment_count = 0
        for inc in all_incidents:
            if inc.status == IncidentStatus.COMPLETED and inc.final_cost:
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

        print(f"✅ Pagos creados: {payment_count}")

        db.commit()
        print("\n🎉 ¡Seed completado exitosamente!")
        print(f"   Tenants: 2")
        print(f"   Usuarios: {len(users_t1) + len(users_t2)}")
        print(f"   Talleres: {len(workshops_t1) + len(workshops_t2)}")
        print(f"   Técnicos: {len(all_techs)}")
        print(f"   Vehículos: {len(vehicles)}")
        print(f"   Incidentes: {incident_count}")
        print(f"\n📧 Credenciales demo:")
        print(f"   Cliente T1: juan@demo.com / 123456")
        print(f"   Cliente T2: ana@demo.com / 123456")
        print(f"   Taller T1: taller1@demo.com / 123456")
        print(f"   Taller T2: express1@demo.com / 123456")

    except Exception as e:
        db.rollback()
        print(f"❌ Error en seed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()


if __name__ == "__main__":
    seed()
