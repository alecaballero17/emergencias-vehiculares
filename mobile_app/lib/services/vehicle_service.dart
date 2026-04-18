import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';
import '../models/vehicle_model.dart';

class VehicleService {
  final Dio _dio = Dio();

  Future<List<Vehicle>> getMyVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return [];

      final response = await _dio.get(
        ApiConstants.vehicles,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => Vehicle.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error obteniendo vehículos: $e');
      return [];
    }
  }
}
