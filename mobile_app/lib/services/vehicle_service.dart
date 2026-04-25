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
      // debugPrint('Error obteniendo vehículos: $e');
      return [];
    }
  }

  Future<bool> registerVehicle(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await _dio.post(
        ApiConstants.vehicles,
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 201;
    } catch (e) {
      // debugPrint('Error registrando vehículo: $e');
      return false;
    }
  }

  Future<bool> updateVehicle(int id, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await _dio.put(
        '${ApiConstants.vehicles}/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      // debugPrint('Error actualizando vehículo: $e');
      return false;
    }
  }

  Future<bool> deleteVehicle(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await _dio.delete(
        '${ApiConstants.vehicles}/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 204;
    } catch (e) {
      // debugPrint('Error eliminando vehículo: $e');
      return false;
    }
  }
}
