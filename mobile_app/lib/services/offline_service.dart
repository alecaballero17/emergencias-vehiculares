import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'incident_service.dart';
import 'connectivity_service.dart';
import 'local_notification_service.dart';

class OfflineService {
  static OfflineService? _instance;
  static OfflineService get instance {
    if (_instance == null) {
      throw Exception("OfflineService must be initialized first");
    }
    return _instance!;
  }

  static Future<void> init(Box box) async {
    _instance = OfflineService._(
      box: box,
      incidentService: IncidentService(),
      connectivityService: ConnectivityService(),
    );
  }

  final Box _box;
  final IncidentService _incidentService;
  final ConnectivityService _connectivityService;
  bool _isSyncing = false;

  OfflineService._({
    required Box box,
    required IncidentService incidentService,
    required ConnectivityService connectivityService,
  })  : _box = box,
        _incidentService = incidentService,
        _connectivityService = connectivityService {
    // Sincronizar automáticamente al recuperar conexión
    _connectivityService.isOnlineStream.listen((isOnline) {
      if (isOnline) {
        debugPrint("[OfflineService] Conexión detectada. Sincronizando incidentes offline...");
        syncPendingIncidents();
      }
    });
  }

  Future<String> saveOfflineIncident({
    required double latitude,
    required double longitude,
    int? vehicleId,
    String? description,
    String? audioPath,
    List<String>? imagePaths,
  }) async {
    final String localUuid = const Uuid().v4();
    final Map<String, dynamic> offlineData = {
      'id': localUuid,
      'latitude': latitude,
      'longitude': longitude,
      'vehicle_id': vehicleId,
      'description': description,
      'audioPath': audioPath,
      'imagePaths': imagePaths ?? [],
      'created_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending', // pending, syncing, synced, error
    };

    await _box.put(localUuid, offlineData);
    debugPrint("[OfflineService] Incidente guardado localmente: $localUuid");
    return localUuid;
  }

  List<Map<String, dynamic>> getPendingIncidents() {
    return _box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> syncPendingIncidents() async {
    if (_isSyncing) return;
    if (!_connectivityService.isOnline) return;

    final pending = getPendingIncidents()
        .where((item) => item['sync_status'] == 'pending' || item['sync_status'] == 'error')
        .toList();

    if (pending.isEmpty) return;

    _isSyncing = true;
    debugPrint("[OfflineService] Sincronizando ${pending.length} incidentes pendientes...");

    for (var item in pending) {
      final String id = item['id'];
      try {
        item['sync_status'] = 'syncing';
        await _box.put(id, item);

        final List<String> imgPaths = List<String>.from(item['imagePaths'] ?? []);
        final List<XFile> imageFiles = imgPaths.map((path) => XFile(path)).toList();

        final result = await _incidentService.reportIncident(
          latitude: item['latitude'] as double,
          longitude: item['longitude'] as double,
          vehicleId: item['vehicle_id'] as int?,
          description: item['description'] as String?,
          audioPath: item['audioPath'] as String?,
          imageFiles: imageFiles,
          localUuid: id,
        );

        if (result != null) {
          debugPrint("[OfflineService] Incidente $id sincronizado exitosamente!");
          item['sync_status'] = 'synced';
          await _box.delete(id); 

          // Notificar al usuario nativamente
          await LocalNotificationService().showNotification(
            id: id.hashCode,
            title: '🚨 Reporte Sincronizado',
            body: 'Tu emergencia guardada offline se ha enviado al servidor con éxito.',
          );
        } else {
          throw Exception("El servidor no devolvió respuesta");
        }
      } catch (e) {
        debugPrint("[OfflineService] Error sincronizando incidente $id: $e");
        item['sync_status'] = 'error';
        await _box.put(id, item);

        // Notificar el fallo nativamente
        await LocalNotificationService().showNotification(
          id: id.hashCode,
          title: '⚠️ Error de Sincronización',
          body: 'No pudimos enviar tu reporte offline. Se reintentará cuando la conexión sea estable.',
        );
      }
    }

    _isSyncing = false;
  }

  Future<void> deleteOfflineIncident(String id) async {
    await _box.delete(id);
    debugPrint("[OfflineService] Incidente offline eliminado localmente: $id");
  }
}
