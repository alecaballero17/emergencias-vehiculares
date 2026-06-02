import 'package:flutter/material.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../services/offline_service.dart';
import '../services/connectivity_service.dart';

class OfflineIncidentsScreen extends StatefulWidget {
  const OfflineIncidentsScreen({super.key});

  @override
  State<OfflineIncidentsScreen> createState() => _OfflineIncidentsScreenState();
}

class _OfflineIncidentsScreenState extends State<OfflineIncidentsScreen> {
  final _offlineService = OfflineService.instance;
  final _connectivityService = ConnectivityService();
  
  List<Map<String, dynamic>> _incidents = [];
  bool _isSyncing = false;
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _isOnline = _connectivityService.isOnline;
    _connectivitySubscription = _connectivityService.isOnlineStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
    _loadIncidents();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _loadIncidents() {
    final list = _offlineService.getPendingIncidents();
    setState(() {
      _incidents = list;
    });
  }

  Future<void> _syncAll() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sin conexión a Internet. Sincronización no disponible.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);
    await _offlineService.syncPendingIncidents();
    setState(() => _isSyncing = false);
    _loadIncidents();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sincronización completada.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteIncident(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Eliminar Reporte Offline'),
        content: const Text('¿Estás seguro de que deseas eliminar permanentemente este reporte guardado sin conexión? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _offlineService.deleteOfflineIncident(id);
      _loadIncidents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte offline eliminado.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent;
      case 'syncing':
        return Colors.cyan;
      case 'error':
        return AppTheme.errorRed;
      case 'synced':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'PENDIENTE DE RED';
      case 'syncing':
        return 'SINCRONIZANDO...';
      case 'error':
        return 'FALLÓ SINCRONIZACIÓN';
      case 'synced':
        return 'ENVIADO';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cola de Sincronización'),
        actions: [
          if (_incidents.isNotEmpty)
            IconButton(
              icon: _isSyncing 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : const Icon(Icons.sync, color: AppTheme.primaryNeon),
              onPressed: _isSyncing ? null : _syncAll,
              tooltip: 'Sincronizar todo',
            ),
        ],
      ),
      body: Column(
        children: [
          // Conexión actual header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: _isOnline ? Colors.green.withOpacity(0.15) : AppTheme.errorRed.withOpacity(0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isOnline ? Icons.wifi : Icons.wifi_off, 
                      color: _isOnline ? Colors.greenAccent : AppTheme.errorRed,
                      size: 20
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOnline ? 'Conexión a Internet Estable' : 'Modo Sin Conexión Activo',
                      style: TextStyle(
                        color: _isOnline ? Colors.greenAccent : AppTheme.errorRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 13
                      ),
                    ),
                  ],
                ),
                if (!_isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Offline', style: TextStyle(color: AppTheme.errorRed, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // Lista de incidentes
          Expanded(
            child: _incidents.isEmpty
                ? Center(
                    child: FadeIn(
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_done_outlined, size: 70, color: Colors.white24),
                          SizedBox(height: 16),
                          Text(
                            'Todo sincronizado',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white54),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'No tienes reportes pendientes de enviar.',
                            style: TextStyle(fontSize: 12, color: Colors.white30),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _incidents.length,
                    itemBuilder: (context, index) {
                      final item = _incidents[index];
                      final date = DateTime.parse(item['created_at']).toLocal();
                      final String status = item['sync_status'] ?? 'pending';
                      final String id = item['id'];
                      final double lat = item['latitude'] as double;
                      final double lng = item['longitude'] as double;
                      final String? desc = item['description'];

                      return FadeInUp(
                        delay: Duration(milliseconds: 50 * index),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.cloud_off, size: 18, color: AppTheme.textSecondary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Reporte #${id.substring(0, 8)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        _getStatusLabel(status),
                                        style: TextStyle(color: _getStatusColor(status), fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24, color: Colors.white10),
                                Text(
                                  'Fecha: ${DateFormat('dd/MM/yyyy - HH:mm').format(date)}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ubicación: Lat: ${lat.toStringAsFixed(5)}, Lon: ${lng.toStringAsFixed(5)}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                if (desc != null && desc.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Descripción: "$desc"',
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white70),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
                                      icon: const Icon(Icons.delete_outline, size: 16),
                                      label: const Text('Eliminar', style: TextStyle(fontSize: 12)),
                                      onPressed: () => _deleteIncident(id),
                                    ),
                                    const SizedBox(width: 12),
                                    if (status == 'error' || status == 'pending')
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryNeon,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.refresh, size: 14),
                                        label: const Text('Reintentar', style: TextStyle(fontSize: 12)),
                                        onPressed: _isSyncing ? null : _syncAll,
                                      ),
                                  ],
                                )
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
    );
  }
}
