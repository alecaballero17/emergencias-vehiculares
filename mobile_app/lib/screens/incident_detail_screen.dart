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
  bool _isPaymentLoading = false;
  String _selectedPaymentMethod = '';

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

  Future<void> _processPayment() async {
    final cost = _incident?['final_cost'];
    if (cost == null || cost == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El taller aún no ha registrado el costo del servicio.')),
      );
      return;
    }
    if (_selectedPaymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un método de pago')),
      );
      return;
    }

    setState(() => _isPaymentLoading = true);

    final success = await _incidentService.makePayment(
      incidentId: widget.incidentId,
      amount: (cost as num).toDouble(),
      paymentMethod: _selectedPaymentMethod,
    );

    setState(() => _isPaymentLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pago realizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDetail();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar el pago'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'PENDIENTE';
      case 'assigned': return 'ASIGNADO';
      case 'in_progress': return 'EN PROCESO';
      case 'completed': return 'COMPLETADO';
      case 'cancelled': return 'CANCELADO';
      default: return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'assigned': return Colors.cyan;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return AppTheme.primaryNeon;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'low': return 'BAJA';
      case 'medium': return 'MEDIA';
      case 'high': return 'ALTA';
      case 'critical': return 'CRÍTICA';
      default: return priority.toUpperCase();
    }
  }

  String _getTypeText(String type) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_incident == null) return const Scaffold(body: Center(child: Text('Error al cargar detalle')));

    final status = _incident!['status'] ?? 'pending';
    final aiSummary = _incident!['ai_summary'] ?? 'Procesando análisis de IA...';
    final workshopId = _incident!['workshop_id'];
    final technicianId = _incident!['technician_id'];
    final estimatedArrival = _incident!['estimated_arrival_minutes'];
    final priority = _incident!['priority'] ?? 'medium';
    final incidentType = _incident!['incident_type'] ?? 'other';
    final finalCost = _incident!['final_cost'];
    final payment = _incident!['payment'];
    final isPaid = payment != null;
    final address = _incident!['address'];
    final aiConfidence = _incident!['ai_confidence'];

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
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      status == 'completed' ? Icons.check_circle : Icons.sync,
                      color: _getStatusColor(status),
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getStatusText(status),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _getStatusColor(status)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_getTypeText(incidentType), style: const TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Prioridad: ${_getPriorityText(priority)}', style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Taller asignado y ETA
            if (workshopId != null) ...[
              const SizedBox(height: 20),
              FadeInLeft(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🔧 Taller Asignado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryNeon)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.store, color: Colors.white70),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Taller #$workshopId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        ],
                      ),
                      if (technicianId != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.white70),
                            const SizedBox(width: 10),
                            Text('Técnico asignado #$technicianId', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                      if (estimatedArrival != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentNeon.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.timer, color: AppTheme.accentNeon),
                              const SizedBox(width: 8),
                              Text(
                                'Tiempo estimado de llegada: ~$estimatedArrival min',
                                style: const TextStyle(color: AppTheme.accentNeon, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // Ubicación
            if (address != null) ...[
              const SizedBox(height: 20),
              FadeInLeft(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(child: Text(address, style: const TextStyle(color: Colors.white70))),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 25),

            // AI Analysis Section
            FadeInLeft(
              child: const Text('🤖 Análisis Inteligente (IA)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            if (aiConfidence != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Precisión: ', style: TextStyle(color: Colors.white70)),
                  Text('${aiConfidence}%', style: TextStyle(color: AppTheme.accentNeon, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
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
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70, fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Línea de Tiempo
            FadeInUp(
              child: const Text('📋 Línea de Tiempo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            _buildTimelineItem('Reporte Recibido', 'Emergencia registrada', true),
            _buildTimelineItem('Análisis de IA', 'Clasificado y priorizado', true),
            _buildTimelineItem(
              'Taller Asignado',
              workshopId != null ? 'Taller #$workshopId' : 'En espera...',
              workshopId != null,
            ),
            _buildTimelineItem(
              'En Proceso',
              status == 'in_progress' ? 'Técnico en camino' : 'Pendiente',
              status == 'in_progress' || status == 'completed',
            ),
            _buildTimelineItem(
              'Completado',
              status == 'completed' ? 'Servicio finalizado' : 'Pendiente',
              status == 'completed',
            ),

            const SizedBox(height: 30),

            // Sección de Pago (cuando el taller completó y puso precio)
            if (status == 'completed' && finalCost != null && (finalCost as num) > 0) ...[
              FadeInUp(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.withOpacity(0.08) : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isPaid ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle : Icons.receipt_long,
                        color: isPaid ? Colors.green : Colors.orange,
                        size: 44,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isPaid ? '✅ PAGADO' : '💳 Pago del Servicio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Monto a pagar
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Bs. ${(finalCost as num).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Monto total del servicio',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      if (!isPaid) ...[
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Selecciona método de pago:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Grid de métodos de pago
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.5,
                          children: [
                            _buildPaymentOption('mobile_payment', '📱', 'QR / Billetera'),
                            _buildPaymentOption('cash', '💵', 'Efectivo'),
                            _buildPaymentOption('credit_card', '💳', 'Tarjeta'),
                            _buildPaymentOption('debit_card', '🏦', 'Transferencia'),
                          ],
                        ),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (_isPaymentLoading || _selectedPaymentMethod.isEmpty) ? null : _processPayment,
                            icon: _isPaymentLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              _isPaymentLoading ? 'Procesando...' : 'CONFIRMAR PAGO',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedPaymentMethod.isEmpty ? Colors.grey : Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'Método: ${_getPaymentMethodLabel(payment?['payment_method'] ?? '')}',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Botones de Acción
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

            const SizedBox(height: 30),
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

  Widget _buildPaymentOption(String method, String emoji, String label) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.green : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: isBold ? Colors.white : Colors.white54,
          fontSize: isBold ? 15 : 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        )),
        Text(value, style: TextStyle(
          color: isBold ? Colors.green : Colors.white,
          fontSize: isBold ? 18 : 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        )),
      ],
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'mobile_payment': return 'QR / Billetera Móvil';
      case 'cash': return 'Efectivo';
      case 'credit_card': return 'Tarjeta de Crédito';
      case 'debit_card': return 'Transferencia Bancaria';
      default: return method;
    }
  }
}
