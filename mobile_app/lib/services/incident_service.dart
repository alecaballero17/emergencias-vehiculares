import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class IncidentService {
  final Dio _dio = Dio();

  Future<bool> reportIncident({
    required double latitude,
    required double longitude,
    int? vehicleId,
    String? description,
    String? audioPath,
    List<String>? imagePaths,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return false;

      Map<String, dynamic> formDataMap = {
        'latitude': latitude,
        'longitude': longitude,
        'vehicle_id': vehicleId,
        'description': description ?? 'Emergencia reportada desde App Móvil',
      };

      if (audioPath != null) {
        formDataMap['audio'] = await MultipartFile.fromFile(
          audioPath,
          filename: 'emergency_audio.m4a',
        );
      }

      if (imagePaths != null && imagePaths.isNotEmpty) {
        List<MultipartFile> files = [];
        for (var path in imagePaths) {
          files.add(await MultipartFile.fromFile(path));
        }
        formDataMap['images'] = files;
      }
      
      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post(
        ApiConstants.incidents,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error reportando incidente: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getIncidentDetail(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return null;

      final response = await _dio.get(
        '${ApiConstants.incidents}/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      print('Error obteniendo detalle: $e');
      return null;
    }
  }

  Future<List<dynamic>> getMyIncidents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return [];

      final response = await _dio.get(
        ApiConstants.incidents,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      print('Error obteniendo historial: $e');
      return [];
    }
  }

  Future<bool> cancelIncident(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await _dio.put(
        '${ApiConstants.incidents}/$id/cancel',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error cancelando incidente: $e');
      return false;
    }
  }
}
