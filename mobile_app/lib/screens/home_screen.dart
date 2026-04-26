import 'package:flutter/material.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import '../core/app_theme.dart';
import '../services/vehicle_service.dart';
import '../services/incident_service.dart';
import '../services/local_notification_service.dart';
import '../models/vehicle_model.dart';
import 'login_screen.dart';
import 'report_incident_screen.dart';
import 'incident_detail_screen.dart';
import 'incident_history_screen.dart';
import 'profile_screen.dart';
import 'vehicle_form_screen.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _vehicleService = VehicleService();
  final _incidentService = IncidentService();
  final _notificationService = LocalNotificationService();
  
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  Map<String, dynamic>? _activeIncident;
  User? _userProfile;
  String? _lastKnownStatus;
  bool _isLoading = true;
  Timer? _globalPollingTimer;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    _loadData();
    _globalPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollActiveIncident();
    });
  }

  @override
  void dispose() {
    _globalPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollActiveIncident() async {
    final incidents = await _incidentService.getMyIncidents();
    if (incidents.isNotEmpty) {
      final last = incidents.first;
      final status = last['status'].toString().toLowerCase();
      
      // Si el estado cambió (o es el primer incidente asignado en una cuenta nueva)
      bool isFirstAssignment = (_lastKnownStatus == null && (status == 'assigned' || status == 'in_progress'));
      bool isStatusChange = (_lastKnownStatus != null && _lastKnownStatus != status);

      if (isFirstAssignment || isStatusChange) {
        final int uniqueNotifId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

        if (status == 'assigned') {
          _notificationService.showNotification(
            id: uniqueNotifId, 
            title: '¡Taller Asignado! 🔧', 
            body: 'Un taller ha aceptado tu emergencia. Pronto despacharán a un técnico.'
          );
          _showInAppNotification('¡Taller Asignado! 🔧', 'Un taller ha aceptado tu emergencia.', Colors.blue);
        } else if (status == 'in_progress') {
          final eta = last['estimated_arrival_minutes'];
          final etaText = eta != null ? ' Tiempo estimado: $eta minutos.' : '';
          _notificationService.showNotification(
            id: uniqueNotifId + 1, 
            title: '¡Técnico en camino! 🚗', 
            body: 'El taller ha despachado al mecánico. ¡Pronto estará contigo!$etaText'
          );
          _showInAppNotification('¡Técnico en camino! 🚗', 'El mecánico va en camino.$etaText', Colors.orange);
        } else if (status == 'completed') {
          _notificationService.showNotification(
            id: uniqueNotifId + 2, 
            title: '¡Servicio Finalizado! ✅', 
            body: 'El taller ha completado el servicio. Por favor realiza el pago.'
          );
          _showInAppNotification('¡Servicio Finalizado! ✅', 'Por favor realiza el pago.', Colors.green);
        }
      }

      if (mounted) {
        setState(() {
          if (status.contains('pending') || status.contains('assigned') || status.contains('in_progress')) {
            _activeIncident = last;
          } else {
            _activeIncident = null; // Ya no hay incidente activo
          }
          _lastKnownStatus = status;
        });
      }
    }
  }

  void _showInAppNotification(String title, String body, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(body, style: const TextStyle(fontSize: 14)),
          ],
        ),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
        elevation: 6,
      ),
    );
  }

  Future<void> _loadData() async {
    final authService = AuthService();
    final vehicles = await _vehicleService.getMyVehicles();
    final profile = await authService.getProfile();
    await _pollActiveIncident(); // Carga inicial
    
    if (mounted) {
      setState(() {
        _vehicles = vehicles;
        _userProfile = profile;
        if (vehicles.isNotEmpty && _selectedVehicle == null) _selectedVehicle = vehicles.first;
        _isLoading = false;
      });
    }
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
            icon: const Icon(Icons.person_outline, color: AppTheme.primaryNeon),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
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
                            '¡Hola, ${_userProfile?.fullName ?? 'Usuario'}!',
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mis Vehículos',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () async {
                                final refresh = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
                                );
                                if (refresh == true) _loadData();
                              },
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryNeon),
                              tooltip: 'Añadir Vehículo',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_vehicles.isEmpty)
                          Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: const Center(
                              child: Text('No tienes vehículos registrados 🚗', style: TextStyle(color: AppTheme.textSecondary)),
                            ),
                          )
                        else
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
                                    onLongPress: () async {
                                      final refresh = await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => VehicleFormScreen(vehicle: v)),
                                      );
                                      if (refresh == true) _loadData();
                                    },
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
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Icon(Icons.directions_car, size: 20, color: isSelected ? AppTheme.primaryNeon : AppTheme.accentNeon),
                                              if (isSelected) const Icon(Icons.check_circle, size: 14, color: AppTheme.primaryNeon),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(v.brand, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                          Text(v.plateNumber, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  const SizedBox(height: 40),
                ],
              ),
          ),
    );
  }
}
