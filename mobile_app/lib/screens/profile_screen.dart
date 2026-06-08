import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
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

  Future<void> _exportBackup() async {
    final String data = OfflineService.instance.exportLocalData();

    try {
      // Guardar localmente en la carpeta temporal
      final tempDir = await getTemporaryDirectory();
      final file = io.File('${tempDir.path}/respaldo_emergencias_offline.json');
      await file.writeAsString(data);

      // Compartir nativamente con share_plus (abre el menú para guardar archivo o enviar por redes)
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Respaldo de Incidentes Fuera de Línea - Emergencias Vehiculares',
      );
    } catch (e) {
      // Fallback a copiar al portapapeles si compartir falla
      Clipboard.setData(ClipboardData(text: data));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copiado al portapapeles (Compartir falló)')),
        );
      }
    }
  }

  void _importBackup() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Restaurar Datos (Importar)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pega el contenido del archivo JSON de respaldo que exportaste anteriormente para restaurar la cola de incidentes offline.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 6,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Pega el JSON aquí...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isEmpty) return;
                try {
                  await OfflineService.instance.importLocalData(text);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Incidentes locales restaurados con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Formato de respaldo JSON inválido'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
                foregroundColor: Colors.black,
              ),
              child: const Text('RESTAURAR', style: TextStyle(fontWeight: FontWeight.bold)),
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
