/// Out-of-band high-priority safety incident record stored under
/// `tenants/{tenantId}/safetyAlerts/{alertId}`.
/// Intentionally separate from operational `blockTask` records.
class SafetyAlert {
  final String id;
  final String tenantId;
  final String? taskId;
  final String reportedByUid;
  final String hazardType;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? photoStoragePath;
  final bool escalated;
  final DateTime reportedAt;
  final String idempotencyKey;

  const SafetyAlert({
    required this.id,
    required this.tenantId,
    this.taskId,
    required this.reportedByUid,
    required this.hazardType,
    required this.description,
    this.latitude,
    this.longitude,
    this.photoStoragePath,
    this.escalated = true,
    required this.reportedAt,
    required this.idempotencyKey,
  });

  factory SafetyAlert.fromJson(Map<String, dynamic> json) {
    return SafetyAlert(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      taskId: json['taskId'] as String?,
      reportedByUid: json['reportedByUid'] as String? ?? '',
      hazardType: json['hazardType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      photoStoragePath: json['photoStoragePath'] as String?,
      escalated: json['escalated'] as bool? ?? true,
      reportedAt: DateTime.tryParse(json['reportedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      if (taskId != null) 'taskId': taskId,
      'reportedByUid': reportedByUid,
      'hazardType': hazardType,
      'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (photoStoragePath != null) 'photoStoragePath': photoStoragePath,
      'escalated': escalated,
      'reportedAt': reportedAt.toUtc().toIso8601String(),
      'idempotencyKey': idempotencyKey,
    };
  }
}
