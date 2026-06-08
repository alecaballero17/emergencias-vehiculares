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
import '../models/incident_model.dart';
import '../services/incident_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_service.dart';
import '../services/tow_truck_service.dart';
import 'quotations_screen.dart';

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

      final isOnline = ConnectivityService().isOnline;
      Position position;

      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: isOnline ? 8 : 3),
        );
      } catch (e) {
        debugPrint("[Offline] Error al obtener posición en tiempo real: $e. Intentando última conocida...");
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          position = lastKnown;
        } else {
          throw Exception('No se pudo obtener la ubicación GPS. Por favor activa la ubicación en tu dispositivo.');
        }
      }

      bool requiresTowTruck = false;
      double? towTruckCost;

      if (isOnline) {
        final selection = await _showTowTruckSelectionDialog(position);
        if (selection == null) {
          // El usuario canceló todo el reporte
          return;
        }
        requiresTowTruck = selection['requiresTowTruck'] as bool;
        towTruckCost = selection['towTruckCost'] as double?;
      } else {
        final bool? selectTow = await _showOfflineTowSelectionDialog();
        if (selectTow == null) {
          // El usuario canceló todo el reporte
          return;
        }
        requiresTowTruck = selectTow;
      }

      // 3. Enviar al Backend (verificar conexión primero)
      if (!isOnline) {
        await OfflineService.instance.saveOfflineIncident(
          latitude: position.latitude,
          longitude: position.longitude,
          vehicleId: widget.selectedVehicle.id,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          audioPath: _audioPath,
          imagePaths: _selectedImages.map((img) => img.path).toList(),
          requiresTowTruck: requiresTowTruck,
          towTruckCost: towTruckCost,
        );
        if (mounted) {
          _showOfflineSuccess();
        }
        return;
      }

      final result = await _incidentService.reportIncident(
        latitude: position.latitude,
        longitude: position.longitude,
        vehicleId: widget.selectedVehicle.id,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        audioPath: _audioPath,
        imageFiles: _selectedImages,
        requiresTowTruck: requiresTowTruck,
        towTruckCost: towTruckCost,
      );

      if (result != null && mounted) {
        final incidentId = result['id'] as int;
        final description = (result['description'] as String?) ?? (result['audio_transcription'] as String?);
        _showSuccess(incidentId, description);
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

  Future<Map<String, dynamic>?> _showTowTruckSelectionDialog(Position position) async {
    final towService = TowTruckService();
    TowTruckEstimate? estimate;
    bool apiFailed = false;

    // Mostrar loading modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: AppTheme.cardBg,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryNeon),
                SizedBox(height: 16),
                Text(
                  'Calculando costo de grúa...',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      estimate = await towService.estimateTowCost(
        clientLatitude: position.latitude,
        clientLongitude: position.longitude,
      );
    } catch (e) {
      debugPrint('Error calculando costo de grúa: $e');
      apiFailed = true;
    }

    if (!mounted) return null;
    Navigator.of(context).pop(); // Quitar loading dialog

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.local_shipping, color: AppTheme.primaryNeon),
                  SizedBox(width: 10),
                  Text(
                    '¿Necesitas Grúa?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Puedes solicitar el servicio de grúa en tu reporte de emergencia actual.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (apiFailed) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No pudimos calcular la tarifa estimada para tu ubicación actual, pero puedes solicitarla igualmente.',
                              style: TextStyle(color: Colors.orange, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (estimate != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNeon.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimación de Grúa:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                          ),
                          const Divider(color: Colors.white24, height: 16),
                          _buildEstimateRow('Distancia estimada:', '${estimate.distanceKm.toStringAsFixed(1)} km'),
                          _buildEstimateRow('Tiempo de llegada:', '${estimate.estimatedTimeMinutes} min'),
                          _buildEstimateRow('Tarifa Base:', 'BOB ${estimate.baseCost.toStringAsFixed(2)}'),
                          _buildEstimateRow('Costo Distancia:', 'BOB ${estimate.distanceCost.toStringAsFixed(2)}'),
                          const Divider(color: Colors.white24, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Costo Total Grúa:',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNeon, fontSize: 14),
                              ),
                              Text(
                                'BOB ${estimate.totalCost.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNeon, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    '¿Deseas agregar la grúa al reporte?',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsOverflowButtonSpacing: 8,
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'requiresTowTruck': true,
                      'towTruckCost': estimate?.totalCost ?? 0.0,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNeon,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    apiFailed ? 'Sí, Solicitar Grúa' : 'Sí, con Grúa (BOB ${estimate?.totalCost.toStringAsFixed(2)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'requiresTowTruck': false,
                      'towTruckCost': null,
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('No, solo Asistencia', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null); // Cancelar envío
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                  ),
                  child: const Text('Cancelar Reporte', style: TextStyle(fontSize: 12)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _showOfflineTowSelectionDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 10),
            Text(
              '¿Necesitas Grúa?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          '⚠️ Modo sin conexión activo. No podemos calcular el costo de la grúa en este momento, pero puedes solicitarla igualmente. Se cotizará cuando el reporte sea enviado.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNeon,
              foregroundColor: Colors.black,
            ),
            child: const Text('Sí, Solicitar Grúa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white30),
              foregroundColor: Colors.white,
            ),
            child: const Text('No, solo asistencia'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Cancelar Reporte'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSuccess(int incidentId, String? description) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('✅ Emergencia Reportada'),
        content: const Text('Un taller ha sido notificado y un técnico está siendo asignado. Presione abajo para ver ofertas.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar Dialog
              Navigator.of(context).pop(); // Volver al Home
              // Navegar a Cotizaciones
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuotationsScreen(
                    incidentId: incidentId,
                    incidentDescription: description,
                  ),
                ),
              );
            },
            child: const Text('Ver Cotizaciones'),
          )
        ],
      ),
    );
  }

  void _showOfflineSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(
              child: Text('Emergencia Guardada'),
            ),
          ],
        ),
        content: const Text(
          '⚠️ Modo sin conexión activo.\n\n'
          'Su reporte se ha guardado localmente en el dispositivo. Se sincronizará y enviará automáticamente al servidor tan pronto como se recupere la conexión a internet.',
        ),
        actions: [
          ElevatedButton(
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
