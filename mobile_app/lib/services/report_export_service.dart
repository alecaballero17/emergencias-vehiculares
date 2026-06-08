import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../core/api_constants.dart';

/// Servicio para exportar reportes del sistema en PDF, HTML y Excel.
/// Descarga archivos desde el backend y los guarda en el dispositivo.
class ReportExportService {
  final Dio _dio = Dio();

  /// Extensiones y MIME types por formato
  static const Map<String, String> _extensions = {
    'pdf': 'pdf',
    'html': 'html',
    'excel': 'xlsx',
  };

  /// Descarga reporte de incidentes en el formato especificado.
  /// Retorna la ruta del archivo descargado o null si falla.
  Future<String?> downloadIncidentsReport({
    String format = 'pdf',
    int days = 30,
  }) async {
    return _downloadReport(
      endpoint: '/reports/incidents/export',
      format: format,
      days: days,
      filenamePrefix: 'reporte_incidentes',
    );
  }

  /// Descarga reporte financiero en el formato especificado.
  /// Retorna la ruta del archivo descargado o null si falla.
  Future<String?> downloadFinancialReport({
    String format = 'pdf',
    int days = 30,
  }) async {
    return _downloadReport(
      endpoint: '/reports/financial/export',
      format: format,
      days: days,
      filenamePrefix: 'reporte_financiero',
    );
  }

  /// Descarga un reporte genérico del backend.
  Future<String?> _downloadReport({
    required String endpoint,
    required String format,
    required int days,
    required String filenamePrefix,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        debugPrint('ReportExportService: No hay token de autenticación');
        return null;
      }

      final url = '${ApiConstants.baseUrl}$endpoint?format=$format&days=$days';
      debugPrint('ReportExportService: Descargando $url');

      // Obtener directorio de descargas
      final dir = await getApplicationDocumentsDirectory();
      final ext = _extensions[format] ?? 'bin';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.path}/${filenamePrefix}_$timestamp.$ext';

      final response = await _dio.download(
        url,
        filePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': '*/*',
          },
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('ReportExportService: Archivo guardado en $filePath');
        return filePath;
      }

      debugPrint('ReportExportService: Respuesta inesperada ${response.statusCode}');
      return null;
    } catch (e) {
      if (e is DioException) {
        debugPrint('ReportExportService: Error de red: ${e.type} - ${e.message}');
        debugPrint('ReportExportService: Detalle: ${e.response?.data}');
      } else {
        debugPrint('ReportExportService: Error desconocido: $e');
      }
      return null;
    }
  }

  /// Construye la URL de descarga con token para abrir en navegador externo.
  Future<String?> getReportUrl({
    required String reportType,
    required String format,
    int days = 30,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final endpoint = reportType == 'incidents'
        ? '/reports/incidents/export'
        : '/reports/financial/export';

    return '${ApiConstants.baseUrl}$endpoint?format=$format&days=$days&token=$token';
  }
}
