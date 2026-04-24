import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  final _descriptionController = TextEditingController();
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
    _descriptionController.dispose();
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
    try {
      if (_isRecording) {
        _stopTimer();
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _audioPath = path;
        });
        debugPrint('Grabación detenida. Path: $path');
      } else {
        if (await _audioRecorder.hasPermission()) {
          String? path;
          
          if (!kIsWeb) {
            final dir = await getTemporaryDirectory();
            path = '${dir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          }
          
          // Usamos 'opus' para Web ya que es el estándar más compatible en navegadores
          // En móvil, dejamos que el sistema elija o usamos uno común
          const config = RecordConfig(
            encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          );
          
          await _audioRecorder.start(config, path: path ?? '');
          
          _startTimer();
          setState(() {
            _isRecording = true;
            _audioPath = null;
          });
          debugPrint('Grabación iniciada...');
        } else {
          debugPrint('No hay permisos de micrófono');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Por favor, concede permiso al micrófono en el navegador')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error crítico en grabación: $e');
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
      // 1. Obtener Ubicación con Timeout de 10s
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Por favor encienda el GPS.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de GPS denegados.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de GPS denegados permanentemente.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // 2. Enviar al Backend
      final success = await _incidentService.reportIncident(
        latitude: position.latitude,
        longitude: position.longitude,
        vehicleId: widget.selectedVehicle.id,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        audioPath: _audioPath,
        imageFiles: _selectedImages,
      );

      if (success && mounted) {
        _showSuccess();
      } else {
        throw Exception('Servidor no disponible');
      }
    } catch (e) {
      String errorMsg = 'Error al enviar reporte';
      if (e is TimeoutException) {
        errorMsg = 'No se pudo obtener el GPS (Tiempo agotado)';
      } else if (e is Exception) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.errorRed,
            content: Text(errorMsg, style: const TextStyle(color: Colors.white)),
          ),
        );
      }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            
            // Botón de Grabación y Preview
            Center(
              child: Column(
                children: [
                  // CASO 1: No hay audio grabado o estamos grabando ahora
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording ? AppTheme.errorRed : AppTheme.cardBg,
                              border: Border.all(
                                color: _isRecording ? Colors.white : AppTheme.errorRed,
                                width: 2
                              ),
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
                    // CASO 2: Audio ya grabado (Mostrar Player)
                    FadeIn(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _playPauseAudio,
                              icon: Icon(
                                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, 
                                color: AppTheme.primaryNeon,
                                size: 30,
                              ),
                            ),
                            const Text(
                              'Audio listo', 
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _deleteAudio,
                              icon: const Icon(Icons.delete_forever, color: AppTheme.errorRed, size: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  Text(
                    _isRecording 
                      ? 'GRABANDO... ${_formatDuration(_recordDuration)}'
                      : (_audioPath != null ? 'Revisa tu reporte antes de enviar' : 'Toca el micro para grabar tu reporte'),
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
                            image: DecorationImage(
                              image: kIsWeb 
                                ? NetworkImage(_selectedImages[index].path) as ImageProvider
                                : FileImage(io.File(_selectedImages[index].path)) as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(), // Eliminamos el icono si la imagen carga
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
            
            const SizedBox(height: 30),
            
            // Campo de texto adicional (opcional)
            const Text('Nota adicional (opcional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Agrega detalles que consideres importantes', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ej: El auto se detuvo en la esquina, huele a quemado...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: AppTheme.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryNeon),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Botón de Envío Final
            FadeInUp(
              child: SizedBox(
                width: double.infinity,
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
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
