import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  // Asegurar que los widgets estén inicializados si usamos servicios asíncronos antes de runApp
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EmergenciasVehicularesApp());
}

class EmergenciasVehicularesApp extends StatelessWidget {
  const EmergenciasVehicularesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergencias Vehiculares',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}
