import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';
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
    List<XFile>? imageFiles,
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
        if (kIsWeb) {
          try {
            debugPrint('Intentando obtener bytes del audio blob: $audioPath');
            // Usamos un Dio limpio para el blob para evitar conflictos de headers base
            final blobResponse = await Dio().get(audioPath, options: Options(responseType: ResponseType.bytes));
            debugPrint('Bytes de audio obtenidos: ${blobResponse.data?.length}');
            
            formDataMap['audio'] = MultipartFile.fromBytes(
              blobResponse.data,
              filename: 'emergency_audio.webm',
            );
          } catch (e) {
            debugPrint('ERROR fatal obteniendo audio: $e');
            // Continuamos sin audio si falla para ver si el resto del reporte pasa
          }
        } else {
          formDataMap['audio'] = await MultipartFile.fromFile(
            audioPath,
            filename: 'emergency_audio.m4a',
          );
        }
      }

      if (imageFiles != null && imageFiles.isNotEmpty) {
        debugPrint('Procesando ${imageFiles.length} imágenes');
        List<MultipartFile> files = [];
        for (var xFile in imageFiles) {
          if (kIsWeb) {
            final bytes = await xFile.readAsBytes();
            files.add(MultipartFile.fromBytes(bytes, filename: xFile.name));
          } else {
            files.add(await MultipartFile.fromFile(xFile.path));
          }
        }
        formDataMap['images'] = files;
      }
      
      final formData = FormData.fromMap(formDataMap);
      debugPrint('Enviando POST a ${ApiConstants.incidents}...');

      final response = await _dio.post(
        ApiConstants.incidents,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          // Aumentamos el timeout para el procesamiento de IA
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );

      debugPrint('Respuesta del servidor: ${response.statusCode}');
      return response.statusCode == 201;
    } catch (e) {
      if (e is DioException) {
        debugPrint('ERROR DE DIO: ${e.type} - ${e.message}');
        debugPrint('Datos de error: ${e.response?.data}');
      } else {
        debugPrint('Error desconocido reportando incidente: $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>?> getIncidentDetail(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return null;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/incidents/$id',
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
        '${ApiConstants.baseUrl}/incidents/$id/cancel',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error cancelando incidente: $e');
      return false;
    }
  }

  Future<bool> makePayment({
    required int incidentId,
    required double amount,
    String paymentMethod = 'mobile_payment',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/payments/$incidentId',
        data: {
          'amount': amount,
          'payment_method': paymentMethod,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.statusCode == 201;
    } catch (e) {
      if (e is DioException) {
        debugPrint('Error de pago: ${e.response?.data}');
        // Si el pago ya fue realizado, tratarlo como éxito
        final detail = e.response?.data?['detail']?.toString() ?? '';
        if (detail.contains('ya fue realizado')) {
          return true;
        }
      }
      return false;
    }
  }
}
