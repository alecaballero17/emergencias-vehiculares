import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class IncidentService {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> reportIncident({
    required double latitude,
    required double longitude,
    int? vehicleId,
    String? description,
    String? audioPath,
    List<XFile>? imageFiles,
    String? localUuid,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      Map<String, dynamic> formDataMap = {
        'latitude': latitude,
        'longitude': longitude,
        'vehicle_id': vehicleId,
        'description': description ?? 'Emergencia reportada desde App Móvil',
      };

      if (localUuid != null) {
        formDataMap['local_uuid'] = localUuid;
      }

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
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        debugPrint('ERROR DE DIO: ${e.type} - ${e.message}');
        debugPrint('Datos de error: ${e.response?.data}');
        if (e.response?.statusCode == 201 || e.response?.statusCode == 200) {
          return e.response?.data;
        }
      } else {
        debugPrint('Error desconocido reportando incidente: $e');
      }
      return null;
    }
  }

  Future<List<dynamic>> getQuotations(int incidentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return [];

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/quotations/$incidentId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data ?? [];
    } catch (e) {
      debugPrint('Error obteniendo cotizaciones: $e');
      return [];
    }
  }

  Future<bool> acceptQuotation(int quotationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await _dio.put(
        '${ApiConstants.baseUrl}/quotations/$quotationId/accept',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error al aceptar cotización: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCostEstimate(String description, {String? incidentType}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return null;

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/ai/estimate-cost',
        data: {
          'description': description,
          if (incidentType != null) 'incident_type': incidentType,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data;
    } catch (e) {
      debugPrint('Error al estimar costos con IA: $e');
      return null;
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
      // debugPrint('Error obteniendo detalle: $e');
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
      // debugPrint('Error obteniendo historial: $e');
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
      // debugPrint('Error cancelando incidente: $e');
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

  Future<String?> createPaymentIntent({
    required int incidentId,
    required double amount,
    String paymentMethod = 'paralela',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return null;

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/payments/create-intent',
        data: {
          'incident_id': incidentId,
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
      if (response.statusCode == 201) {
        return response.data['payment_intent_id'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error creando intención de pago: $e');
      return null;
    }
  }

  Future<bool> confirmPayment({
    required String paymentIntentId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/payments/confirm/$paymentIntentId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error confirmando pago: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getVoiceReport(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return null;

      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath, filename: 'voice_query.wav'),
      });

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/ai/voice-report?client_context=true',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error en reporte de voz: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAnalyticsKPIs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return null;

      final headers = {'Authorization': 'Bearer $token'};
      
      final responses = await Future.wait([
        _dio.get('${ApiConstants.baseUrl}/analytics/summary', options: Options(headers: headers)),
        _dio.get('${ApiConstants.baseUrl}/analytics/assignment-time', options: Options(headers: headers)),
        _dio.get('${ApiConstants.baseUrl}/analytics/arrival-time', options: Options(headers: headers)),
        _dio.get('${ApiConstants.baseUrl}/analytics/sla-compliance', options: Options(headers: headers)),
        _dio.get('${ApiConstants.baseUrl}/analytics/incidents-by-type', options: Options(headers: headers)),
        _dio.get('${ApiConstants.baseUrl}/analytics/top-workshops', options: Options(headers: headers)),
        _dio.get('${ApiConstants.baseUrl}/analytics/cancelled-cases', options: Options(headers: headers)),
      ]);

      return {
        'summary': responses[0].data,
        'assignment': responses[1].data,
        'arrival': responses[2].data,
        'sla': responses[3].data,
        'types': responses[4].data,
        'workshops': responses[5].data,
        'cancellation': responses[6].data,
      };
    } catch (e) {
      debugPrint('Error obteniendo analíticas: $e');
      return null;
    }
  }
}
