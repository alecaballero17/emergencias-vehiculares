-- =====================================================
-- SCRIPT DE ESTRUCTURA Y DATOS DE LA BASE DE DATOS
-- =====================================================

-- Desactivar restricciones de integridad
SET session_replication_role = 'replica';

-- === ESTRUCTURA DE TABLAS (DDL) ===

-- Estructura de la tabla: tenants
CREATE TABLE tenants (
	id SERIAL NOT NULL, 
	name VARCHAR(255) NOT NULL, 
	slug VARCHAR(100) NOT NULL, 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id)
);

-- Estructura de la tabla: users
CREATE TABLE users (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	email VARCHAR(255) NOT NULL, 
	password_hash VARCHAR(255) NOT NULL, 
	full_name VARCHAR(255) NOT NULL, 
	phone VARCHAR(20), 
	role userrole NOT NULL, 
	is_active BOOLEAN, 
	firebase_token VARCHAR(500), 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);

-- Estructura de la tabla: workshops
CREATE TABLE workshops (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	name VARCHAR(255) NOT NULL, 
	email VARCHAR(255) NOT NULL, 
	password_hash VARCHAR(255) NOT NULL, 
	phone VARCHAR(20), 
	address VARCHAR(500), 
	latitude FLOAT, 
	longitude FLOAT, 
	is_active BOOLEAN, 
	capacity INTEGER, 
	specialties JSON, 
	firebase_token VARCHAR(500), 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);

-- Estructura de la tabla: notifications
CREATE TABLE notifications (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	user_id INTEGER, 
	workshop_id INTEGER, 
	title VARCHAR(255) NOT NULL, 
	message TEXT NOT NULL, 
	notification_type VARCHAR(50) NOT NULL, 
	is_read BOOLEAN, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(user_id) REFERENCES users (id), 
	FOREIGN KEY(workshop_id) REFERENCES workshops (id)
);

-- Estructura de la tabla: technicians
CREATE TABLE technicians (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	workshop_id INTEGER NOT NULL, 
	name VARCHAR(255) NOT NULL, 
	phone VARCHAR(20), 
	specialties JSON, 
	is_available BOOLEAN, 
	latitude FLOAT, 
	longitude FLOAT, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(workshop_id) REFERENCES workshops (id) ON DELETE CASCADE
);

-- Estructura de la tabla: vehicles
CREATE TABLE vehicles (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	user_id INTEGER NOT NULL, 
	brand VARCHAR(100) NOT NULL, 
	model VARCHAR(100) NOT NULL, 
	year INTEGER NOT NULL, 
	color VARCHAR(50), 
	license_plate VARCHAR(20) NOT NULL, 
	vin VARCHAR(50), 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(user_id) REFERENCES users (id) ON DELETE CASCADE, 
	UNIQUE (license_plate)
);

-- Estructura de la tabla: incidents
CREATE TABLE incidents (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	user_id INTEGER NOT NULL, 
	vehicle_id INTEGER, 
	workshop_id INTEGER, 
	technician_id INTEGER, 
	latitude FLOAT NOT NULL, 
	longitude FLOAT NOT NULL, 
	address TEXT, 
	description TEXT, 
	audio_transcription TEXT, 
	incident_type incidenttype, 
	priority incidentpriority, 
	status incidentstatus, 
	ai_summary TEXT, 
	ai_classification TEXT, 
	ai_confidence FLOAT, 
	ai_cost_estimate_min FLOAT, 
	ai_cost_estimate_max FLOAT, 
	estimated_arrival_minutes INTEGER, 
	final_cost FLOAT, 
	cancellation_fee FLOAT, 
	local_uuid VARCHAR(100), 
	created_at TIMESTAMP WITHOUT TIME ZONE, 
	updated_at TIMESTAMP WITHOUT TIME ZONE, 
	searching_at TIMESTAMP WITH TIME ZONE, 
	assigned_at TIMESTAMP WITH TIME ZONE, 
	en_route_at TIMESTAMP WITH TIME ZONE, 
	attending_at TIMESTAMP WITH TIME ZONE, 
	completed_at TIMESTAMP WITH TIME ZONE, 
	cancelled_at TIMESTAMP WITH TIME ZONE, 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(user_id) REFERENCES users (id), 
	FOREIGN KEY(vehicle_id) REFERENCES vehicles (id), 
	FOREIGN KEY(workshop_id) REFERENCES workshops (id), 
	FOREIGN KEY(technician_id) REFERENCES technicians (id)
);

-- Estructura de la tabla: evidences
CREATE TABLE evidences (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	incident_id INTEGER NOT NULL, 
	evidence_type evidencetype NOT NULL, 
	file_url VARCHAR(500), 
	content TEXT, 
	ai_analysis TEXT, 
	created_at TIMESTAMP WITHOUT TIME ZONE, 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(incident_id) REFERENCES incidents (id) ON DELETE CASCADE
);

-- Estructura de la tabla: payments
CREATE TABLE payments (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	incident_id INTEGER NOT NULL, 
	amount FLOAT NOT NULL, 
	commission_amount FLOAT NOT NULL, 
	commission_percent FLOAT, 
	cancellation_fee FLOAT, 
	payment_status paymentstatus, 
	payment_method paymentmethod, 
	payment_intent_id VARCHAR(255), 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	paid_at TIMESTAMP WITH TIME ZONE, 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (incident_id), 
	FOREIGN KEY(incident_id) REFERENCES incidents (id) ON DELETE CASCADE
);

-- Estructura de la tabla: quotations
CREATE TABLE quotations (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	incident_id INTEGER NOT NULL, 
	workshop_id INTEGER NOT NULL, 
	amount FLOAT NOT NULL, 
	estimated_repair_hours FLOAT, 
	description TEXT, 
	status quotationstatus, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now(), 
	accepted_at TIMESTAMP WITH TIME ZONE, 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(incident_id) REFERENCES incidents (id) ON DELETE CASCADE, 
	FOREIGN KEY(workshop_id) REFERENCES workshops (id)
);

-- Estructura de la tabla: service_history
CREATE TABLE service_history (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	incident_id INTEGER NOT NULL, 
	status VARCHAR(50) NOT NULL, 
	notes TEXT, 
	created_by VARCHAR(100), 
	created_at TIMESTAMP WITHOUT TIME ZONE, 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(incident_id) REFERENCES incidents (id) ON DELETE CASCADE
);

-- === DATOS DE LAS TABLAS (DML) ===

-- Datos de la tabla: tenants
INSERT INTO tenants (id, name, slug, is_active, created_at) VALUES (1, 'Auxilio Norte', 'auxilio-norte', TRUE, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO tenants (id, name, slug, is_active, created_at) VALUES (2, 'Mecánicos Express', 'mecanicos-express', TRUE, '2026-05-25T11:06:42.519276-04:00');

-- Datos de la tabla: users
INSERT INTO users (id, tenant_id, email, password_hash, full_name, phone, role, is_active, firebase_token, created_at, updated_at) VALUES (1, 1, 'juan@demo.com', '$2b$12$LjQN2WYjKCSOK7rSY9kDnuNYNdBxC2.13GVWyH5vtO7uggT7vgrXu', 'Juan Pérez', '70000000', 'client', TRUE, NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-25T11:06:42.519276-04:00');
INSERT INTO users (id, tenant_id, email, password_hash, full_name, phone, role, is_active, firebase_token, created_at, updated_at) VALUES (2, 1, 'maria@demo.com', '$2b$12$xmzZ0P37GMSYBFtKQZCV7e7bZ2n06Av2u8WFhMRALBcI4/DHFy0M.', 'María García', '70000001', 'client', TRUE, NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-25T11:06:42.519276-04:00');
INSERT INTO users (id, tenant_id, email, password_hash, full_name, phone, role, is_active, firebase_token, created_at, updated_at) VALUES (3, 1, 'carlos@demo.com', '$2b$12$g39Qg14/u3Gt.djgPm8gK.TgI6MltD8yx2dR7V1tYZzDmGzxYOUa2', 'Carlos López', '70000002', 'client', TRUE, NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-25T11:06:42.519276-04:00');
INSERT INTO users (id, tenant_id, email, password_hash, full_name, phone, role, is_active, firebase_token, created_at, updated_at) VALUES (4, 2, 'ana@demo.com', '$2b$12$RGqaZklSERZj2j3Ilbm.Y.Z4WHUYx1ASUYEipRRyj357W/7YVNb2m', 'Ana Rodríguez', '71000000', 'client', TRUE, NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-25T11:06:42.519276-04:00');
INSERT INTO users (id, tenant_id, email, password_hash, full_name, phone, role, is_active, firebase_token, created_at, updated_at) VALUES (5, 2, 'pedro@demo.com', '$2b$12$etJGUQP8OdR/aMDGPx/Cf.uYkIugk2YE0S4x/UNeOT01qheRQb/s6', 'Pedro Martínez', '71000001', 'client', TRUE, NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-25T11:06:42.519276-04:00');

-- Datos de la tabla: workshops
INSERT INTO workshops (id, tenant_id, name, email, password_hash, phone, address, latitude, longitude, is_active, capacity, specialties, firebase_token, created_at, updated_at) VALUES (1, 1, 'Taller Automotriz Central', 'taller1@demo.com', '$2b$12$S1kLT9hyoWVOSv/XmIZ3FejyGmprl8PufpVNIO7jSH7/4YOVPbRZW', '71234567', 'Av. Principal, Santa Cruz', -17.7833, -63.1822, TRUE, 5, '[''battery'', ''engine'', ''crash'']', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-25T11:06:42.519276-04:00');
INSERT INTO workshops (id, tenant_id, name, email, password_hash, phone, address, latitude, longitude, is_active, capacity, specialties, firebase_token, created_at, updated_at) VALUES (2, 1, 'Mecánica Rápida Sur', 'taller2@demo.com', '$2b$12$BJtrwD0Ckjco.EGF3/JWi.ld4N8c02QvDe7WW.KaBmCFAAGUz5ig6', '71234567', 'Av. Principal, Santa Cruz', -17.8, -63.17, TRUE, 5, '[''tire'', ''battery'', ''other'']', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-25T11:06:42.519276-04:00');
INSERT INTO workshops (id, tenant_id, name, email, password_hash, phone, address, latitude, longitude, is_active, capacity, specialties, firebase_token, created_at, updated_at) VALUES (3, 1, 'AutoService Premium', 'taller3@demo.com', '$2b$12$IHjC4EpVLpO08rLG3Snc/.qWKIRCCt0cFG93gAB3DVxz0LInGw1zC', '71234567', 'Av. Principal, Santa Cruz', -17.77, -63.19, TRUE, 5, '[''engine'', ''crash'', ''tire'']', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-25T11:06:42.519276-04:00');
INSERT INTO workshops (id, tenant_id, name, email, password_hash, phone, address, latitude, longitude, is_active, capacity, specialties, firebase_token, created_at, updated_at) VALUES (4, 2, 'Express Mecánica', 'express1@demo.com', '$2b$12$IGgRTo5NpNPW9tkBom1rfuyG5lesgYzQEpnPDXzvJfXhyhPEz1iRK', '72234567', 'Zona Norte, Santa Cruz', -17.785, -63.175, TRUE, 4, '[''battery'', ''tire'', ''engine'']', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-25T11:06:42.519276-04:00');
INSERT INTO workshops (id, tenant_id, name, email, password_hash, phone, address, latitude, longitude, is_active, capacity, specialties, firebase_token, created_at, updated_at) VALUES (5, 2, 'TallerPro 24h', 'express2@demo.com', '$2b$12$S0rq7/AZh0ftXPxWX1aoDOgxujmVhLKb2K2ecscPw358MGzSMYG7C', '72234567', 'Zona Norte, Santa Cruz', -17.795, -63.185, TRUE, 4, '[''crash'', ''engine'', ''other'']', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-25T11:06:42.519276-04:00');

-- Datos de la tabla: notifications
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (1, 1, 1, NULL, '🔧 Tu solicitud fue aceptada', 'El taller Taller Automotriz Central ha aceptado tu emergencia. ETA: 5 min', 'incident_accepted', FALSE, '2026-06-01T19:54:35.346551-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (2, 1, 1, NULL, '🚗 Auxilio en camino', 'El mecánico del taller Taller Automotriz Central está en camino. ETA: 5 min', 'incident_en_route', FALSE, '2026-06-01T19:54:38.325624-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (3, 1, 1, NULL, '🔧 Mecánico ha llegado', 'El mecánico del taller Taller Automotriz Central está atendiendo tu vehículo', 'incident_attending', FALSE, '2026-06-01T19:55:01.457537-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (4, 1, 1, NULL, '🔧 Tu solicitud fue aceptada', 'El taller Taller Automotriz Central ha aceptado tu emergencia. ETA: 5 min', 'incident_accepted', FALSE, '2026-06-01T19:55:11.956546-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (5, 1, 1, NULL, '🚗 Auxilio en camino', 'El mecánico del taller Taller Automotriz Central está en camino. ETA: 5 min', 'incident_en_route', FALSE, '2026-06-01T19:56:22.245269-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (6, 1, 1, NULL, '🔧 Mecánico ha llegado', 'El mecánico del taller Taller Automotriz Central está atendiendo tu vehículo', 'incident_attending', FALSE, '2026-06-01T20:39:25.204823-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (7, 1, 1, NULL, '🔧 Tu solicitud fue aceptada', 'El taller Taller Automotriz Central ha aceptado tu emergencia. ETA: 5 min', 'incident_accepted', FALSE, '2026-06-01T20:39:58.149581-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (8, 1, 1, NULL, '🚗 Auxilio en camino', 'El mecánico del taller Taller Automotriz Central está en camino. ETA: 5 min', 'incident_en_route', FALSE, '2026-06-01T20:39:59.286034-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (9, 1, 1, NULL, '✅ Servicio completado', 'El taller Taller Automotriz Central ha completado el servicio. Costo: Bs. 100.0', 'incident_completed', FALSE, '2026-06-01T20:41:39.850049-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (10, 1, 1, NULL, '🔧 Tu solicitud fue aceptada', 'El taller Taller Automotriz Central ha aceptado tu emergencia. ETA: 5 min', 'incident_accepted', FALSE, '2026-06-06T22:01:38.924709-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (11, 1, 1, NULL, '🚗 Auxilio en camino', 'El mecánico del taller Taller Automotriz Central está en camino. ETA: 5 min', 'incident_en_route', FALSE, '2026-06-06T22:01:48.105133-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (12, 1, 1, NULL, '🔧 Mecánico ha llegado', 'El mecánico del taller Taller Automotriz Central está atendiendo tu vehículo', 'incident_attending', FALSE, '2026-06-06T22:09:03.947733-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (13, 1, 1, NULL, '✅ Servicio completado', 'El taller Taller Automotriz Central ha completado el servicio. Costo: Bs. 100.0', 'incident_completed', FALSE, '2026-06-06T22:09:20.139687-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (14, 1, 1, NULL, '💰 Nueva cotización recibida', 'El taller Taller Automotriz Central cotizó Bs. 300.0', 'quotation_received', FALSE, '2026-06-06T22:10:24.243862-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (15, 1, 1, NULL, '🔧 Tu solicitud fue aceptada', 'El taller Taller Automotriz Central ha aceptado tu emergencia. ETA: 5 min', 'incident_accepted', FALSE, '2026-06-06T22:10:36.919997-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (16, 1, 1, NULL, '🚗 Auxilio en camino', 'El mecánico del taller Taller Automotriz Central está en camino. ETA: 5 min', 'incident_en_route', FALSE, '2026-06-06T22:10:47.122245-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (17, 1, 1, NULL, '🔧 Mecánico ha llegado', 'El mecánico del taller Taller Automotriz Central está atendiendo tu vehículo', 'incident_attending', FALSE, '2026-06-06T22:42:57.314986-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (18, 1, 1, NULL, '✅ Servicio completado', 'El taller Taller Automotriz Central ha completado el servicio. Costo: Bs. 100.0', 'incident_completed', FALSE, '2026-06-06T22:43:06.938542-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (19, 1, 1, NULL, '💰 Nueva cotización recibida', 'El taller Taller Automotriz Central cotizó Bs. 100.0', 'quotation_received', FALSE, '2026-06-06T22:56:58.416770-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (20, 1, 1, NULL, '🔧 Tu solicitud fue aceptada', 'El taller Taller Automotriz Central ha aceptado tu emergencia. ETA: 5 min', 'incident_accepted', FALSE, '2026-06-06T22:57:16.852346-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (21, 1, 1, NULL, '🚗 Auxilio en camino', 'El mecánico del taller Taller Automotriz Central está en camino. ETA: 5 min', 'incident_en_route', FALSE, '2026-06-06T22:57:19.421129-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (22, 1, 1, NULL, '🔧 Mecánico ha llegado', 'El mecánico del taller Taller Automotriz Central está atendiendo tu vehículo', 'incident_attending', FALSE, '2026-06-06T22:57:48.323182-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (23, 1, 1, NULL, '✅ Servicio completado', 'El taller Taller Automotriz Central ha completado el servicio. Costo: Bs. 100.0', 'incident_completed', FALSE, '2026-06-06T22:57:56.501859-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (24, 1, 1, NULL, '💰 Nueva cotización recibida', 'El taller Taller Automotriz Central cotizó Bs. 50.0', 'quotation_received', FALSE, '2026-06-06T22:58:55.425891-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (25, 1, NULL, 1, '🎉 ¡Cotización aceptada!', 'Tu cotización de Bs. 50.0 fue aceptada para el incidente #32', 'quotation_accepted', FALSE, '2026-06-06T22:59:10.092836-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (26, 1, 1, NULL, '🚗 Auxilio en camino', 'El mecánico del taller Taller Automotriz Central está en camino. ETA: None min', 'incident_en_route', FALSE, '2026-06-06T22:59:22.388579-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (27, 1, 1, NULL, '🔧 Mecánico ha llegado', 'El mecánico del taller Taller Automotriz Central está atendiendo tu vehículo', 'incident_attending', FALSE, '2026-06-06T22:59:36.189913-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (28, 1, 1, NULL, '✅ Servicio completado', 'El taller Taller Automotriz Central ha completado el servicio. Costo: Bs. 200.0', 'incident_completed', FALSE, '2026-06-06T23:06:50.602540-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (29, 1, 1, NULL, '💰 Nueva cotización recibida', 'El taller Taller Automotriz Central cotizó Bs. 200.0', 'quotation_received', FALSE, '2026-06-06T23:07:43.631160-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (30, 1, NULL, 1, '🎉 ¡Cotización aceptada!', 'Tu cotización de Bs. 200.0 fue aceptada para el incidente #33', 'quotation_accepted', FALSE, '2026-06-06T23:07:57.075123-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (31, 1, 1, NULL, '🚗 Auxilio en camino', 'El mecánico del taller Taller Automotriz Central está en camino. ETA: None min', 'incident_en_route', FALSE, '2026-06-06T23:11:18.440331-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (32, 1, 1, NULL, '🔧 Mecánico ha llegado', 'El mecánico del taller Taller Automotriz Central está atendiendo tu vehículo', 'incident_attending', FALSE, '2026-06-06T23:14:19.651092-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (33, 1, 1, NULL, '✅ Servicio completado', 'El taller Taller Automotriz Central ha completado el servicio. Costo: Bs. 500.0', 'incident_completed', FALSE, '2026-06-06T23:14:28.417145-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (34, 1, 1, NULL, '🔧 Tu solicitud fue aceptada', 'El taller Taller Automotriz Central ha aceptado tu emergencia. ETA: 5 min', 'incident_accepted', FALSE, '2026-06-06T23:37:15.376915-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (35, 1, 1, NULL, '🚗 Auxilio en camino', 'El mecánico del taller Taller Automotriz Central está en camino. ETA: 5 min', 'incident_en_route', FALSE, '2026-06-06T23:37:30.853812-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (36, 1, 1, NULL, '🔧 Mecánico ha llegado', 'El mecánico del taller Taller Automotriz Central está atendiendo tu vehículo', 'incident_attending', FALSE, '2026-06-06T23:37:45.121698-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (37, 1, 1, NULL, '✅ Servicio completado', 'El taller Taller Automotriz Central ha completado el servicio. Costo: Bs. 500.0', 'incident_completed', FALSE, '2026-06-06T23:37:54.801293-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (38, 1, 1, NULL, '🔧 Tu solicitud fue aceptada', 'El taller Taller Automotriz Central ha aceptado tu emergencia. ETA: 5 min', 'incident_accepted', FALSE, '2026-06-06T23:54:34.906393-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (39, 1, 1, NULL, '🚗 Auxilio en camino', 'El mecánico del taller Taller Automotriz Central está en camino. ETA: 5 min', 'incident_en_route', FALSE, '2026-06-06T23:54:36.365320-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (40, 1, 1, NULL, '🔧 Mecánico ha llegado', 'El mecánico del taller Taller Automotriz Central está atendiendo tu vehículo', 'incident_attending', FALSE, '2026-06-06T23:54:46.971084-04:00');
INSERT INTO notifications (id, tenant_id, user_id, workshop_id, title, message, notification_type, is_read, created_at) VALUES (41, 1, 1, NULL, '✅ Servicio completado', 'El taller Taller Automotriz Central ha completado el servicio. Costo: Bs. 100.0', 'incident_completed', FALSE, '2026-06-06T23:54:53.938571-04:00');

-- Datos de la tabla: technicians
INSERT INTO technicians (id, tenant_id, workshop_id, name, phone, specialties, is_available, latitude, longitude, created_at) VALUES (1, 1, 1, 'Roberto Sánchez', '73000000', '[''battery'', ''engine'']', TRUE, -17.785434951080003, -63.18419001468608, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO technicians (id, tenant_id, workshop_id, name, phone, specialties, is_available, latitude, longitude, created_at) VALUES (2, 1, 1, 'Fernando Vargas', '73000001', '[''battery'', ''engine'']', TRUE, -17.778741113075856, -63.18045168617082, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO technicians (id, tenant_id, workshop_id, name, phone, specialties, is_available, latitude, longitude, created_at) VALUES (3, 1, 2, 'Miguel Quispe', '73000002', '[''tire'', ''battery'']', TRUE, -17.80316019487891, -63.17349829196068, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO technicians (id, tenant_id, workshop_id, name, phone, specialties, is_available, latitude, longitude, created_at) VALUES (4, 1, 2, 'Diego Flores', '73000003', '[''tire'', ''battery'']', TRUE, -17.80442155595526, -63.17203515155895, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO technicians (id, tenant_id, workshop_id, name, phone, specialties, is_available, latitude, longitude, created_at) VALUES (5, 1, 3, 'Oscar Mamani', '73000004', '[''engine'', ''crash'']', TRUE, -17.77121635599573, -63.19334645733165, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO technicians (id, tenant_id, workshop_id, name, phone, specialties, is_available, latitude, longitude, created_at) VALUES (6, 1, 3, 'Luis Rojas', '73000005', '[''engine'', ''crash'']', TRUE, -17.770881500593287, -63.19019241378016, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO technicians (id, tenant_id, workshop_id, name, phone, specialties, is_available, latitude, longitude, created_at) VALUES (7, 2, 4, 'Sergio Gutiérrez', '73000006', '[''battery'', ''tire'']', TRUE, -17.783192560685965, -63.17435668646588, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO technicians (id, tenant_id, workshop_id, name, phone, specialties, is_available, latitude, longitude, created_at) VALUES (8, 2, 4, 'Andrés Montaño', '73000007', '[''battery'', ''tire'']', TRUE, -17.787195111006948, -63.1730485696102, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO technicians (id, tenant_id, workshop_id, name, phone, specialties, is_available, latitude, longitude, created_at) VALUES (9, 2, 5, 'Roberto Sánchez', '73000008', '[''crash'', ''engine'']', TRUE, -17.79652400765953, -63.185286204267086, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO technicians (id, tenant_id, workshop_id, name, phone, specialties, is_available, latitude, longitude, created_at) VALUES (10, 2, 5, 'Fernando Vargas', '73000009', '[''crash'', ''engine'']', TRUE, -17.79100933449393, -63.18388923616929, '2026-05-25T11:06:42.519276-04:00');

-- Datos de la tabla: vehicles
INSERT INTO vehicles (id, tenant_id, user_id, brand, model, year, color, license_plate, vin, created_at) VALUES (1, 1, 1, 'Toyota', 'Corolla', 2020, 'Blanco', 'SCZ-1234', NULL, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO vehicles (id, tenant_id, user_id, brand, model, year, color, license_plate, vin, created_at) VALUES (2, 1, 2, 'Hyundai', 'Tucson', 2022, 'Negro', 'SCZ-5678', NULL, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO vehicles (id, tenant_id, user_id, brand, model, year, color, license_plate, vin, created_at) VALUES (3, 1, 3, 'Nissan', 'Sentra', 2019, 'Gris', 'SCZ-9012', NULL, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO vehicles (id, tenant_id, user_id, brand, model, year, color, license_plate, vin, created_at) VALUES (4, 2, 4, 'Suzuki', 'Swift', 2021, 'Rojo', 'CBB-3456', NULL, '2026-05-25T11:06:42.519276-04:00');
INSERT INTO vehicles (id, tenant_id, user_id, brand, model, year, color, license_plate, vin, created_at) VALUES (5, 2, 5, 'Kia', 'Sportage', 2023, 'Azul', 'CBB-7890', NULL, '2026-05-25T11:06:42.519276-04:00');

-- Datos de la tabla: incidents
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (1, 1, 2, 1, 3, NULL, -17.73514323873795, -63.22639665148303, 'Calle 49, Zona Este', 'Emergencia de tipo battery reportada automáticamente', NULL, 'battery', 'low', 'finalizado', '🚨 SITUACIÓN: Emergencia de battery
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 78.5035780239468, 197.0, 955.0, 12, 683.4621648104087, NULL, NULL, '2026-05-12T19:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-12T19:07:47.697437-04:00', '2026-05-12T19:15:47.697437-04:00', '2026-05-12T19:17:47.697437-04:00', '2026-05-12T19:34:47.697437-04:00', '2026-05-12T21:02:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (2, 1, 3, 2, 1, NULL, -17.78396098275666, -63.22139126650209, 'Calle 27, Zona Este', 'Emergencia de tipo engine reportada automáticamente', NULL, 'engine', 'low', 'finalizado', '🚨 SITUACIÓN: Emergencia de engine
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 84.53430703757805, 93.0, 884.0, 17, 383.79520668091175, NULL, NULL, '2026-05-01T08:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-01T08:09:47.697437-04:00', '2026-05-01T08:24:47.697437-04:00', '2026-05-01T08:29:47.697437-04:00', '2026-05-01T08:46:47.697437-04:00', '2026-05-01T10:25:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (3, 1, 3, 3, 1, NULL, -17.741546617089252, -63.21588438165934, 'Calle 4, Zona Centro', 'Emergencia de tipo tire reportada automáticamente', NULL, 'tire', 'low', 'finalizado', '🚨 SITUACIÓN: Emergencia de tire
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 86.01867133630682, 70.0, 351.0, 9, 584.8038036505081, NULL, NULL, '2026-05-12T01:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-12T01:07:47.697437-04:00', '2026-05-12T01:09:47.697437-04:00', '2026-05-12T01:13:47.697437-04:00', '2026-05-12T01:27:47.697437-04:00', '2026-05-12T03:26:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (4, 1, 3, 4, 1, NULL, -17.806148345785296, -63.1362550381852, 'Calle 14, Zona Este', 'Emergencia de tipo tire reportada automáticamente', NULL, 'tire', 'medium', 'cancelado', '🚨 SITUACIÓN: Emergencia de tire
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 93.23004840820059, 187.0, 504.0, 17, NULL, 50.0, NULL, '2026-05-17T01:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-17T01:07:47.697437-04:00', '2026-05-17T01:09:47.697437-04:00', NULL, NULL, NULL, '2026-05-17T01:14:47.697437-04:00');
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (5, 1, 2, 5, 1, NULL, -17.74042704286902, -63.14568215043065, 'Calle 18, Zona Sur', 'Emergencia de tipo tire reportada automáticamente', NULL, 'tire', 'high', 'finalizado', '🚨 SITUACIÓN: Emergencia de tire
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 76.05604791713168, 107.0, 381.0, 15, 482.57307151133523, NULL, NULL, '2026-05-17T10:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-17T10:09:47.697437-04:00', '2026-05-17T10:14:47.697437-04:00', '2026-05-17T10:15:47.697437-04:00', '2026-05-17T10:40:47.697437-04:00', '2026-05-17T12:36:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (6, 1, 1, NULL, 3, NULL, -17.77630469349617, -63.17633454707262, 'Calle 25, Zona Norte', 'Emergencia de tipo engine reportada automáticamente', NULL, 'engine', 'low', 'finalizado', '🚨 SITUACIÓN: Emergencia de engine
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 96.53915233086593, 134.0, 570.0, 9, 291.1374241158883, NULL, NULL, '2026-05-19T03:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-19T03:08:47.697437-04:00', '2026-05-19T03:21:47.697437-04:00', '2026-05-19T03:22:47.697437-04:00', '2026-05-19T03:27:47.697437-04:00', '2026-05-19T04:24:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (7, 1, 1, NULL, 3, NULL, -17.733696964627402, -63.18889691918347, 'Calle 17, Zona Norte', 'Emergencia de tipo battery reportada automáticamente', NULL, 'battery', 'low', 'finalizado', '🚨 SITUACIÓN: Emergencia de battery
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 87.16593869333522, 144.0, 800.0, 29, 244.56447948424548, NULL, NULL, '2026-05-03T10:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-03T10:08:47.697437-04:00', '2026-05-03T10:13:47.697437-04:00', '2026-05-03T10:15:47.697437-04:00', '2026-05-03T10:51:47.697437-04:00', '2026-05-03T12:23:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (8, 1, 1, NULL, 3, NULL, -17.75899691365937, -63.16317968448901, 'Calle 41, Zona Este', 'Emergencia de tipo other reportada automáticamente', NULL, 'other', 'high', 'cancelado', '🚨 SITUACIÓN: Emergencia de other
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 93.71551347480117, 138.0, 665.0, 9, NULL, NULL, NULL, '2026-05-03T09:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-03T09:07:47.697437-04:00', '2026-05-03T09:21:47.697437-04:00', NULL, NULL, NULL, '2026-05-03T09:26:47.697437-04:00');
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (9, 1, 3, NULL, 3, NULL, -17.74652289387475, -63.22555752694457, 'Calle 31, Zona Norte', 'Emergencia de tipo engine reportada automáticamente', NULL, 'engine', 'high', 'finalizado', '🚨 SITUACIÓN: Emergencia de engine
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 88.82639003601511, 72.0, 589.0, 10, 115.77682660868747, NULL, NULL, '2026-05-20T06:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-20T06:08:47.697437-04:00', '2026-05-20T06:11:47.697437-04:00', '2026-05-20T06:12:47.697437-04:00', '2026-05-20T06:22:47.697437-04:00', '2026-05-20T07:55:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (10, 1, 3, NULL, 1, NULL, -17.805082292464068, -63.200957000150574, 'Calle 44, Zona Centro', 'Emergencia de tipo other reportada automáticamente', NULL, 'other', 'high', 'finalizado', '🚨 SITUACIÓN: Emergencia de other
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 70.68555467570017, 72.0, 587.0, 29, 623.1303662634842, NULL, NULL, '2026-05-11T21:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-11T21:09:47.697437-04:00', '2026-05-11T21:23:47.697437-04:00', '2026-05-11T21:26:47.697437-04:00', '2026-05-11T21:50:47.697437-04:00', '2026-05-11T22:27:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (11, 1, 1, NULL, 1, NULL, -17.818010380712067, -63.162474614277606, 'Calle 3, Zona Sur', 'Emergencia de tipo tire reportada automáticamente', NULL, 'tire', 'medium', 'finalizado', '🚨 SITUACIÓN: Emergencia de tire
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 77.88466184119862, 123.0, 519.0, 11, 332.59269957544774, NULL, NULL, '2026-05-05T00:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-05T00:09:47.697437-04:00', '2026-05-05T00:16:47.697437-04:00', '2026-05-05T00:18:47.697437-04:00', '2026-05-05T00:38:47.697437-04:00', '2026-05-05T01:34:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (12, 1, 3, NULL, 1, NULL, -17.823587018661204, -63.22057465276056, 'Calle 24, Zona Sur', 'Emergencia de tipo engine reportada automáticamente', NULL, 'engine', 'low', 'cancelado', '🚨 SITUACIÓN: Emergencia de engine
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 85.9472921949471, 66.0, 607.0, 7, NULL, 50.0, NULL, '2026-05-13T00:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-13T00:07:47.697437-04:00', '2026-05-13T00:20:47.697437-04:00', NULL, NULL, NULL, '2026-05-13T00:25:47.697437-04:00');
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (13, 1, 3, NULL, 2, NULL, -17.738126215726354, -63.21120265381166, 'Calle 3, Zona Centro', 'Emergencia de tipo tire reportada automáticamente', NULL, 'tire', 'medium', 'finalizado', '🚨 SITUACIÓN: Emergencia de tire
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 75.72728071850857, 97.0, 769.0, 8, 195.46124828026882, NULL, NULL, '2026-05-02T22:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-02T22:08:47.697437-04:00', '2026-05-02T22:15:47.697437-04:00', '2026-05-02T22:17:47.697437-04:00', '2026-05-02T22:24:47.697437-04:00', '2026-05-03T00:07:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (14, 1, 3, NULL, 1, NULL, -17.782714410830597, -63.13920477791087, 'Calle 42, Zona Este', 'Emergencia de tipo other reportada automáticamente', NULL, 'other', 'high', 'finalizado', '🚨 SITUACIÓN: Emergencia de other
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 96.93196253488895, 172.0, 473.0, 18, 526.9726070379422, NULL, NULL, '2026-05-19T11:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-19T11:07:47.697437-04:00', '2026-05-19T11:18:47.697437-04:00', '2026-05-19T11:21:47.697437-04:00', '2026-05-19T11:48:47.697437-04:00', '2026-05-19T13:44:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (15, 1, 3, NULL, 1, NULL, -17.80004562437428, -63.2006114041219, 'Calle 25, Zona Norte', 'Emergencia de tipo engine reportada automáticamente', NULL, 'engine', 'low', 'finalizado', '🚨 SITUACIÓN: Emergencia de engine
🛠️ DIAGNÓSTICO: Requiere atención', NULL, 97.73776513290792, 119.0, 821.0, 8, 603.975406977899, NULL, NULL, '2026-05-02T09:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-02T09:09:47.697437-04:00', '2026-05-02T09:14:47.697437-04:00', '2026-05-02T09:16:47.697437-04:00', '2026-05-02T09:21:47.697437-04:00', '2026-05-02T10:10:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (16, 2, 5, NULL, 4, NULL, -17.81201746787714, -63.182608401866304, 'Av. 21, Zona Urbari', 'Reporte de tire', NULL, 'tire', 'medium', 'finalizado', '🚨 Emergencia clasificada como tire', NULL, 85.19764129689457, 146.0, 520.0, 14, 785.0070508597449, NULL, NULL, '2026-05-23T09:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-23T09:09:47.697437-04:00', '2026-05-23T09:18:47.697437-04:00', '2026-05-23T09:19:47.697437-04:00', '2026-05-23T09:31:47.697437-04:00', '2026-05-23T10:55:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (17, 2, 5, NULL, 4, NULL, -17.76660217238084, -63.179430535534244, 'Av. 9, Zona Urbari', 'Reporte de engine', NULL, 'engine', 'medium', 'finalizado', '🚨 Emergencia clasificada como engine', NULL, 90.998106800495, 170.0, 516.0, 20, 486.20693317016566, NULL, NULL, '2026-05-24T05:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-24T05:08:47.697437-04:00', '2026-05-24T05:12:47.697437-04:00', '2026-05-24T05:15:47.697437-04:00', '2026-05-24T05:40:47.697437-04:00', '2026-05-24T06:55:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (18, 2, 5, NULL, 4, NULL, -17.761674790848183, -63.206158004460015, 'Av. 2, Zona Equipetrol', 'Reporte de other', NULL, 'other', 'medium', 'finalizado', '🚨 Emergencia clasificada como other', NULL, 75.45850957105931, 167.0, 895.0, 22, 644.863074488889, NULL, NULL, '2026-05-22T12:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-22T12:08:47.697437-04:00', '2026-05-22T12:13:47.697437-04:00', '2026-05-22T12:17:47.697437-04:00', '2026-05-22T12:38:47.697437-04:00', '2026-05-22T13:26:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (19, 2, 5, NULL, 4, NULL, -17.804548174657164, -63.172857760499255, 'Av. 28, Zona Plan 3000', 'Reporte de tire', NULL, 'tire', 'high', 'finalizado', '🚨 Emergencia clasificada como tire', NULL, 95.30976563533844, 217.0, 419.0, 20, 772.6077335741354, NULL, NULL, '2026-05-04T19:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-04T19:07:47.697437-04:00', '2026-05-04T19:09:47.697437-04:00', '2026-05-04T19:11:47.697437-04:00', '2026-05-04T19:28:47.697437-04:00', '2026-05-04T19:52:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (20, 2, 4, NULL, 5, NULL, -17.770311949138115, -63.158380168260486, 'Av. 29, Zona Urbari', 'Reporte de crash', NULL, 'crash', 'medium', 'cancelado', '🚨 Emergencia clasificada como crash', NULL, 97.87363417238002, 159.0, 873.0, 16, NULL, NULL, NULL, '2026-05-19T06:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-19T06:09:47.697437-04:00', '2026-05-19T06:17:47.697437-04:00', NULL, NULL, NULL, '2026-05-19T06:20:47.697437-04:00');
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (21, 2, 4, NULL, 4, NULL, -17.79002293179546, -63.13794857476975, 'Av. 23, Zona Urbari', 'Reporte de engine', NULL, 'engine', 'medium', 'finalizado', '🚨 Emergencia clasificada como engine', NULL, 78.18823174952185, 217.0, 1022.0, 5, 251.08060736352428, NULL, NULL, '2026-05-09T23:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-09T23:07:47.697437-04:00', '2026-05-09T23:09:47.697437-04:00', '2026-05-09T23:13:47.697437-04:00', '2026-05-09T23:19:47.697437-04:00', '2026-05-09T23:39:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (22, 2, 4, NULL, 5, NULL, -17.76788350034643, -63.20623880348126, 'Av. 28, Zona Equipetrol', 'Reporte de engine', NULL, 'engine', 'high', 'finalizado', '🚨 Emergencia clasificada como engine', NULL, 79.1446970710707, 160.0, 966.0, 7, 601.0674610293383, NULL, NULL, '2026-05-15T03:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-15T03:09:47.697437-04:00', '2026-05-15T03:15:47.697437-04:00', '2026-05-15T03:18:47.697437-04:00', '2026-05-15T03:24:47.697437-04:00', '2026-05-15T04:42:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (23, 2, 5, NULL, 5, NULL, -17.773262409532204, -63.145343378523314, 'Av. 9, Zona Equipetrol', 'Reporte de engine', NULL, 'engine', 'high', 'finalizado', '🚨 Emergencia clasificada como engine', NULL, 81.38724629818779, 119.0, 786.0, 8, 857.0626483055413, NULL, NULL, '2026-05-23T20:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-23T20:08:47.697437-04:00', '2026-05-23T20:13:47.697437-04:00', '2026-05-23T20:17:47.697437-04:00', '2026-05-23T20:28:47.697437-04:00', '2026-05-23T21:16:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (24, 2, 5, NULL, 4, NULL, -17.811585093369768, -63.14439493863009, 'Av. 9, Zona Urbari', 'Reporte de engine', NULL, 'engine', 'medium', 'finalizado', '🚨 Emergencia clasificada como engine', NULL, 95.78821203619954, 163.0, 1135.0, 23, 815.3162243056059, NULL, NULL, '2026-05-06T20:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-06T20:08:47.697437-04:00', '2026-05-06T20:12:47.697437-04:00', '2026-05-06T20:13:47.697437-04:00', '2026-05-06T20:36:47.697437-04:00', '2026-05-06T21:46:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (25, 2, 4, NULL, 4, NULL, -17.820920419078373, -63.13253774703358, 'Av. 19, Zona Urbari', 'Reporte de battery', NULL, 'battery', 'high', 'finalizado', '🚨 Emergencia clasificada como battery', NULL, 93.5748837325473, 141.0, 630.0, 24, 787.7414460404051, NULL, NULL, '2026-05-05T13:06:47.697437', '2026-05-25T11:06:47.705429', '2026-05-05T13:08:47.697437-04:00', '2026-05-05T13:15:47.697437-04:00', '2026-05-05T13:19:47.697437-04:00', '2026-05-05T13:46:47.697437-04:00', '2026-05-05T15:10:47.697437-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (28, 1, 1, 1, 1, 2, -17.792839, -63.2151594, 'Calle Coronel Moisés Subirana, Los Mangales, Municipio Santa Cruz de la Sierra', 'llanta pinchada', 'Se me pinchó la llanta hoy en la mañana', 'tire', 'medium', 'en_atencion', '🚨 SITUACIÓN: El usuario reporta un pinchazo en la llanta del vehículo.
🛠️ DIAGNÓSTICO: La imagen confirma un neumático completamente desinflado.
🧰 RECOMENDACIÓN: Asistencia para cambio de llanta.', 'La transcripción del audio y la evidencia visual coinciden perfectamente, indicando un pinchazo de llanta. La imagen muestra un neumático del Toyota Corolla 2020 desinflado, confirmando el reporte del usuario.', 100.0, NULL, NULL, 5, NULL, NULL, '1544b099-df36-4369-9c90-7bff668d66b6', '2026-06-01T19:05:23.748065', '2026-06-01T20:39:25.181407', '2026-06-01T19:05:23.754586-04:00', '2026-06-01T19:55:11.945762-04:00', '2026-06-01T19:56:22.235619-04:00', '2026-06-01T20:39:25.175300-04:00', NULL, NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (27, 1, 1, 1, 1, 2, -17.7928395, -63.2151358, 'Calle Coronel Moisés Subirana, Los Mangales, Municipio Santa Cruz de la Sierra', 'llanta pinchada', 'Se me pinchó la llanta anoche', 'tire', 'medium', 'en_camino', '🚨 SITUACIÓN: El vehículo Toyota Corolla 2020 con matrícula SCZ-1234 en Calle Coronel Moisés Subirana, Los Mangales, Municipio Santa Cruz de la Sierra, presenta una llanta pinchada.
🛠️ DIAGNÓSTICO: La llanta delantera parece estar completamente desinflada.
🧰 RECOMENDACIÓN: Se requiere asistencia para cambio de llanta o reparación.', 'El reporte indica un pinchazo de llanta, y la evidencia visual de la imagen muestra claramente una llanta desinflada. La descripción del usuario y la imagen visual son consistentes.', 100.0, NULL, NULL, 5, NULL, NULL, '59240261-c3b6-4906-91d3-cc784f24135c', '2026-06-01T19:04:17.027507', '2026-06-01T20:39:59.279337', '2026-06-01T19:04:17.034553-04:00', '2026-06-01T20:39:58.127187-04:00', '2026-06-01T20:39:59.275793-04:00', NULL, NULL, NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (29, 1, 1, 1, 1, 1, -17.7928817, -63.2151806, 'Calle Coronel Moisés Subirana, Los Mangales, Municipio Santa Cruz de la Sierra', 'se pinchó mi llanta', 'Se pinchó mi llanta hoy en la mañana', 'tire', 'medium', 'finalizado', '🚨 SITUACIÓN: El vehículo Toyota Corolla 2020, matrícula SCZ-1234, ha sufrido un pinchazo en una de sus llantas en la Calle Coronel Moisés Subirana, Los Mangales, Santa Cruz de la Sierra.
🛠️ DIAGNÓSTICO: Llanta desinflada visiblemente.
🧰 RECOMENDACIÓN: Se requiere asistencia para cambio de llanta o reparación.', 'El reporte del usuario y la evidencia visual de la imagen confirman de manera inequívoca que se trata de un pinchazo de llanta. La llanta se encuentra completamente desinflada, lo que imposibilita el uso seguro del vehículo.', 100.0, NULL, NULL, 5, 100.0, NULL, '4a73dd13-4a86-422c-bfcf-c8ec46bb5ac1', '2026-06-01T19:09:45.929987', '2026-06-01T20:41:39.831639', '2026-06-01T19:09:45.934719-04:00', '2026-06-01T19:54:35.287563-04:00', '2026-06-01T19:54:38.314486-04:00', '2026-06-01T19:55:01.445655-04:00', '2026-06-01T20:41:39.827706-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (30, 1, 1, 1, 1, 2, -17.7928512, -63.215129, 'Calle Coronel Moisés Subirana, Los Mangales, Municipio Santa Cruz de la Sierra', 'llanta pinchada', 'Se me pinchó la llanta anoche, por favor.', 'tire', 'medium', 'finalizado', '🚨 SITUACIÓN: Vehículo Toyota Corolla con llanta pinchada en la Calle Coronel Moisés Subirana.
🛠️ DIAGNÓSTICO: Neumático desinflado, posiblemente por pinchazo.
🧰 RECOMENDACIÓN: Asistencia para cambio de llanta o reparación.', 'La transcripción del audio indica claramente un ''pinchazo de llanta''. La imagen proporcionada muestra un neumático visiblemente desinflado, confirmando la descripción del usuario y la evidencia visual. El vehículo es un Toyota Corolla 2020 y la ubicación es Calle Coronel Moisés Subirana, Los Mangales, Municipio Santa Cruz de la Sierra.', 100.0, NULL, NULL, 5, 100.0, NULL, NULL, '2026-06-06T22:00:52.580005', '2026-06-06T22:09:20.129970', '2026-06-06T22:00:52.644329-04:00', '2026-06-06T22:01:38.880495-04:00', '2026-06-06T22:01:48.094742-04:00', '2026-06-06T22:09:03.936420-04:00', '2026-06-06T22:09:20.125386-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (26, 1, 1, 1, 1, 2, -17.7928707, -63.2151371, 'Calle Coronel Moisés Subirana, Los Mangales, Municipio Santa Cruz de la Sierra', 'llanta pinchada', 'Llanta pinchada en mi auto', 'tire', 'medium', 'finalizado', '🚨 SITUACIÓN: Se reporta una llanta pinchada en un Toyota Corolla 2020 en la Calle Coronel Moisés Subirana, Los Mangales.
🛠️ DIAGNÓSTICO: La llanta delantera presenta una desinflación completa, evidenciando un pinchazo.
🧰 RECOMENDACIÓN: Se requiere asistencia para cambio de llanta o reparación.', 'El usuario reporta una ''llanta pinchada'' y la evidencia visual de la foto muestra claramente una llanta completamente desinflada, confirmando el pinchazo. El vehículo es un Toyota Corolla 2020, matrícula SCZ-1234, ubicado en Calle Coronel Moisés Subirana, Los Mangales, Santa Cruz de la Sierra. La prioridad es media ya que el vehículo no puede desplazarse de forma segura.', 100.0, NULL, NULL, 5, 100.0, NULL, '582e1751-4ff3-424d-b8cc-b3b93068deae', '2026-06-01T18:58:59.999178', '2026-06-06T22:43:06.928048', '2026-06-01T18:59:00.047586-04:00', '2026-06-06T22:10:36.896200-04:00', '2026-06-06T22:10:47.110270-04:00', '2026-06-06T22:42:57.279304-04:00', '2026-06-06T22:43:06.925637-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (31, 1, 1, 1, 1, 1, -17.7928359, -63.2151481, 'Calle Coronel Moisés Subirana, Los Mangales, Municipio Santa Cruz de la Sierra', 'llanta pinchada', 'Se me pinchó la llanta, voy.', 'tire', 'high', 'finalizado', '🚨 SITUACIÓN: El vehículo Toyota Corolla 2020 con placa SCZ-1234 ha sufrido un pinchazo en una de sus llantas. 🛠️ DIAGNÓSTICO: Llanta totalmente desinflada, indicando una punción o fuga de aire significativa. La rueda se ve apoyada en el rin. 🧰 RECOMENDACIÓN: Se requiere asistencia inmediata para cambio de llanta o reparación en sitio.', 'El reporte del usuario y la evidencia visual coinciden perfectamente. Las fotografías muestran de forma clara una llanta completamente desinflada, lo cual confirma un pinchazo. La baja presión es evidente en la forma en que la llanta se aplasta contra el suelo y el rin del vehículo. La prioridad es alta debido a la inmovilización del vehículo.', 100.0, NULL, NULL, 5, 100.0, NULL, NULL, '2026-06-06T22:55:55.085912', '2026-06-06T22:57:56.488949', '2026-06-06T22:55:55.097863-04:00', '2026-06-06T22:57:16.827153-04:00', '2026-06-06T22:57:19.405566-04:00', '2026-06-06T22:57:48.311058-04:00', '2026-06-06T22:57:56.485391-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (32, 1, 1, 1, 1, NULL, -17.7928522, -63.2151251, 'Calle Coronel Moisés Subirana, Los Mangales, Municipio Santa Cruz de la Sierra', 'Emergencia reportada desde App Móvil', 'Llanta pinchada', 'tire', 'medium', 'finalizado', '🚨 SITUACIÓN: El vehículo Toyota Corolla 2020, matrícula SCZ-1234, ha sufrido un pinchazo en una de sus llantas.
🛠️ DIAGNÓSTICO: La llanta está visiblemente desinflada, lo que impide la circulación segura del vehículo.
🧰 RECOMENDACIÓN: Se requiere asistencia para cambio de llanta o reparación.', 'El audio y las imágenes confirman de manera inequívoca que la emergencia se debe a un pinchazo en la llanta del vehículo. La llanta está completamente desinflada, lo cual es un problema común que requiere atención inmediata para permitir la movilidad del coche.', 100.0, NULL, NULL, NULL, 200.0, NULL, NULL, '2026-06-06T22:58:27.282335', '2026-06-06T23:06:50.588325', '2026-06-06T22:58:27.298220-04:00', '2026-06-06T22:59:10.074566-04:00', '2026-06-06T22:59:22.378272-04:00', '2026-06-06T22:59:36.181898-04:00', '2026-06-06T23:06:50.587324-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (33, 1, 1, 1, 1, NULL, -17.792868, -63.2151125, 'Calle Coronel Moisés Subirana, Los Mangales, Municipio Santa Cruz de la Sierra', 'llanta pinchada', 'Se me pinchó la llanta, ayuda por favor', 'tire', 'medium', 'finalizado', '🚨 SITUACIÓN: El conductor reporta un pinchazo en una llanta de su Toyota Corolla 2020 en la Calle Coronel Moisés Subirana, Los Mangales.
🛠️ DIAGNÓSTICO: Pinchazo de llanta trasera.
🧰 RECOMENDACIÓN: Asistencia para cambio de llanta o remolque.', 'La imagen muestra claramente una llanta desinflada del lado del conductor, confirmando el reporte de pinchazo. El audio es breve y claro, sin ruido que dificulte la comprensión. La prioridad es media ya que es una falla mecánica que inmoviliza el vehículo pero no representa un peligro inmediato.', 100.0, NULL, NULL, NULL, 500.0, NULL, NULL, '2026-06-06T23:07:23.179053', '2026-06-06T23:14:28.404940', '2026-06-06T23:07:23.198222-04:00', '2026-06-06T23:07:57.058788-04:00', '2026-06-06T23:11:18.424608-04:00', '2026-06-06T23:14:19.638792-04:00', '2026-06-06T23:14:28.401727-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (34, 1, 1, 1, 1, 1, -17.7928775, -63.2151232, 'Calle Coronel Moisés Subirana, Los Mangales, Municipio Santa Cruz de la Sierra', 'llantas pinchadas', 'Se pinchó', 'tire', 'high', 'finalizado', '🚨 SITUACIÓN: El vehículo Toyota Corolla 2020 con placa SCZ-1234 presenta llantas pinchadas en la Calle Coronel Moisés Subirana, Los Mangales.
🛠️ DIAGNÓSTICO: Una o más llantas están desinfladas y posiblemente inutilizables.
🧰 RECOMENDACIÓN: Asistencia para cambio de llanta o remolque.', 'La imagen muestra claramente una llanta desinflada, lo que confirma la descripción del usuario de ''llantas pinchadas''. La prioridad es alta debido a que un vehículo con llantas pinchadas no es seguro para circular y podría causar daños adicionales o representar un peligro.', 100.0, NULL, NULL, 5, 500.0, NULL, NULL, '2026-06-06T23:36:59.987282', '2026-06-06T23:37:54.790513', '2026-06-06T23:37:00.072543-04:00', '2026-06-06T23:37:15.362539-04:00', '2026-06-06T23:37:30.842025-04:00', '2026-06-06T23:37:45.106379-04:00', '2026-06-06T23:37:54.784408-04:00', NULL);
INSERT INTO incidents (id, tenant_id, user_id, vehicle_id, workshop_id, technician_id, latitude, longitude, address, description, audio_transcription, incident_type, priority, status, ai_summary, ai_classification, ai_confidence, ai_cost_estimate_min, ai_cost_estimate_max, estimated_arrival_minutes, final_cost, cancellation_fee, local_uuid, created_at, updated_at, searching_at, assigned_at, en_route_at, attending_at, completed_at, cancelled_at) VALUES (35, 1, 1, 1, 1, 1, -17.7928748, -63.2151084, 'Calle Coronel Moisés Subirana, Los Mangales, Municipio Santa Cruz de la Sierra', 'llantas pinchada', 'Se me pinchó la llanta anoche', 'tire', 'medium', 'finalizado', '🚨 SITUACIÓN: Un Toyota Corolla con placa SCZ-1234 ha sufrido un pinchazo en una de sus llantas en la Calle Coronel Moisés Subirana, Los Mangales.
🛠️ DIAGNÓSTICO: La llanta delantera derecha (o la más visible en las imágenes) está completamente desinflada, indicando un pinchazo o fuga de aire significativa.
🧰 RECOMENDACIÓN: Se requiere asistencia para cambio de llanta o reparación de la misma.', 'La información proporcionada por el usuario coincide con la evidencia visual, que muestra claramente un neumático desinflado en un Toyota Corolla. No hay indicios de colisión, falla de motor, batería, sobrecalentamiento ni problemas relacionados con llaves. La urgencia es media, ya que permite el desplazamiento con precaución hasta un taller o el uso de la llanta de repuesto.', 100.0, NULL, NULL, 5, 100.0, NULL, NULL, '2026-06-06T23:54:17.648471', '2026-06-06T23:54:53.923862', '2026-06-06T23:54:17.665370-04:00', '2026-06-06T23:54:34.842602-04:00', '2026-06-06T23:54:36.347197-04:00', '2026-06-06T23:54:46.950816-04:00', '2026-06-06T23:54:53.915698-04:00', NULL);

-- Datos de la tabla: evidences
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (1, 1, 26, 'audio', 'uploads\audio\acce1751338140c1be21404f676e9bf3.m4a', NULL, NULL, '2026-06-01T18:59:04.719813');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (2, 1, 26, 'image', 'uploads\images\42c0487b6b0e4b9d8e1d1f3694400ac1.jpg', NULL, NULL, '2026-06-01T18:59:04.719813');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (3, 1, 26, 'text', NULL, 'llanta pinchada', NULL, '2026-06-01T18:59:04.719813');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (4, 1, 27, 'audio', 'uploads\audio\9619d216236f40bea502fb9e7aee4bcd.m4a', NULL, NULL, '2026-06-01T19:04:20.503663');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (5, 1, 27, 'image', 'uploads\images\fdc7f8653efc484fbc3cbaa7e3149823.jpg', NULL, NULL, '2026-06-01T19:04:20.503663');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (6, 1, 27, 'text', NULL, 'llanta pinchada', NULL, '2026-06-01T19:04:20.503663');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (7, 1, 28, 'audio', 'uploads\audio\04a1f92053734b6db68b2d352945f0ae.m4a', NULL, NULL, '2026-06-01T19:05:26.457581');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (8, 1, 28, 'image', 'uploads\images\b19dd467276c4c51a4f50bacf5b89408.jpg', NULL, NULL, '2026-06-01T19:05:26.457581');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (9, 1, 28, 'text', NULL, 'llanta pinchada', NULL, '2026-06-01T19:05:26.457581');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (10, 1, 29, 'audio', 'uploads\audio\f32072b58f904c36b8c193c7048264f1.m4a', NULL, NULL, '2026-06-01T19:09:49.694291');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (11, 1, 29, 'image', 'uploads\images\645941a4490e4d1c95bc00189d0dc0c4.jpg', NULL, NULL, '2026-06-01T19:09:49.694291');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (12, 1, 29, 'text', NULL, 'se pinchó mi llanta', NULL, '2026-06-01T19:09:49.694291');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (13, 1, 30, 'audio', 'uploads\audio\1f1b5b166b664f7a8946868ddbcd00bb.m4a', NULL, NULL, '2026-06-06T22:00:56.575679');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (14, 1, 30, 'image', 'uploads\images\05f49a9ce87b47469a6dec6564e4ae57.jpg', NULL, NULL, '2026-06-06T22:00:56.575679');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (15, 1, 30, 'text', NULL, 'llanta pinchada', NULL, '2026-06-06T22:00:56.575679');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (16, 1, 31, 'audio', 'uploads\audio\bb80c3ddeb17457aa8d761b8e772723f.m4a', NULL, NULL, '2026-06-06T22:55:59.274176');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (17, 1, 31, 'image', 'uploads\images\e716e99a8d4c4fe0b69a0cca9f87c43a.jpg', NULL, NULL, '2026-06-06T22:55:59.274176');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (18, 1, 31, 'text', NULL, 'llanta pinchada', NULL, '2026-06-06T22:55:59.274176');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (19, 1, 32, 'audio', 'uploads\audio\e793d96eef764c5ab55144d9439b534c.m4a', NULL, NULL, '2026-06-06T22:58:30.359529');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (20, 1, 32, 'image', 'uploads\images\adf1eddca5134498935e495311c15cb8.jpg', NULL, NULL, '2026-06-06T22:58:30.359529');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (21, 1, 32, 'text', NULL, 'Emergencia reportada desde App Móvil', NULL, '2026-06-06T22:58:30.359529');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (22, 1, 33, 'audio', 'uploads\audio\5cb65009c5404bfe95d1627b75b738a6.m4a', NULL, NULL, '2026-06-06T23:07:27.132415');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (23, 1, 33, 'image', 'uploads\images\36a425c8b8a041e88c1b5ed5c09fbb72.jpg', NULL, NULL, '2026-06-06T23:07:27.132415');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (24, 1, 33, 'text', NULL, 'llanta pinchada', NULL, '2026-06-06T23:07:27.132415');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (25, 1, 34, 'audio', 'uploads\audio\87efc97b1ddf4b3bbb73d209380ea5c3.m4a', NULL, NULL, '2026-06-06T23:37:04.135091');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (26, 1, 34, 'image', 'uploads\images\d1c0bd5e573c4c4c9106720884570823.jpg', NULL, NULL, '2026-06-06T23:37:04.135091');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (27, 1, 34, 'text', NULL, 'llantas pinchadas', NULL, '2026-06-06T23:37:04.135091');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (28, 1, 35, 'audio', 'uploads\audio\a6a3443e836143cbbb507e8c7735f364.m4a', NULL, NULL, '2026-06-06T23:54:21.647666');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (29, 1, 35, 'image', 'uploads\images\9274b071eab4483a809267ad829a0eab.jpg', NULL, NULL, '2026-06-06T23:54:21.647666');
INSERT INTO evidences (id, tenant_id, incident_id, evidence_type, file_url, content, ai_analysis, created_at) VALUES (30, 1, 35, 'text', NULL, 'llantas pinchada', NULL, '2026-06-06T23:54:21.647666');

-- Datos de la tabla: payments
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (1, 1, 1, 683.46, 68.35, 10.0, 0.0, 'completed', 'paralela', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-12T21:02:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (2, 1, 2, 383.8, 38.38, 10.0, 0.0, 'completed', 'paralela', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-01T10:25:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (3, 1, 3, 584.8, 58.48, 10.0, 0.0, 'completed', 'credit_card', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-12T03:26:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (4, 1, 5, 482.57, 48.26, 10.0, 0.0, 'completed', 'credit_card', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-17T12:36:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (5, 1, 6, 291.14, 29.11, 10.0, 0.0, 'completed', 'credit_card', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-19T04:24:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (6, 1, 7, 244.56, 24.46, 10.0, 0.0, 'completed', 'mobile_payment', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-03T12:23:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (7, 1, 9, 115.78, 11.58, 10.0, 0.0, 'completed', 'mobile_payment', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-20T07:55:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (8, 1, 10, 623.13, 62.31, 10.0, 0.0, 'completed', 'paralela', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-11T22:27:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (9, 1, 11, 332.59, 33.26, 10.0, 0.0, 'completed', 'mobile_payment', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-05T01:34:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (10, 1, 13, 195.46, 19.55, 10.0, 0.0, 'completed', 'mobile_payment', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-03T00:07:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (11, 1, 14, 526.97, 52.7, 10.0, 0.0, 'completed', 'mobile_payment', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-19T13:44:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (12, 1, 15, 603.98, 60.4, 10.0, 0.0, 'completed', 'credit_card', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-02T10:10:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (13, 2, 16, 785.01, 78.5, 10.0, 0.0, 'completed', 'paralela', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-23T10:55:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (14, 2, 17, 486.21, 48.62, 10.0, 0.0, 'completed', 'paralela', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-24T06:55:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (15, 2, 18, 644.86, 64.49, 10.0, 0.0, 'completed', 'credit_card', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-22T13:26:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (16, 2, 19, 772.61, 77.26, 10.0, 0.0, 'completed', 'mobile_payment', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-04T19:52:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (17, 2, 21, 251.08, 25.11, 10.0, 0.0, 'completed', 'mobile_payment', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-09T23:39:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (18, 2, 22, 601.07, 60.11, 10.0, 0.0, 'completed', 'mobile_payment', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-15T04:42:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (19, 2, 23, 857.06, 85.71, 10.0, 0.0, 'completed', 'paralela', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-23T21:16:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (20, 2, 24, 815.32, 81.53, 10.0, 0.0, 'completed', 'mobile_payment', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-06T21:46:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (21, 2, 25, 787.74, 78.77, 10.0, 0.0, 'completed', 'credit_card', NULL, '2026-05-25T11:06:42.519276-04:00', '2026-05-05T15:10:47.697437-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (22, 1, 34, 500.0, 50.0, 10.0, 0.0, 'completed', 'mobile_payment', NULL, '2026-06-06T23:38:23.936350-04:00', '2026-06-06T23:38:24.008966-04:00');
INSERT INTO payments (id, tenant_id, incident_id, amount, commission_amount, commission_percent, cancellation_fee, payment_status, payment_method, payment_intent_id, created_at, paid_at) VALUES (23, 1, 35, 100.0, 10.0, 10.0, 0.0, 'completed', 'mobile_payment', NULL, '2026-06-06T23:55:10.990658-04:00', '2026-06-06T23:55:11.021872-04:00');

-- Datos de la tabla: quotations
INSERT INTO quotations (id, tenant_id, incident_id, workshop_id, amount, estimated_repair_hours, description, status, created_at, accepted_at) VALUES (1, 1, 26, 1, 300.0, 1.0, '', 'pending', '2026-06-06T22:10:24.187818-04:00', NULL);
INSERT INTO quotations (id, tenant_id, incident_id, workshop_id, amount, estimated_repair_hours, description, status, created_at, accepted_at) VALUES (2, 1, 31, 1, 100.0, 1.0, 'esta barato', 'pending', '2026-06-06T22:56:58.384618-04:00', NULL);
INSERT INTO quotations (id, tenant_id, incident_id, workshop_id, amount, estimated_repair_hours, description, status, created_at, accepted_at) VALUES (3, 1, 32, 1, 50.0, 1.0, '', 'accepted', '2026-06-06T22:58:55.410586-04:00', '2026-06-06T22:59:10.059394-04:00');
INSERT INTO quotations (id, tenant_id, incident_id, workshop_id, amount, estimated_repair_hours, description, status, created_at, accepted_at) VALUES (4, 1, 33, 1, 200.0, 0.5, '', 'accepted', '2026-06-06T23:07:43.604774-04:00', '2026-06-06T23:07:57.055691-04:00');

-- Datos de la tabla: service_history
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (1, 1, 1, 'pendiente', 'Incidente creado', 'sistema', '2026-05-12T19:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (2, 1, 1, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-12T19:07:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (3, 1, 1, 'taller_asignado', 'Asignado a taller #3', 'sistema', '2026-05-12T19:15:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (4, 1, 1, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-12T19:17:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (5, 1, 1, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-12T19:34:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (6, 1, 1, 'finalizado', 'Servicio completado', 'sistema', '2026-05-12T21:02:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (7, 1, 2, 'pendiente', 'Incidente creado', 'sistema', '2026-05-01T08:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (8, 1, 2, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-01T08:09:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (9, 1, 2, 'taller_asignado', 'Asignado a taller #1', 'sistema', '2026-05-01T08:24:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (10, 1, 2, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-01T08:29:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (11, 1, 2, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-01T08:46:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (12, 1, 2, 'finalizado', 'Servicio completado', 'sistema', '2026-05-01T10:25:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (13, 1, 3, 'pendiente', 'Incidente creado', 'sistema', '2026-05-12T01:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (14, 1, 3, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-12T01:07:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (15, 1, 3, 'taller_asignado', 'Asignado a taller #1', 'sistema', '2026-05-12T01:09:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (16, 1, 3, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-12T01:13:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (17, 1, 3, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-12T01:27:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (18, 1, 3, 'finalizado', 'Servicio completado', 'sistema', '2026-05-12T03:26:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (19, 1, 4, 'pendiente', 'Incidente creado', 'sistema', '2026-05-17T01:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (20, 1, 4, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-17T01:07:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (21, 1, 4, 'taller_asignado', 'Asignado a taller #1', 'sistema', '2026-05-17T01:09:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (22, 1, 4, 'cancelado', 'Cancelado', 'sistema', '2026-05-17T01:14:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (23, 1, 5, 'pendiente', 'Incidente creado', 'sistema', '2026-05-17T10:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (24, 1, 5, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-17T10:09:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (25, 1, 5, 'taller_asignado', 'Asignado a taller #1', 'sistema', '2026-05-17T10:14:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (26, 1, 5, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-17T10:15:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (27, 1, 5, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-17T10:40:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (28, 1, 5, 'finalizado', 'Servicio completado', 'sistema', '2026-05-17T12:36:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (29, 1, 6, 'pendiente', 'Incidente creado', 'sistema', '2026-05-19T03:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (30, 1, 6, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-19T03:08:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (31, 1, 6, 'taller_asignado', 'Asignado a taller #3', 'sistema', '2026-05-19T03:21:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (32, 1, 6, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-19T03:22:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (33, 1, 6, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-19T03:27:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (34, 1, 6, 'finalizado', 'Servicio completado', 'sistema', '2026-05-19T04:24:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (35, 1, 7, 'pendiente', 'Incidente creado', 'sistema', '2026-05-03T10:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (36, 1, 7, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-03T10:08:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (37, 1, 7, 'taller_asignado', 'Asignado a taller #3', 'sistema', '2026-05-03T10:13:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (38, 1, 7, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-03T10:15:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (39, 1, 7, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-03T10:51:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (40, 1, 7, 'finalizado', 'Servicio completado', 'sistema', '2026-05-03T12:23:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (41, 1, 8, 'pendiente', 'Incidente creado', 'sistema', '2026-05-03T09:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (42, 1, 8, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-03T09:07:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (43, 1, 8, 'taller_asignado', 'Asignado a taller #3', 'sistema', '2026-05-03T09:21:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (44, 1, 8, 'cancelado', 'Cancelado', 'sistema', '2026-05-03T09:26:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (45, 1, 9, 'pendiente', 'Incidente creado', 'sistema', '2026-05-20T06:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (46, 1, 9, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-20T06:08:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (47, 1, 9, 'taller_asignado', 'Asignado a taller #3', 'sistema', '2026-05-20T06:11:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (48, 1, 9, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-20T06:12:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (49, 1, 9, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-20T06:22:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (50, 1, 9, 'finalizado', 'Servicio completado', 'sistema', '2026-05-20T07:55:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (51, 1, 10, 'pendiente', 'Incidente creado', 'sistema', '2026-05-11T21:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (52, 1, 10, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-11T21:09:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (53, 1, 10, 'taller_asignado', 'Asignado a taller #1', 'sistema', '2026-05-11T21:23:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (54, 1, 10, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-11T21:26:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (55, 1, 10, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-11T21:50:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (56, 1, 10, 'finalizado', 'Servicio completado', 'sistema', '2026-05-11T22:27:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (57, 1, 11, 'pendiente', 'Incidente creado', 'sistema', '2026-05-05T00:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (58, 1, 11, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-05T00:09:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (59, 1, 11, 'taller_asignado', 'Asignado a taller #1', 'sistema', '2026-05-05T00:16:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (60, 1, 11, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-05T00:18:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (61, 1, 11, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-05T00:38:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (62, 1, 11, 'finalizado', 'Servicio completado', 'sistema', '2026-05-05T01:34:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (63, 1, 12, 'pendiente', 'Incidente creado', 'sistema', '2026-05-13T00:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (64, 1, 12, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-13T00:07:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (65, 1, 12, 'taller_asignado', 'Asignado a taller #1', 'sistema', '2026-05-13T00:20:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (66, 1, 12, 'cancelado', 'Cancelado', 'sistema', '2026-05-13T00:25:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (67, 1, 13, 'pendiente', 'Incidente creado', 'sistema', '2026-05-02T22:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (68, 1, 13, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-02T22:08:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (69, 1, 13, 'taller_asignado', 'Asignado a taller #2', 'sistema', '2026-05-02T22:15:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (70, 1, 13, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-02T22:17:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (71, 1, 13, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-02T22:24:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (72, 1, 13, 'finalizado', 'Servicio completado', 'sistema', '2026-05-03T00:07:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (73, 1, 14, 'pendiente', 'Incidente creado', 'sistema', '2026-05-19T11:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (74, 1, 14, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-19T11:07:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (75, 1, 14, 'taller_asignado', 'Asignado a taller #1', 'sistema', '2026-05-19T11:18:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (76, 1, 14, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-19T11:21:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (77, 1, 14, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-19T11:48:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (78, 1, 14, 'finalizado', 'Servicio completado', 'sistema', '2026-05-19T13:44:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (79, 1, 15, 'pendiente', 'Incidente creado', 'sistema', '2026-05-02T09:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (80, 1, 15, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-02T09:09:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (81, 1, 15, 'taller_asignado', 'Asignado a taller #1', 'sistema', '2026-05-02T09:14:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (82, 1, 15, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-02T09:16:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (83, 1, 15, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-02T09:21:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (84, 1, 15, 'finalizado', 'Servicio completado', 'sistema', '2026-05-02T10:10:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (85, 2, 16, 'pendiente', 'Incidente creado', 'sistema', '2026-05-23T09:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (86, 2, 16, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-23T09:09:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (87, 2, 16, 'taller_asignado', 'Asignado a taller #4', 'sistema', '2026-05-23T09:18:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (88, 2, 16, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-23T09:19:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (89, 2, 16, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-23T09:31:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (90, 2, 16, 'finalizado', 'Servicio completado', 'sistema', '2026-05-23T10:55:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (91, 2, 17, 'pendiente', 'Incidente creado', 'sistema', '2026-05-24T05:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (92, 2, 17, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-24T05:08:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (93, 2, 17, 'taller_asignado', 'Asignado a taller #4', 'sistema', '2026-05-24T05:12:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (94, 2, 17, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-24T05:15:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (95, 2, 17, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-24T05:40:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (96, 2, 17, 'finalizado', 'Servicio completado', 'sistema', '2026-05-24T06:55:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (97, 2, 18, 'pendiente', 'Incidente creado', 'sistema', '2026-05-22T12:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (98, 2, 18, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-22T12:08:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (99, 2, 18, 'taller_asignado', 'Asignado a taller #4', 'sistema', '2026-05-22T12:13:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (100, 2, 18, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-22T12:17:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (101, 2, 18, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-22T12:38:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (102, 2, 18, 'finalizado', 'Servicio completado', 'sistema', '2026-05-22T13:26:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (103, 2, 19, 'pendiente', 'Incidente creado', 'sistema', '2026-05-04T19:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (104, 2, 19, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-04T19:07:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (105, 2, 19, 'taller_asignado', 'Asignado a taller #4', 'sistema', '2026-05-04T19:09:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (106, 2, 19, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-04T19:11:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (107, 2, 19, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-04T19:28:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (108, 2, 19, 'finalizado', 'Servicio completado', 'sistema', '2026-05-04T19:52:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (109, 2, 20, 'pendiente', 'Incidente creado', 'sistema', '2026-05-19T06:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (110, 2, 20, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-19T06:09:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (111, 2, 20, 'taller_asignado', 'Asignado a taller #5', 'sistema', '2026-05-19T06:17:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (112, 2, 20, 'cancelado', 'Cancelado', 'sistema', '2026-05-19T06:20:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (113, 2, 21, 'pendiente', 'Incidente creado', 'sistema', '2026-05-09T23:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (114, 2, 21, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-09T23:07:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (115, 2, 21, 'taller_asignado', 'Asignado a taller #4', 'sistema', '2026-05-09T23:09:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (116, 2, 21, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-09T23:13:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (117, 2, 21, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-09T23:19:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (118, 2, 21, 'finalizado', 'Servicio completado', 'sistema', '2026-05-09T23:39:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (119, 2, 22, 'pendiente', 'Incidente creado', 'sistema', '2026-05-15T03:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (120, 2, 22, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-15T03:09:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (121, 2, 22, 'taller_asignado', 'Asignado a taller #5', 'sistema', '2026-05-15T03:15:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (122, 2, 22, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-15T03:18:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (123, 2, 22, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-15T03:24:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (124, 2, 22, 'finalizado', 'Servicio completado', 'sistema', '2026-05-15T04:42:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (125, 2, 23, 'pendiente', 'Incidente creado', 'sistema', '2026-05-23T20:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (126, 2, 23, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-23T20:08:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (127, 2, 23, 'taller_asignado', 'Asignado a taller #5', 'sistema', '2026-05-23T20:13:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (128, 2, 23, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-23T20:17:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (129, 2, 23, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-23T20:28:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (130, 2, 23, 'finalizado', 'Servicio completado', 'sistema', '2026-05-23T21:16:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (131, 2, 24, 'pendiente', 'Incidente creado', 'sistema', '2026-05-06T20:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (132, 2, 24, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-06T20:08:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (133, 2, 24, 'taller_asignado', 'Asignado a taller #4', 'sistema', '2026-05-06T20:12:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (134, 2, 24, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-06T20:13:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (135, 2, 24, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-06T20:36:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (136, 2, 24, 'finalizado', 'Servicio completado', 'sistema', '2026-05-06T21:46:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (137, 2, 25, 'pendiente', 'Incidente creado', 'sistema', '2026-05-05T13:06:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (138, 2, 25, 'buscando_taller', 'Buscando talleres', 'sistema', '2026-05-05T13:08:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (139, 2, 25, 'taller_asignado', 'Asignado a taller #4', 'sistema', '2026-05-05T13:15:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (140, 2, 25, 'en_camino', 'Mecánico en camino', 'sistema', '2026-05-05T13:19:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (141, 2, 25, 'en_atencion', 'Mecánico atendiendo', 'sistema', '2026-05-05T13:46:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (142, 2, 25, 'finalizado', 'Servicio completado', 'sistema', '2026-05-05T15:10:47.697437');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (143, 1, 26, 'pendiente', 'Incidente creado', 'sistema', '2026-06-01T18:59:04.738505');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (144, 1, 26, 'buscando_taller', 'Buscando talleres cercanos', 'sistema', '2026-06-01T18:59:04.738505');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (145, 1, 27, 'pendiente', 'Incidente creado', 'sistema', '2026-06-01T19:04:20.506650');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (146, 1, 27, 'buscando_taller', 'Buscando talleres cercanos', 'sistema', '2026-06-01T19:04:20.506650');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (147, 1, 28, 'pendiente', 'Incidente creado', 'sistema', '2026-06-01T19:05:26.459621');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (148, 1, 28, 'buscando_taller', 'Buscando talleres cercanos', 'sistema', '2026-06-01T19:05:26.459621');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (149, 1, 29, 'pendiente', 'Incidente creado', 'sistema', '2026-06-01T19:09:49.696597');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (150, 1, 29, 'buscando_taller', 'Buscando talleres cercanos', 'sistema', '2026-06-01T19:09:49.696597');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (151, 1, 29, 'taller_asignado', 'Aceptado por taller Taller Automotriz Central', 'taller_1', '2026-06-01T19:54:35.299930');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (152, 1, 29, 'en_camino', 'Mecánico en camino - Taller Taller Automotriz Central', 'taller_1', '2026-06-01T19:54:38.314486');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (153, 1, 29, 'en_atencion', 'Mecánico llegó al lugar - Taller Taller Automotriz Central', 'taller_1', '2026-06-01T19:55:01.445655');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (154, 1, 28, 'taller_asignado', 'Aceptado por taller Taller Automotriz Central', 'taller_1', '2026-06-01T19:55:11.950391');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (155, 1, 28, 'en_camino', 'Mecánico en camino - Taller Taller Automotriz Central', 'taller_1', '2026-06-01T19:56:22.238659');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (156, 1, 28, 'en_atencion', 'Mecánico llegó al lugar - Taller Taller Automotriz Central', 'taller_1', '2026-06-01T20:39:25.181744');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (157, 1, 27, 'taller_asignado', 'Aceptado por taller Taller Automotriz Central', 'taller_1', '2026-06-01T20:39:58.134420');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (158, 1, 27, 'en_camino', 'Mecánico en camino - Taller Taller Automotriz Central', 'taller_1', '2026-06-01T20:39:59.280337');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (159, 1, 29, 'finalizado', 'Servicio completado por taller Taller Automotriz Central', 'taller_1', '2026-06-01T20:41:39.833559');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (160, 1, 30, 'pendiente', 'Incidente creado', 'sistema', '2026-06-06T22:00:56.584621');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (161, 1, 30, 'buscando_taller', 'Buscando talleres cercanos', 'sistema', '2026-06-06T22:00:56.584621');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (162, 1, 30, 'taller_asignado', 'Aceptado por taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:01:38.903167');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (163, 1, 30, 'en_camino', 'Mecánico en camino - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:01:48.097261');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (164, 1, 30, 'en_atencion', 'Mecánico llegó al lugar - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:09:03.942510');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (165, 1, 30, 'finalizado', 'Servicio completado por taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:09:20.132488');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (166, 1, 26, 'taller_asignado', 'Aceptado por taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:10:36.906591');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (167, 1, 26, 'en_camino', 'Mecánico en camino - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:10:47.115445');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (168, 1, 26, 'en_atencion', 'Mecánico llegó al lugar - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:42:57.296075');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (169, 1, 26, 'finalizado', 'Servicio completado por taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:43:06.932130');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (170, 1, 31, 'pendiente', 'Incidente creado', 'sistema', '2026-06-06T22:55:59.278178');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (171, 1, 31, 'buscando_taller', 'Buscando talleres cercanos', 'sistema', '2026-06-06T22:55:59.278178');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (172, 1, 31, 'taller_asignado', 'Aceptado por taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:57:16.840534');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (173, 1, 31, 'en_camino', 'Mecánico en camino - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:57:19.414589');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (184, 1, 33, 'taller_asignado', 'Cotización aceptada - Taller #1', 'usuario', '2026-06-06T23:07:57.065406');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (186, 1, 33, 'en_atencion', 'Mecánico llegó al lugar - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T23:14:19.644953');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (187, 1, 33, 'finalizado', 'Servicio completado por taller Taller Automotriz Central', 'taller_1', '2026-06-06T23:14:28.407228');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (188, 1, 34, 'pendiente', 'Incidente creado', 'sistema', '2026-06-06T23:37:04.141885');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (189, 1, 34, 'buscando_taller', 'Buscando talleres cercanos', 'sistema', '2026-06-06T23:37:04.141885');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (174, 1, 31, 'en_atencion', 'Mecánico llegó al lugar - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:57:48.312158');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (175, 1, 31, 'finalizado', 'Servicio completado por taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:57:56.493812');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (176, 1, 32, 'pendiente', 'Incidente creado', 'sistema', '2026-06-06T22:58:30.363611');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (177, 1, 32, 'buscando_taller', 'Buscando talleres cercanos', 'sistema', '2026-06-06T22:58:30.363611');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (178, 1, 32, 'taller_asignado', 'Cotización aceptada - Taller #1', 'usuario', '2026-06-06T22:59:10.079993');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (179, 1, 32, 'en_camino', 'Mecánico en camino - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:59:22.378272');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (180, 1, 32, 'en_atencion', 'Mecánico llegó al lugar - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T22:59:36.185521');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (181, 1, 32, 'finalizado', 'Servicio completado por taller Taller Automotriz Central', 'taller_1', '2026-06-06T23:06:50.592665');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (182, 1, 33, 'pendiente', 'Incidente creado', 'sistema', '2026-06-06T23:07:27.140675');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (183, 1, 33, 'buscando_taller', 'Buscando talleres cercanos', 'sistema', '2026-06-06T23:07:27.140675');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (185, 1, 33, 'en_camino', 'Mecánico en camino - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T23:11:18.433469');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (190, 1, 34, 'taller_asignado', 'Aceptado por taller Taller Automotriz Central', 'taller_1', '2026-06-06T23:37:15.367826');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (191, 1, 34, 'en_camino', 'Mecánico en camino - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T23:37:30.846127');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (192, 1, 34, 'en_atencion', 'Mecánico llegó al lugar - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T23:37:45.114398');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (193, 1, 34, 'finalizado', 'Servicio completado por taller Taller Automotriz Central', 'taller_1', '2026-06-06T23:37:54.792811');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (194, 1, 35, 'pendiente', 'Incidente creado', 'sistema', '2026-06-06T23:54:21.652887');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (195, 1, 35, 'buscando_taller', 'Buscando talleres cercanos', 'sistema', '2026-06-06T23:54:21.652887');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (196, 1, 35, 'taller_asignado', 'Aceptado por taller Taller Automotriz Central', 'taller_1', '2026-06-06T23:54:34.875156');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (197, 1, 35, 'en_camino', 'Mecánico en camino - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T23:54:36.355017');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (198, 1, 35, 'en_atencion', 'Mecánico llegó al lugar - Taller Taller Automotriz Central', 'taller_1', '2026-06-06T23:54:46.963105');
INSERT INTO service_history (id, tenant_id, incident_id, status, notes, created_by, created_at) VALUES (199, 1, 35, 'finalizado', 'Servicio completado por taller Taller Automotriz Central', 'taller_1', '2026-06-06T23:54:53.926244');

-- Reactivar restricciones de integridad
SET session_replication_role = 'origin';
