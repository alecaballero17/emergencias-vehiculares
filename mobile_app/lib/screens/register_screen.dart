import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _tenants = [];
  int? _selectedTenantId;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    final list = await _authService.getTenants();
    if (mounted) {
      setState(() {
        _tenants = list;
        if (list.isNotEmpty) {
          _selectedTenantId = list.first['id'];
        }
      });
    }
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _nameController.text.isEmpty || 
        _selectedTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena los campos obligatorios')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await _authService.registerUser(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _nameController.text,
      phone: _phoneController.text,
      tenantId: _selectedTenantId!,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al registrar. Intenta con otro correo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: AppTheme.primaryNeon),
              ),
            ),
            const SizedBox(height: 20),
            FadeInDown(
              child: const Text(
                'Crea tu cuenta',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              child: const Text('Únete a la red de emergencias vehiculares', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 30),
            
            if (_tenants.isNotEmpty) ...[
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: DropdownButtonFormField<int>(
                  value: _selectedTenantId,
                  dropdownColor: AppTheme.cardBg,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Red de Emergencias (Tenant)',
                    prefixIcon: Icon(Icons.hub),
                  ),
                  items: _tenants.map<DropdownMenuItem<int>>((dynamic tenant) {
                    return DropdownMenuItem<int>(
                      value: tenant['id'] as int,
                      child: Text(tenant['name'] as String),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    setState(() {
                      _selectedTenantId = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            ),
            const SizedBox(height: 20),
             FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: TextField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Teléfono (Opcional)',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              delay: const Duration(milliseconds: 700),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Text('REGISTRARME'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
