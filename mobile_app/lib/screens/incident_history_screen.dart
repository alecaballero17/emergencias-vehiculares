import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
                    final date = DateTime.parse(item['created_at']);
                    final status = item['status'].toString().split('.').last.toUpperCase();
                    
                    return FadeInUp(
                      delay: Duration(milliseconds: 50 * index),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IncidentDetailScreen(incidentId: item['id']),
                              ),
                            );
                          },
                          leading: _getIconForType(item['incident_type']),
                          title: Text(
                            '${item['incident_type'].toString().toUpperCase()} #${item['id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(DateFormat('dd MMM yyyy - HH:mm').format(date)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                            ),
                            child: Text(
                              status,
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
      default: return const Icon(Icons.warning, color: AppTheme.primaryNeon);
    }
  }

  Color _getStatusColor(String status) {
    if (status.contains('COMPLETED')) return Colors.greenAccent;
    if (status.contains('CANCELLED')) return Colors.grey;
    if (status.contains('PENDING')) return AppTheme.accentNeon;
    return Colors.orangeAccent;
  }
}
