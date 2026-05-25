import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'services/offline_service.dart';

void main() async {
  // Asegurar que los widgets estén inicializados si usamos servicios asíncronos antes de runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Hive y Box offline
  await Hive.initFlutter();
  final box = await Hive.openBox('offline_incidents');
  await OfflineService.init(box);

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
