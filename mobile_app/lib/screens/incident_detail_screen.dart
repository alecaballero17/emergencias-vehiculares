import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_theme.dart';
import '../services/incident_service.dart';

class IncidentDetailScreen extends StatefulWidget {
  final int incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final _incidentService = IncidentService();
  Map<String, dynamic>? _incident;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final detail = await _incidentService.getIncidentDetail(widget.incidentId);
    if (mounted) {
      setState(() {
        _incident = detail;
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelIncident() async {
    final success = await _incidentService.cancelIncident(widget.incidentId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergencia cancelada.')),
      );
      _loadDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_incident == null) return const Scaffold(body: Center(child: Text('Error al cargar detalle')));

    final status = _incident!['status'];
    final aiSummary = _incident!['ai_summary'] ?? 'Procesando análisis de IA...';

    return Scaffold(
      appBar: AppBar(title: Text('Emergencia #${widget.incidentId}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNeon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.sync, color: AppTheme.primaryNeon, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      status.toString().split('.').last.toUpperCase(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryNeon),
                    ),
                    const Text('Estado de la solicitud', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // AI Analysis Section
            FadeInLeft(
              child: const Text('Análisis Inteligente (IA)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            FadeInLeft(
              delay: const Duration(milliseconds: 200),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  aiSummary,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Timeline 
            FadeInUp(
              child: const Text('Línea de Tiempo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            _buildTimelineItem('Reporte Recibido', 'Hace unos momentos', true),
            _buildTimelineItem('Análisis de IA Completado', 'Prioridad asignada', true),
            _buildTimelineItem('Buscando Taller Cercano', 'En espera...', false),
            
            const SizedBox(height: 40),
            
            // Botones de Acción
            const SizedBox(height: 10),
            if (status == 'pending' || status == 'assigned')
              FadeInUp(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cancelIncident,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorRed.withOpacity(0.1),
                      side: const BorderSide(color: AppTheme.errorRed),
                    ),
                    child: const Text('CANCELAR EMERGENCIA', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            
            const SizedBox(height: 15),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.textSecondary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cerrar y volver al Home', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? AppTheme.accentNeon : AppTheme.textSecondary,
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal)),
              Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}
