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
        await _saveAuth(authData);
        return authData;
      }
      return null;
    } catch (e) {
      print('Error en login: $e');
      return null;
    }
  }

  Future<AuthResponse?> registerUser({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
        },
      );

      if (response.statusCode == 201) {
        // Registro exitoso -> Ahora hacemos login automático
        return await login(email, password);
      }
      return null;
    } catch (e) {
      print('Error en registro: $e');
      return null;
    }
  }

  Future<User?> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _dio.get(
        ApiConstants.profile,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error obteniendo perfil: $e');
      return null;
    }
  }

  Future<void> _saveAuth(AuthResponse authData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', authData.accessToken);
    await prefs.setString('role', authData.role);
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
