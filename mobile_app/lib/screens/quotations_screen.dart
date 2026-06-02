import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_theme.dart';
import '../services/incident_service.dart';
import 'tracking_screen.dart';

class QuotationsScreen extends StatefulWidget {
  final int incidentId;
  final String? incidentDescription;

  const QuotationsScreen({
    super.key,
    required this.incidentId,
    this.incidentDescription,
  });

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  final IncidentService _incidentService = IncidentService();
  bool _isLoading = true;
  List<dynamic> _quotations = [];
  Map<String, dynamic>? _aiEstimate;
  bool _isLoadingEstimate = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Cargar cotizaciones
      final quotes = await _incidentService.getQuotations(widget.incidentId);
      
      // 2. Obtener estimación de IA si hay descripción
      if (widget.incidentDescription != null && widget.incidentDescription!.isNotEmpty) {
        setState(() => _isLoadingEstimate = true);
        _aiEstimate = await _incidentService.getCostEstimate(widget.incidentDescription!);
        setState(() => _isLoadingEstimate = false);
      }

      setState(() {
        _quotations = quotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "No se pudieron cargar las cotizaciones.";
        _isLoading = false;
        _isLoadingEstimate = false;
      });
    }
  }

  Future<void> _acceptQuotation(int quotationId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await _incidentService.acceptQuotation(quotationId);
      if (mounted) Navigator.pop(context); // Cerrar loader

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('¡Cotización aceptada! Taller asignado.', style: TextStyle(color: Colors.white)),
            ),
          );
          // Redirigir a la pantalla de tracking
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TrackingScreen(incidentId: widget.incidentId),
            ),
          );
        }
      } else {
        throw Exception("No se pudo completar el proceso");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.errorRed,
            content: const Text('Error al aceptar la cotización. Intente de nuevo.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones del Taller'),
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Sección de IA de Costos ---
                    if (_isLoadingEstimate)
                      Card(
                        color: AppTheme.cardBg,
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      )
                    else if (_aiEstimate != null)
                      FadeInDown(
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentNeon.withOpacity(0.15),
                                AppTheme.primaryNeon.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.accentNeon.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.psychology, color: AppTheme.accentNeon, size: 28),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Estimador de Costos (IA)',
                                    style: TextStyle(
                                      color: AppTheme.accentNeon,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Rango de costo sugerido:',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bs. ${_aiEstimate!['min_cost']} - Bs. ${_aiEstimate!['max_cost']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _aiEstimate!['reasoning'] ?? '',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),
                    const Text(
                      'Ofertas Disponibles',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    if (_errorMessage != null)
                      Center(child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed)))
                    else if (_quotations.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40.0),
                          child: Column(
                            children: [
                              const Icon(Icons.hourglass_empty, size: 60, color: Colors.white24),
                              const SizedBox(height: 15),
                              const Text(
                                'Buscando cotizaciones...',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white54),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Los talleres del tenant están evaluando tu caso.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _quotations.length,
                        itemBuilder: (context, index) {
                          final quote = _quotations[index];
                          final workshop = quote['workshop'] ?? {};
                          final amount = quote['amount'] ?? 0.0;
                          final hours = quote['estimated_repair_hours'] ?? 0.0;
                          final notes = quote['description'] ?? 'Sin descripción adicional';

                          return FadeInUp(
                            duration: Duration(milliseconds: 300 + (index * 100)),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          workshop['name'] ?? 'Taller Mecánico',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      Text(
                                        'Bs. $amount',
                                        style: const TextStyle(
                                          color: AppTheme.primaryNeon,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tiempo estimado: $hours horas',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    notes,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _acceptQuotation(quote['id']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryNeon,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            minimumSize: Size.zero,
                                          ),
                                          child: const Text(
                                            'Aceptar Oferta',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
