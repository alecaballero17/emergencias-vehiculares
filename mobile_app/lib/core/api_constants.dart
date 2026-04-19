class ApiConstants {
  // Cuando uses el navegador (Chrome), usamos localhost
  // Si llegas a usar un emulador de Android, tendrías que usar 10.0.2.2
  static const String baseUrl = 'http://localhost:8000/api';
  
  // Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register/user';
  static const String vehicles = '$baseUrl/vehicles';
  static const String incidents = '$baseUrl/incidents';
  static const String profile = '$baseUrl/users/me';
}
