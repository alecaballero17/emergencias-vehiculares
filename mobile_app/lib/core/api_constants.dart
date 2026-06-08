import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  /// Detecta automáticamente la URL correcta según la plataforma:
  /// - Web (Chrome): usa localhost
  /// - Emulador Android: usa 10.0.2.2
  /// - Dispositivo físico: usa la IP local de la red WiFi
  static String get baseUrl {
    // URL de producción en Render
    return 'https://emergencias-api.onrender.com/api';
  }

  // Endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register/user';
  static String get vehicles => '$baseUrl/vehicles/';
  static String get incidents => '$baseUrl/incidents/';
  static String get profile => '$baseUrl/users/me';
}
