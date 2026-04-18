import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await _authService.getProfile();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Error al cargar perfil'))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      FadeInDown(
                        child: const Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primaryNeon,
                            child: Icon(Icons.person, size: 50, color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInDown(
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          _user!.fullName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(_user!.email, style: const TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 40),
                      
                      _buildInfoTile(Icons.phone, 'Teléfono', _user!.phone ?? 'No registrado'),
                      _buildInfoTile(Icons.badge, 'Rol', _user!.role.toUpperCase()),
                      
                      const Spacer(),
                      
                      FadeInUp(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                            child: const Text('CERRAR SESIÓN'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return FadeInLeft(
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryNeon),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
