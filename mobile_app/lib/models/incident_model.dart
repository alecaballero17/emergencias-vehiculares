/// Modelo de Incidente para la app móvil
/// Representa una emergencia vehicular reportada
class Incident {
  final int id;
  final int userId;
  final int vehicleId;
  final double latitude;
  final double longitude;
  final String? address;
  final String? description;
  final String? audioTranscription;
  final String incidentType; // battery, tire, crash, engine, other
  final String priority; // low, medium, high, critical
  final String status; // pendiente, buscando_taller, taller_asignado, en_camino, en_atencion, finalizado, cancelado
  final String? aiSummary;
  final double? aiCostEstimateMin;
  final double? aiCostEstimateMax;
  final int? estimatedArrivalMinutes;
  final double? finalCost;
  final double? cancellationFee;
  final bool requiresTowTruck;
  final double? towTruckCost;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? searchingAt;
  final DateTime? assignedAt;
  final DateTime? enRouteAt;
  final DateTime? attendingAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  Incident({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.description,
    this.audioTranscription,
    this.incidentType = 'other',
    this.priority = 'medium',
    this.status = 'pendiente',
    this.aiSummary,
    this.aiCostEstimateMin,
    this.aiCostEstimateMax,
    this.estimatedArrivalMinutes,
    this.finalCost,
    this.cancellationFee,
    this.requiresTowTruck = false,
    this.towTruckCost,
    required this.createdAt,
    this.updatedAt,
    this.searchingAt,
    this.assignedAt,
    this.enRouteAt,
    this.attendingAt,
    this.completedAt,
    this.cancelledAt,
  });

  /// Crear desde JSON del servidor
  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      vehicleId: json['vehicle_id'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      description: json['description'] as String?,
      audioTranscription: json['audio_transcription'] as String?,
      incidentType: json['incident_type'] as String? ?? 'other',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pendiente',
      aiSummary: json['ai_summary'] as String?,
      aiCostEstimateMin: json['ai_cost_estimate_min'] as double?,
      aiCostEstimateMax: json['ai_cost_estimate_max'] as double?,
      estimatedArrivalMinutes: json['estimated_arrival_minutes'] as int?,
      finalCost: json['final_cost'] as double?,
      cancellationFee: json['cancellation_fee'] as double?,
      requiresTowTruck: json['requires_tow_truck'] as bool? ?? false,
      towTruckCost: json['tow_truck_cost'] as double?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      searchingAt: json['searching_at'] != null
          ? DateTime.parse(json['searching_at'])
          : null,
      assignedAt:
          json['assigned_at'] != null ? DateTime.parse(json['assigned_at']) : null,
      enRouteAt:
          json['en_route_at'] != null ? DateTime.parse(json['en_route_at']) : null,
      attendingAt: json['attending_at'] != null
          ? DateTime.parse(json['attending_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
    );
  }

  /// Convertir a JSON para enviar al servidor
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'description': description,
      'audio_transcription': audioTranscription,
      'incident_type': incidentType,
      'priority': priority,
      'status': status,
      'ai_summary': aiSummary,
      'ai_cost_estimate_min': aiCostEstimateMin,
      'ai_cost_estimate_max': aiCostEstimateMax,
      'estimated_arrival_minutes': estimatedArrivalMinutes,
      'final_cost': finalCost,
      'cancellation_fee': cancellationFee,
      'requires_tow_truck': requiresTowTruck,
      'tow_truck_cost': towTruckCost,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'searching_at': searchingAt?.toIso8601String(),
      'assigned_at': assignedAt?.toIso8601String(),
      'en_route_at': enRouteAt?.toIso8601String(),
      'attending_at': attendingAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }

  /// Copiar con cambios
  Incident copyWith({
    int? id,
    int? userId,
    int? vehicleId,
    double? latitude,
    double? longitude,
    String? address,
    String? description,
    String? audioTranscription,
    String? incidentType,
    String? priority,
    String? status,
    String? aiSummary,
    double? aiCostEstimateMin,
    double? aiCostEstimateMax,
    int? estimatedArrivalMinutes,
    double? finalCost,
    double? cancellationFee,
    bool? requiresTowTruck,
    double? towTruckCost,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? searchingAt,
    DateTime? assignedAt,
    DateTime? enRouteAt,
    DateTime? attendingAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    return Incident(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      description: description ?? this.description,
      audioTranscription: audioTranscription ?? this.audioTranscription,
      incidentType: incidentType ?? this.incidentType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      aiSummary: aiSummary ?? this.aiSummary,
      aiCostEstimateMin: aiCostEstimateMin ?? this.aiCostEstimateMin,
      aiCostEstimateMax: aiCostEstimateMax ?? this.aiCostEstimateMax,
      estimatedArrivalMinutes:
          estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      finalCost: finalCost ?? this.finalCost,
      cancellationFee: cancellationFee ?? this.cancellationFee,
      requiresTowTruck: requiresTowTruck ?? this.requiresTowTruck,
      towTruckCost: towTruckCost ?? this.towTruckCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      searchingAt: searchingAt ?? this.searchingAt,
      assignedAt: assignedAt ?? this.assignedAt,
      enRouteAt: enRouteAt ?? this.enRouteAt,
      attendingAt: attendingAt ?? this.attendingAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  String toString() {
    return 'Incident(id: $id, status: $status, requiresTowTruck: $requiresTowTruck)';
  }
}

/// Modelo para respuesta de estimación de grúa
class TowTruckEstimate {
  final double distanceKm;
  final double baseCost;
  final double distanceCost;
  final double totalCost;
  final int estimatedTimeMinutes;

  TowTruckEstimate({
    required this.distanceKm,
    required this.baseCost,
    required this.distanceCost,
    required this.totalCost,
    required this.estimatedTimeMinutes,
  });

  factory TowTruckEstimate.fromJson(Map<String, dynamic> json) {
    return TowTruckEstimate(
      distanceKm: (json['distance_km'] as num).toDouble(),
      baseCost: (json['base_cost'] as num).toDouble(),
      distanceCost: (json['distance_cost'] as num).toDouble(),
      totalCost: (json['total_cost'] as num).toDouble(),
      estimatedTimeMinutes: json['estimated_time_minutes'] as int,
    );
  }
}

/// Modelo para taller cercano con estimación
class NearestWorkshop {
  final int workshopId;
  final String workshopName;
  final double distanceKm;
  final double estimatedCost;
  final int estimatedTimeMinutes;

  NearestWorkshop({
    required this.workshopId,
    required this.workshopName,
    required this.distanceKm,
    required this.estimatedCost,
    required this.estimatedTimeMinutes,
  });

  factory NearestWorkshop.fromJson(Map<String, dynamic> json) {
    return NearestWorkshop(
      workshopId: json['workshop_id'] as int,
      workshopName: json['workshop_name'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      estimatedCost: (json['estimated_cost'] as num).toDouble(),
      estimatedTimeMinutes: json['estimated_time_minutes'] as int,
    );
  }
}
