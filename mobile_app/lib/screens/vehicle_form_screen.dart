import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_theme.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';

class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicle; // Si es null, estamos creando. Si no, editando.
  const VehicleFormScreen({super.key, this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _service = VehicleService();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();
  
  bool _isLoading = false;
  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _brandController.text = widget.vehicle!.brand;
      _modelController.text = widget.vehicle!.model;
      _yearController.text = widget.vehicle!.year.toString();
      _colorController.text = widget.vehicle!.color;
      _plateController.text = widget.vehicle!.plateNumber;
    }
  }

  Future<void> _save() async {
    if (_brandController.text.isEmpty || _plateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La Marca y la Placa son obligatorias')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final data = {
      'brand': _brandController.text,
      'model': _modelController.text,
      'year': int.tryParse(_yearController.text) ?? 2024,
      'color': _colorController.text,
      'license_plate': _plateController.text,
    };

    bool success;
    if (_isEditing) {
      success = await _service.updateVehicle(widget.vehicle!.id, data);
    } else {
      success = await _service.registerVehicle(data);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true); // Retornar true para refrescar la lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar vehículo. Revisa la placa.')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('¿Eliminar vehículo?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _service.deleteVehicle(widget.vehicle!.id);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Vehículo' : 'Registrar Vehículo'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
              onPressed: _delete,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            FadeInDown(
              child: const Icon(Icons.directions_car, size: 60, color: AppTheme.primaryNeon),
            ),
            const SizedBox(height: 30),
            
            _buildField(_brandController, 'Marca (Ej: Toyota)', Icons.business),
            const SizedBox(height: 20),
            _buildField(_modelController, 'Modelo (Ej: Corolla)', Icons.model_training),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildField(_yearController, 'Año', Icons.calendar_today, isNumber: true)),
                const SizedBox(width: 20),
                Expanded(child: _buildField(_colorController, 'Color', Icons.color_lens)),
              ],
            ),
            const SizedBox(height: 20),
            _buildField(_plateController, 'Placa (Ej: ABC-1234)', Icons.pin, isReadOnly: _isEditing),
            
            const SizedBox(height: 50),
            
            FadeInUp(
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(_isEditing ? 'ACTUALIZAR DATOS' : 'REGISTRAR VEHÍCULO'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, bool isReadOnly = false}) {
    return FadeInLeft(
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: isReadOnly ? Colors.white.withOpacity(0.02) : null,
        ),
      ),
    );
  }
}
