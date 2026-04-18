import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_theme.dart';
import '../services/vehicle_service.dart';
import '../services/incident_service.dart';
import '../models/vehicle_model.dart';
import 'login_screen.dart';
import 'report_incident_screen.dart';
import 'incident_detail_screen.dart';
import 'incident_history_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
   final _vehicleService = VehicleService();
   final _incidentService = IncidentService();
   List<Vehicle> _vehicles = [];
   Vehicle? _selectedVehicle;
   Map<String, dynamic>? _activeIncident;
   bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final vehicles = await _vehicleService.getMyVehicles();
    final incidents = await _incidentService.getMyIncidents();
    
    setState(() {
      _vehicles = vehicles;
      if (vehicles.isNotEmpty && _selectedVehicle == null) _selectedVehicle = vehicles.first;
      
      // Encontrar el último incidente activo (Pendiente, Asignado o En Progreso)
      if (incidents.isNotEmpty) {
        final last = incidents.first;
        final status = last['status'].toString().toLowerCase();
        if (status.contains('pending') || status.contains('assigned') || status.contains('in_progress')) {
          _activeIncident = last;
        }
      }
      
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergencias', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.accentNeon),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentHistoryScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.errorRed),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con Saludo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          child: Text(
                            '¡Hola, Carlos!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 5),
                        FadeInDown(
                          delay: const Duration(milliseconds: 200),
                          child: const Text(
                            '¿En qué podemos ayudarte hoy?',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_activeIncident != null)
                          FadeInRight(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => IncidentDetailScreen(incidentId: _activeIncident!['id']),
                                  ),
                                ).then((_) => _loadData());
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentNeon.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.accentNeon.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_searching, color: AppTheme.accentNeon),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Tienes una emergencia activa', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text('ID: #${_activeIncident!['id']} - Toca para ver seguimiento', style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.accentNeon),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
    
                  // Botón SOS Central
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElasticIn(
                            child: GestureDetector(
                              onTap: () {
                                if (_selectedVehicle == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Por favor, selecciona un vehículo primero.')),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportIncidentScreen(selectedVehicle: _selectedVehicle!),
                                  ),
                                );
                              },
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.errorRed,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.errorRed.withOpacity(0.4),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                  gradient: const RadialGradient(
                                    colors: [
                                      Color(0xFFFF5F6D),
                                      AppTheme.errorRed,
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.warning_amber_rounded, size: 50, color: Colors.white),
                                      SizedBox(height: 5),
                                      Text(
                                        'SOS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Pulse(
                            infinite: true,
                            child: const Text(
                              'PRESIONA EN CASO DE EMERGENCIA',
                              style: TextStyle(
                                color: AppTheme.errorRed,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
    
                  // Lista de Vehículos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis Vehículos',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _vehicles.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 15),
                            itemBuilder: (context, index) {
                              final v = _vehicles[index];
                              final isSelected = _selectedVehicle?.id == v.id;
                              return FadeInRight(
                                delay: Duration(milliseconds: 100 * index),
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedVehicle = v),
                                  child: Container(
                                    width: 160,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primaryNeon : Colors.white.withOpacity(0.05),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.directions_car, size: 20, color: isSelected ? AppTheme.primaryNeon : AppTheme.accentNeon),
                                        const SizedBox(height: 5),
                                        Text(v.brand, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(v.plateNumber, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
          ),
    );
  }
}
