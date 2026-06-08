import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_theme.dart';
import '../services/incident_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final IncidentService _incidentService = IncidentService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;
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
      final res = await _incidentService.getAnalyticsKPIs();
      if (res != null) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      } else {
        throw Exception("Respuesta de analíticas vacía");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "No se pudieron cargar las analíticas operacionales.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analítica y KPIs'),
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: AppTheme.errorRed),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card de SLA y Cumplimiento
                        FadeInDown(
                          child: _buildSLACard(),
                        ),
                        const SizedBox(height: 20),

                        // Card de Tiempos Promedio
                        FadeInDown(
                          delay: const Duration(milliseconds: 100),
                          child: _buildTimesCard(),
                        ),
                        const SizedBox(height: 20),

                        // Distribución de Incidentes
                        FadeInDown(
                          delay: const Duration(milliseconds: 200),
                          child: _buildIncidentTypesCard(),
                        ),
                        const SizedBox(height: 20),

                        // Ranking de Talleres
                        FadeInDown(
                          delay: const Duration(milliseconds: 300),
                          child: _buildWorkshopRankingCard(),
                        ),
                        const SizedBox(height: 20),

                        // Casos Cancelados y Expirados
                        FadeInDown(
                          delay: const Duration(milliseconds: 400),
                          child: _buildCancellationsCard(),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSLACard() {
    final slaData = _data?['sla'] ?? {};
    final percent = slaData['sla_percent'] ?? 0.0;
    final compliant = slaData['compliant'] ?? 0;
    final total = slaData['total'] ?? 0;

    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cumplimiento SLA',
                  style: TextStyle(
                    color: AppTheme.accentNeon,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Porcentaje de asistencias que llegaron a tiempo según el estimado inicial.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  '$compliant de $total servicios a tiempo',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentNeon),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimesCard() {
    final assignment = _data?['assignment'] ?? {};
    final arrival = _data?['arrival'] ?? {};

    final avgAssign = assignment['avg_minutes'] ?? 0.0;
    final avgArrival = arrival['avg_minutes'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⏱️ Tiempos Operacionales Promedio',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildTimeRow('Tiempo de Asignación', '$avgAssign min', 'Desde SOS hasta taller asignado'),
          const Divider(color: Colors.white10, height: 24),
          _buildTimeRow('Tiempo de Llegada', '$avgArrival min', 'Desde asignación hasta arribo físico'),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String title, String value, String desc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryNeon),
        ),
      ],
    );
  }

  Widget _buildIncidentTypesCard() {
    final typesData = _data?['types'] ?? {};
    final list = typesData['data'] as List<dynamic>? ?? [];
    final total = typesData['total'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🤖 Incidentes por Tipo (Clasificación IA)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const Center(child: Text('Sin datos disponibles', style: TextStyle(color: AppTheme.textSecondary)))
          else
            ...list.map((item) {
              final count = item['count'] ?? 0;
              final percent = total > 0 ? (count / total) : 0.0;
              final label = item['label'] ?? '';
              final type = item['type'] ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_getTypeEmoji(type)} $label', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        Text('$count (${(percent * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryNeon),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWorkshopRankingCard() {
    final wsData = _data?['workshops'] ?? {};
    final list = wsData['data'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Eficiencia de Talleres',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const Center(child: Text('No hay talleres registrados', style: TextStyle(color: AppTheme.textSecondary)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 20),
              itemBuilder: (context, index) {
                final ws = list[index];
                final name = ws['workshop_name'] ?? 'Taller';
                final total = ws['total_incidents'] ?? 0;
                final rate = ws['completion_rate'] ?? 0.0;
                final avgResp = ws['avg_response_minutes'] ?? 0.0;

                return Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryNeon.withOpacity(0.1),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Asignados: $total  ·  Soporte: $avgResp min', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(
                      '$rate%',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.accentNeon, fontSize: 14),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCancellationsCard() {
    final cancellation = _data?['cancellation'] ?? {};
    final rate = cancellation['cancellation_rate'] ?? 0.0;
    final cancelled = cancellation['cancelled'] ?? 0;
    final expired = cancellation['expired'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️ Cancelaciones & Tiempos Expirados',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tasa de Cancelación', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Servicios abortados: $cancelled', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
              Text(
                '$rate%',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.errorRed),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Servicios Expirados', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 2),
                  const Text('Sin atención por más de 2 horas', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
              Text(
                '$expired',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTypeEmoji(String type) {
    switch (type) {
      case 'battery':
        return '🔋';
      case 'tire':
        return '🛞';
      case 'crash':
        return '💥';
      case 'engine':
        return '🔧';
      case 'other':
      default:
        return '❓';
    }
  }
}
