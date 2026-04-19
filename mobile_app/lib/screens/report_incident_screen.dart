import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/app_theme.dart';
import '../models/vehicle_model.dart';
import '../services/incident_service.dart';

class ReportIncidentScreen extends StatefulWidget {
  final Vehicle selectedVehicle;
  const ReportIncidentScreen({super.key, required this.selectedVehicle});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _incidentService = IncidentService();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _imagePicker = ImagePicker();
  
  bool _isRecording = false;
  String? _audioPath;
  List<XFile> _selectedImages = [];
  bool _isSending = false;
  
  // Timer para grabación
  Timer? _timer;
  int _recordDuration = 0;
  bool _isPlaying = false;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _playPauseAudio() async {
    if (_audioPath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
      setState(() => _isPlaying = true);
      
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  void _deleteAudio() {
    setState(() {
      _audioPath = null;
      _isPlaying = false;
    });
    _audioPlayer.stop();
  }
  
  // -- Lógica de Audio --
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _stopTimer();
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
    } else {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        _startTimer();
        setState(() {
          _isRecording = true;
          _audioPath = null;
        });
      }
    }
  }

  // -- Lógica de Imágenes --
  Future<void> _pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // -- Enviar Emergencia --
  Future<void> _submitEmergency() async {
    setState(() => _isSending = true);

    try {
      // 1. Obtener Ubicación
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Enviar al Backend
      final success = await _incidentService.reportIncident(
        latitude: position.latitude,
        longitude: position.longitude,
        vehicleId: widget.selectedVehicle.id,
        audioPath: _audioPath,
        imagePaths: _selectedImages.map((e) => e.path).toList(),
      );

      if (success && mounted) {
        _showSuccess();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Permisos de ubicación necesarios')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('✅ Emergencia Reportada'),
        content: const Text('Un taller ha sido notificado y un técnico está siendo asignado.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar Dialog
              Navigator.of(context).pop(); // Volver al Home
            },
            child: const Text('Entendido'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Emergencia')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen Vehículo
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNeon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: AppTheme.primaryNeon, size: 30),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.selectedVehicle.brand, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(widget.selectedVehicle.plateNumber, style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            const Text('Evidencia de Audio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Describe el problema para que la IA lo analice', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            
            // Botón de Grabación
            Center(
              child: Column(
                children: [
                  if (_audioPath == null || _isRecording)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isRecording)
                          Pulse(
                            infinite: true,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.errorRed.withOpacity(0.2),
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: _toggleRecording,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording ? AppTheme.errorRed : AppTheme.cardBg,
                              border: Border.all(color: AppTheme.errorRed, width: 2),
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic, 
                              color: _isRecording ? Colors.white : AppTheme.errorRed,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Player Preview
                    FadeIn(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _playPauseAudio,
                              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: AppTheme.primaryNeon),
                            ),
                            const Text('Audio grabado ready', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: _deleteAudio,
                              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  Text(
                    _isRecording 
                      ? 'GRABANDO... ${_formatDuration(_recordDuration)}'
                      : (_audioPath != null ? 'Toca Play para revisar' : 'Toca para grabar reporte'),
                    style: TextStyle(
                      color: _isRecording ? AppTheme.errorRed : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Evidencia de Fotos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_a_photo, size: 18),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const Text('Captura fotos del daño o lugar', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            
            if (_selectedImages.isEmpty)
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Center(child: Text('Sin fotos seleccionadas', style: TextStyle(color: Colors.white24))),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                              image: AssetImage('assets/placeholder.png'), // Placeholder para Web, en móvil usaremos FileImage
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Nota: En una app móvil real usaríamos Image.file(File(_selectedImages[index].path))
                          // Pero para la demo en Web, mostraremos un icono si el path no es accesible directamente
                          child: const Icon(Icons.image, color: Colors.white24),
                        ),
                        Positioned(
                          top: 0,
                          right: 10,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            
            const Spacer(),
            
            // Botón de Envío Final
            FadeInUp(
              child: ElevatedButton(
                onPressed: _isSending ? null : _submitEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: _isSending 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ENVIAR REPORTE DE EMERGENCIA', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
