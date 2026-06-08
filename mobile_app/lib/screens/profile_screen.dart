import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/offline_service.dart';
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
                      
                      const SizedBox(height: 20),
                      FadeInLeft(
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _exportBackup,
                                icon: const Icon(Icons.backup),
                                label: const Text('EXPORTAR'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cardBg,
                                  foregroundColor: AppTheme.primaryNeon,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _importBackup,
                                icon: const Icon(Icons.settings_backup_restore),
                                label: const Text('IMPORTAR'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cardBg,
                                  foregroundColor: AppTheme.primaryNeon,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

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

  void _exportBackup() {
    final String data = OfflineService.instance.exportLocalData();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exportar Datos Locales (Hive)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Copia el siguiente texto JSON para respaldar tus incidentes guardados sin conexión:'),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: data),
                readOnly: true,
                maxLines: 5,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'JSON de Respaldo',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: data));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copiado al portapapeles')),
                );
                Navigator.pop(context);
              },
              child: const Text('COPIAR'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CERRAR'),
            ),
          ],
        );
      },
    );
  }

  void _importBackup() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restaurar Datos Locales (Hive)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pega el texto JSON de tu respaldo para restaurar los incidentes:'),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 5,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Pega el JSON aquí...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isEmpty) return;
                try {
                  await OfflineService.instance.importLocalData(text);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Datos locales restaurados con éxito')),
                    );
                  }
                  Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ JSON inválido o corrupto')),
                    );
                  }
                }
              },
              child: const Text('RESTAURAR'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
          ],
        );
      },
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
