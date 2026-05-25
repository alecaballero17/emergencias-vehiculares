import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_theme.dart';
import '../services/incident_service.dart';
import '../services/websocket_service.dart';

class TrackingScreen extends StatefulWidget {
  final int incidentId;

  const TrackingScreen({super.key, required this.incidentId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final IncidentService _incidentService = IncidentService();
  final WebSocketService _wsService = WebSocketService();
  
  bool _isLoading = true;
  String _status = 'pendiente';
  int? _etaMinutes;
  double? _cancellationFee;
  String? _workshopName;
  String? _mechanicName;
  
  // Coordenadas
  LatLng _userLocation = const LatLng(-17.7833, -63.1822); // Santa Cruz por defecto
  LatLng? _mechanicLocation;
  
  // Google Maps Controller
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _fetchInitialDetails();
    _initWebSocket();
  }

  @override
  void dispose() {
    _wsService.unsubscribeIncident(widget.incidentId);
    _wsService.disconnect();
    super.dispose();
  }

  Future<void> _fetchInitialDetails() async {
    try {
      final detail = await _incidentService.getIncidentDetail(widget.incidentId);
      if (detail != null) {
        setState(() {
          _status = detail['status'] ?? 'pendiente';
          _userLocation = LatLng(detail['latitude'], detail['longitude']);
          _cancellationFee = detail['cancellation_fee'] != null 
              ? (detail['cancellation_fee'] as num).toDouble() 
              : null;
          _etaMinutes = detail['estimated_arrival_minutes'];
          
          final ws = detail['workshop'];
          if (ws != null) {
            _workshopName = ws['name'];
          }
          _isLoading = false;
        });
        _updateMarkers();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _initWebSocket() async {
    await _wsService.connect();
    _wsService.subscribeIncident(widget.incidentId);
    _wsService.messages.listen((msg) {
      if (msg['incident_id'] == widget.incidentId) {
        if (msg['type'] == 'status_change') {
          setState(() {
            _status = msg['new_status'];
            if (msg['cancellation_fee'] != null) {
              _cancellationFee = (msg['cancellation_fee'] as num).toDouble();
            }
            if (msg['eta_minutes'] != null) {
              _etaMinutes = msg['eta_minutes'];
            }
          });
          _updateMarkers();

          if (_status == 'finalizado' || _status == 'cancelado') {
            _showEndDialog(_status);
          }
        } else if (msg['type'] == 'location_update') {
          final lat = msg['latitude'] as double;
          final lng = msg['longitude'] as double;
          setState(() {
            _mechanicLocation = LatLng(lat, lng);
            if (msg['eta_minutes'] != null) {
              _etaMinutes = msg['eta_minutes'];
            }
          });
          _updateMarkers();
          _animateToLocation(LatLng(lat, lng));
        }
      }
    });
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation,
          infoWindow: const InfoWindow(title: 'Tu Ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      if (_mechanicLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('mechanic_location'),
            position: _mechanicLocation!,
            infoWindow: InfoWindow(title: _mechanicName ?? 'Mecánico / Asistencia'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ),
        );
      }
    });
  }

  void _animateToLocation(LatLng pos) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(pos),
    );
  }

  void _showEndDialog(String endStatus) {
    String title = endStatus == 'finalizado' ? '✅ Servicio Completado' : '❌ Incidente Cancelado';
    String message = endStatus == 'finalizado' 
        ? 'El mecánico ha completado la asistencia. Puedes proceder al pago.' 
        : 'El incidente ha sido cancelado.';
    
    if (_cancellationFee != null && _cancellationFee! > 0) {
      message += '\n\nSe ha aplicado un recargo de reconocimiento de Bs. $_cancellationFee por cancelación en camino/atención.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver al Home
            },
            child: const Text('Volver al Home'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelIncident() async {
    // Verificar si requiere recargo
    final bool hasFee = _status == 'en_camino' || _status == 'en_atencion';
    final String alertText = hasFee
        ? '⚠️ ATENCIÓN: El mecánico ya está en camino o atendiéndote. Cancelar en este punto incurre en una Tarifa de Reconocimiento obligatoria de Bs. 50.\n\n¿Estás seguro de cancelar?'
        : '¿Estás seguro de que deseas cancelar la solicitud de asistencia?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Confirmar Cancelación'),
        content: Text(alertText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, continuar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _incidentService.cancelIncident(widget.incidentId);
      setState(() => _isLoading = false);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.errorRed,
            content: const Text('No se pudo cancelar el incidente.'),
          ),
        );
      }
    }
  }

  // Helper para pintar el tracker de estados
  Widget _buildStateTracker() {
    final List<String> states = ['buscando_taller', 'taller_asignado', 'en_camino', 'en_atencion', 'finalizado'];
    final List<String> labels = ['Buscando', 'Asignado', 'En Camino', 'Atención', 'Completado'];
    
    int currentIndex = states.indexOf(_status);
    if (currentIndex == -1 && _status == 'pendiente') currentIndex = 0;
    if (_status == 'cancelado') currentIndex = -1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(states.length, (index) {
        bool isDone = index <= currentIndex;
        bool isCurrent = index == currentIndex;
        Color color = isCurrent 
            ? AppTheme.accentNeon 
            : (isDone ? AppTheme.primaryNeon : AppTheme.textSecondary.withOpacity(0.3));

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == 0 
                          ? Colors.transparent 
                          : (index <= currentIndex ? AppTheme.primaryNeon : Colors.white10),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: isCurrent ? Colors.white : Colors.transparent,
                        width: 2
                      ),
                    ),
                    child: Icon(
                      index < currentIndex ? Icons.check : null, 
                      size: 12, 
                      color: Colors.white
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == states.length - 1 
                          ? Colors.transparent 
                          : (index < currentIndex ? AppTheme.primaryNeon : Colors.white10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte de Emergencia'),
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // --- MAPA EN FONDO ---
                GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(target: _userLocation, zoom: 15),
                  markers: _markers,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                ),

                // --- PANEL DE CONTROL INFERIOR ---
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBg,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Barra indicadora de arrastre
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          // --- Tracker de Estados ---
                          _buildStateTracker(),
                          const Divider(height: 30, color: Colors.white10),

                          // --- Detalles del Taller / ETA ---
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryNeon.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.car_repair, color: AppTheme.primaryNeon, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _workshopName ?? 'Buscando taller especializado...',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _status == 'en_camino' 
                                          ? 'Mecánico en ruta' 
                                          : (_status == 'en_atencion' ? 'Servicio en curso' : 'Espere confirmación'),
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (_etaMinutes != null && (_status == 'taller_asignado' || _status == 'en_camino'))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentNeon.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$_etaMinutes min',
                                        style: const TextStyle(
                                          color: AppTheme.accentNeon,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16
                                        ),
                                      ),
                                      const Text('ETA', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          
                          // Advertencia de congestión de tráfico pesado si aplica
                          if (_etaMinutes != null && _etaMinutes! > 25)
                            Padding(
                              padding: const EdgeInsets.only(top: 15.0),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Tráfico pesado detectado en la ruta. Retraso probable.',
                                        style: TextStyle(color: Colors.orange, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // --- Botón de Cancelación ---
                          if (_status != 'finalizado' && _status != 'cancelado')
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.errorRed),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _cancelIncident,
                                child: const Text(
                                  'CANCELAR SOLICITUD',
                                  style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
