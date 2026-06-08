import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/app_theme.dart';
import '../services/incident_service.dart';
import '../services/websocket_service.dart';
import 'quotations_screen.dart';
import 'tracking_screen.dart';

class IncidentDetailScreen extends StatefulWidget {
  final int incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final _incidentService = IncidentService();
  final _wsService = WebSocketService();
  Map<String, dynamic>? _incident;
  bool _isLoading = true;
  bool _isPaymentLoading = false;
  String _selectedPaymentMethod = '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _initWebSocket();
  }

  void _initWebSocket() async {
    await _wsService.connect();
    _wsService.subscribeIncident(widget.incidentId);
    _wsService.messages.listen((msg) {
      if (msg['incident_id'] == widget.incidentId) {
        if (msg['type'] == 'status_change') {
          _refreshDetailSilently();
        }
      }
    });
  }

  @override
  void dispose() {
    _wsService.unsubscribeIncident(widget.incidentId);
    _wsService.disconnect();
    super.dispose();
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

  Future<void> _refreshDetailSilently() async {
    final detail = await _incidentService.getIncidentDetail(widget.incidentId);
    if (mounted) {
      setState(() {
        _incident = detail;
      });
    }
  }

  Future<void> _cancelIncident() async {
    final status = _incident?['status'] ?? 'pendiente';
    final hasFee = status == 'en_camino' || status == 'en_atencion';
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
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergencia cancelada.')),
        );
        _loadDetail();
      }
    }
  }

  void _showPaymentFlow() {
    final status = _incident?['status'] ?? '';
    final cancellationFee = _incident?['cancellation_fee'];
    final cost = _incident?['final_cost'];
    
    final double amount = (status == 'cancelado' && cancellationFee != null)
        ? (cancellationFee as num).toDouble()
        : (cost != null ? (cost as num).toDouble() : 0.0);

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'cancelado'
              ? 'No hay tarifa de cancelación registrada.'
              : 'El taller aún no ha registrado el costo del servicio.'),
        ),
      );
      return;
    }
    if (_selectedPaymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un método de pago')),
      );
      return;
    }

    switch (_selectedPaymentMethod) {
      case 'credit_card':
        _showCardPayment(amount);
        break;
      case 'mobile_payment':
        _showQRPayment(amount);
        break;
      case 'cash':
        _showCashPayment(amount);
        break;
      case 'debit_card':
        _showTransferPayment(amount);
        break;
    }
  }

  Future<void> _executePayment(double amount) async {
    setState(() => _isPaymentLoading = true);

    bool success = false;
    final intentId = await _incidentService.createPaymentIntent(
      incidentId: widget.incidentId,
      amount: amount,
      paymentMethod: _selectedPaymentMethod,
    );

    if (intentId != null) {
      success = await _incidentService.confirmPayment(paymentIntentId: intentId);
    } else {
      success = await _incidentService.makePayment(
        incidentId: widget.incidentId,
        amount: amount,
        paymentMethod: _selectedPaymentMethod,
      );
    }

    setState(() => _isPaymentLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pago procesado exitosamente por pasarela Paralela'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDetail();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar el pago por pasarela'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ========== FLUJO TARJETA (Estilo Stripe) ==========
  void _showCardPayment(double amount) {
    String cardNumber = '';
    String expiryDate = '';
    String cvv = '';
    String cardHolder = '';
    bool isCvvFocused = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),
                    const Text('💳 Pago con Tarjeta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Total: Bs. ${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),

                    // Tarjeta animada
                    CreditCardWidget(
                      cardNumber: cardNumber,
                      expiryDate: expiryDate,
                      cardHolderName: cardHolder,
                      cvvCode: cvv,
                      showBackView: isCvvFocused,
                      onCreditCardWidgetChange: (_) {},
                      cardBgColor: const Color(0xFF0D2137),
                      glassmorphismConfig: Glassmorphism(
                        blurX: 10, blurY: 10,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Colors.green.withOpacity(0.3), Colors.blue.withOpacity(0.3)],
                        ),
                      ),
                    ),

                    // Formulario
                    CreditCardForm(
                      formKey: formKey,
                      cardNumber: cardNumber,
                      expiryDate: expiryDate,
                      cardHolderName: cardHolder,
                      cvvCode: cvv,
                      onCreditCardModelChange: (model) {
                        setModalState(() {
                          cardNumber = model.cardNumber;
                          expiryDate = model.expiryDate;
                          cardHolder = model.cardHolderName;
                          cvv = model.cvvCode;
                          isCvvFocused = model.isCvvFocused;
                        });
                      },
                      obscureCvv: true,
                      inputConfiguration: const InputConfiguration(
                        cardNumberDecoration: InputDecoration(
                          labelText: 'Número de Tarjeta',
                          hintText: 'XXXX XXXX XXXX XXXX',
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        expiryDateDecoration: InputDecoration(
                          labelText: 'Fecha Exp.',
                          hintText: 'MM/AA',
                          prefixIcon: Icon(Icons.date_range),
                        ),
                        cvvCodeDecoration: InputDecoration(
                          labelText: 'CVV',
                          hintText: 'XXX',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        cardHolderDecoration: InputDecoration(
                          labelText: 'Nombre del Titular',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Text('Tarjeta de prueba: 4242 4242 4242 4242', style: TextStyle(color: Colors.blue, fontSize: 12))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isPaymentLoading ? null : () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(ctx);
                            _executePayment(amount);
                          }
                        },
                        icon: _isPaymentLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.lock, size: 18),
                        label: Text(_isPaymentLoading ? 'Procesando...' : 'PAGAR Bs. ${amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ========== FLUJO QR ==========
  void _showQRPayment(double amount) {
    final qrData = 'emergencias-vehiculares|pago|${widget.incidentId}|$amount|BOB';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text('📱 Pago con QR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Escanea el código con tu app de banca móvil', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 20),

              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Bs. ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),

              const SizedBox(height: 8),
              const Text('Tigo Money • BNB • Banco Sol • BCP', style: TextStyle(color: Colors.white38, fontSize: 12)),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _executePayment(amount);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('YA REALICÉ EL PAGO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========== FLUJO EFECTIVO ==========
  void _showCashPayment(double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('💵', style: TextStyle(fontSize: 28)),
            SizedBox(width: 10),
            Text('Pago en Efectivo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('Bs. ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 4),
                  const Text('Pagar directamente al técnico',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Al confirmar, el técnico recibirá una notificación de que realizará el pago en efectivo.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executePayment(amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('CONFIRMAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ========== FLUJO TRANSFERENCIA ==========
  void _showTransferPayment(double amount) {
    final comprobanteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  )),
                  const SizedBox(height: 16),
                  const Center(child: Text('🏦 Transferencia Bancaria', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 4),
                  Center(child: Text('Total: Bs. ${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w600))),
                  const SizedBox(height: 20),

                  const Text('Datos de la cuenta:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),

                  _buildBankRow('Banco', 'Banco Nacional de Bolivia'),
                  _buildBankRow('Tipo de Cuenta', 'Caja de Ahorro'),
                  _buildBankRow('Nro. de Cuenta', '4500-123456-001'),
                  _buildBankRow('Titular', 'Emergencias Vehiculares SRL'),
                  _buildBankRow('Moneda', 'Bolivianos (BOB)'),
                  _buildBankRow('Monto', 'Bs. ${amount.toStringAsFixed(2)}'),

                  const SizedBox(height: 20),
                  const Text('Nro. de Comprobante:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: comprobanteController,
                    decoration: InputDecoration(
                      hintText: 'Ingresa el número de comprobante',
                      prefixIcon: const Icon(Icons.receipt_long),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (comprobanteController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ingresa el número de comprobante')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        _executePayment(amount);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('CONFIRMAR TRANSFERENCIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pendiente': return 'PENDIENTE';
      case 'buscando_taller': return 'BUSCANDO TALLER';
      case 'taller_asignado': return 'TALLER ASIGNADO';
      case 'en_camino': return 'MECÁNICO EN CAMINO';
      case 'en_atencion': return 'EN ATENCIÓN';
      case 'finalizado': return 'FINALIZADO';
      case 'cancelado': return 'CANCELADO';
      default: return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendiente': return Colors.orange;
      case 'buscando_taller': return Colors.amber;
      case 'taller_asignado': return Colors.cyan;
      case 'en_camino': return Colors.blue;
      case 'en_atencion': return Colors.purple;
      case 'finalizado': return Colors.green;
      case 'cancelado': return Colors.red;
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

    final status = _incident!['status'] ?? 'pendiente';
    final aiSummary = _incident!['ai_summary'] ?? 'Procesando análisis de IA...';
    final workshopId = _incident!['workshop_id'];
    final technicianId = _incident!['technician_id'];
    final estimatedArrival = _incident!['estimated_arrival_minutes'];
    final priority = _incident!['priority'] ?? 'medium';
    final incidentType = _incident!['incident_type'] ?? 'other';
    final finalCost = _incident!['final_cost'];
    final payment = _incident!['payment'];
    final isPaid = payment != null && payment['payment_status'] == 'completed';
    final cancellationFee = _incident!['cancellation_fee'];
    final showServicePayment = status == 'finalizado' && finalCost != null && (finalCost as num) > 0;
    final showPenaltyPayment = status == 'cancelado' && cancellationFee != null && (cancellationFee as num) > 0;
    final double paymentAmount = showServicePayment
        ? (finalCost as num).toDouble()
        : (showPenaltyPayment ? (cancellationFee as num).toDouble() : 0.0);
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
                      status == 'finalizado' ? Icons.check_circle : Icons.sync,
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
                              Flexible(
                                child: Text(
                                  'Tiempo estimado de llegada: ~$estimatedArrival min',
                                  style: const TextStyle(color: AppTheme.accentNeon, fontWeight: FontWeight.bold, fontSize: 15),
                                  textAlign: TextAlign.center,
                                ),
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
              (status == 'en_camino' || status == 'en_atencion' || status == 'finalizado') ? (status == 'en_camino' ? 'Técnico en camino' : 'Técnico en lugar') : 'Pendiente',
              status == 'en_camino' || status == 'en_atencion' || status == 'finalizado',
            ),
            _buildTimelineItem(
              'Completado',
              status == 'finalizado' ? 'Servicio finalizado' : 'Pendiente',
              status == 'finalizado',
            ),

            const SizedBox(height: 30),

            // Sección de Pago (cuando el taller completó y puso precio O cuando se canceló con penalización)
            if (showServicePayment || showPenaltyPayment) ...[
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
                        isPaid
                            ? '✅ PAGADO'
                            : (showPenaltyPayment ? '💳 Pago de Penalización' : '💳 Pago del Servicio'),
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
                              'Bs. ${paymentAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              showPenaltyPayment ? 'Tarifa de reconocimiento por cancelación' : 'Monto total del servicio',
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
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
                            onPressed: (_isPaymentLoading || _selectedPaymentMethod.isEmpty) ? null : _showPaymentFlow,
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

            // Botones de Acción del flujo Fase 2
            if (status == 'pendiente' || status == 'buscando_taller') ...[
              FadeInUp(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuotationsScreen(
                            incidentId: widget.incidentId,
                            incidentDescription: _incident?['description'] ?? _incident?['audio_transcription'],
                          ),
                        ),
                      ).then((_) => _loadDetail());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentNeon,
                    ),
                    child: const Text('VER COTIZACIONES / OFERTAS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (status == 'taller_asignado' || status == 'en_camino' || status == 'en_atencion') ...[
              FadeInUp(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrackingScreen(
                            incidentId: widget.incidentId,
                          ),
                        ),
                      ).then((_) => _loadDetail());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNeon,
                    ),
                    child: const Text('SEGUIR EN VIVO (MAPA)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (status == 'pendiente' || status == 'buscando_taller' || status == 'taller_asignado' || status == 'en_camino' || status == 'en_atencion')
              FadeInUp(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _cancelIncident,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
