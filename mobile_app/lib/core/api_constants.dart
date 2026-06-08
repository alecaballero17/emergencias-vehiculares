import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  /// Detecta automáticamente la URL correcta según la plataforma:
  /// - Web (Chrome): usa localhost
  /// - Emulador Android: usa 10.0.2.2
  /// - Dispositivo físico: usa la IP local de la red WiFi
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    // Para Android físico/emulador:
    // Cambia esta IP por la de tu computadora (ver con ipconfig)
    // Emulador: 10.0.2.2 | Físico: tu IP WiFi (ej: 192.168.100.144)
    const String pcIp = '192.168.100.144';
    return 'http://$pcIp:8000/api';
  }

  // Endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register/user';
  static String get vehicles => '$baseUrl/vehicles/';
  static String get incidents => '$baseUrl/incidents/';
  static String get profile => '$baseUrl/users/me';
}
