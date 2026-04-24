import 'package:flutter/material.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../services/incident_service.dart';
import 'incident_detail_screen.dart';

class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  final _incidentService = IncidentService();
  List<dynamic> _incidents = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshHistorySilently();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _incidentService.getMyIncidents();
    if (mounted) {
      setState(() {
        _incidents = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshHistorySilently() async {
    final history = await _incidentService.getMyIncidents();
    if (mounted) {
      setState(() {
        _incidents = history;
      });
    }
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'battery': return '🔋 Batería';
      case 'tire': return '🛞 Llanta';
      case 'crash': return '💥 Accidente';
      case 'engine': return '🔧 Motor';
      case 'overheating': return '🌡️ Sobrecalentamiento';
      case 'keys_lost': return '🔑 Llave perdida';
      case 'keys_locked': return '🔐 Llave en vehículo';
      default: return '❓ Otro';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'PENDIENTE';
      case 'assigned': return 'ASIGNADO';
      case 'in_progress': return 'EN PROCESO';
      case 'completed': return 'COMPLETADO';
      case 'cancelled': return 'CANCELADO';
      default: return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Reportes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incidents.isEmpty
              ? const Center(child: Text('No tienes reportes previos.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _incidents.length,
                  itemBuilder: (context, index) {
                    final item = _incidents[index];
                    final date = DateTime.parse(item['created_at']).toLocal();
                    final status = item['status']?.toString() ?? 'pending';
                    
                    return FadeInUp(
                      delay: Duration(milliseconds: 50 * index),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IncidentDetailScreen(incidentId: item['id']),
                              ),
                            );
                            // Recargar historial al volver por si hubo cambios
                            _loadHistory();
                          },
                          leading: _getIconForType(item['incident_type']),
                          title: Text(
                            '${_getTypeLabel(item['incident_type'])} #${item['id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(DateFormat('dd/MM/yyyy - HH:mm').format(date)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                            ),
                            child: Text(
                              _getStatusLabel(status),
                              style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Icon _getIconForType(String? type) {
    switch (type) {
      case 'battery': return const Icon(Icons.battery_alert, color: Colors.orange);
      case 'tire': return const Icon(Icons.tire_repair, color: Colors.blue);
      case 'engine': return const Icon(Icons.engineering, color: Colors.red);
      case 'crash': return const Icon(Icons.car_crash, color: Colors.redAccent);
      case 'overheating': return const Icon(Icons.thermostat, color: Colors.deepOrange);
      case 'keys_lost': return const Icon(Icons.key_off, color: Colors.amber);
      case 'keys_locked': return const Icon(Icons.lock, color: Colors.amber);
      default: return const Icon(Icons.warning, color: AppTheme.primaryNeon);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.greenAccent;
      case 'cancelled': return Colors.grey;
      case 'pending': return AppTheme.accentNeon;
      case 'assigned': return Colors.cyan;
      case 'in_progress': return Colors.orangeAccent;
      default: return Colors.orangeAccent;
    }
  }
}
