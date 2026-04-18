import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio = Dio();

  Future<AuthResponse?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final authData = AuthResponse.fromJson(response.data);
        
        // Guardar token y rol localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', authData.accessToken);
        await prefs.setString('role', authData.role);
        
        return authData;
      }
      return null;
    } catch (e) {
      print('Error en login: $e');
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
