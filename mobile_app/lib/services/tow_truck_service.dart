import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/incident_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

/// Servicio para cálculo de costos de grúa
class TowTruckService {
  static String get baseUrl => '${ApiConstants.baseUrl}/tow-truck';
  static const String tokenKey = 'token';

  /// Obtener estimación de grúa para un taller específico
  Future<TowTruckEstimate> estimateTowCost({
    required double clientLatitude,
    required double clientLongitude,
    int? workshopId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);

      final body = {
        'client_latitude': clientLatitude,
        'client_longitude': clientLongitude,
        if (workshopId != null) 'workshop_id': workshopId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/estimate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return TowTruckEstimate.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error estimando costo de grúa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en TowTruckService.estimateTowCost: $e');
    }
  }

  /// Obtener los 5 talleres más cercanos con estimaciones
  Future<List<NearestWorkshop>> getNearestWorkshops({
    required double clientLatitude,
    required double clientLongitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);

      final body = {
        'client_latitude': clientLatitude,
        'client_longitude': clientLongitude,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/nearest-workshops'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((w) => NearestWorkshop.fromJson(w)).toList();
      } else {
        throw Exception(
            'Error obteniendo talleres cercanos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en TowTruckService.getNearestWorkshops: $e');
    }
  }

  /// Formatear costo para mostrar
  String formatCost(double cost) {
    return 'BOB ${cost.toStringAsFixed(2)}';
  }

  /// Formatear tiempo estimado
  String formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}
