import '../enums/worker_enums.dart';

/// Evidence metadata record stored under `tenants/{tenantId}/tasks/{taskId}/evidence/{evidenceId}`.
/// Binary files live exclusively in Cloud Storage for Firebase.
class TaskEvidence {
  final String id;
  final String taskId;
  final String tenantId;
  final EvidenceKind kind;
  final EvidenceStatus status;
  final String mimeType;
  final int sizeBytes;
  final String? storagePath;
  final String? localStagingRef;
  final double? capturedLatitude;
  final double? capturedLongitude;
  final String capturedByUid;
  final DateTime capturedAt;
  final int schemaVersion;

  const TaskEvidence({
    required this.id,
    required this.taskId,
    required this.tenantId,
    required this.kind,
    required this.status,
    required this.mimeType,
    required this.sizeBytes,
    this.storagePath,
    this.localStagingRef,
    this.capturedLatitude,
    this.capturedLongitude,
    required this.capturedByUid,
    required this.capturedAt,
    this.schemaVersion = 1,
  });

  factory TaskEvidence.fromJson(Map<String, dynamic> json) {
    return TaskEvidence(
      id: json['id'] as String? ?? '',
      taskId: json['taskId'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      kind: EvidenceKind.fromValue(json['kind'] as String?),
      status: EvidenceStatus.fromValue(json['status'] as String?),
      mimeType: json['mimeType'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      storagePath: json['storagePath'] as String?,
      localStagingRef: json['localStagingRef'] as String?,
      capturedLatitude: (json['capturedLatitude'] as num?)?.toDouble(),
      capturedLongitude: (json['capturedLongitude'] as num?)?.toDouble(),
      capturedByUid: json['capturedByUid'] as String? ?? '',
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'tenantId': tenantId,
      'kind': kind.value,
      'status': status.value,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      if (storagePath != null) 'storagePath': storagePath,
      if (localStagingRef != null) 'localStagingRef': localStagingRef,
      if (capturedLatitude != null) 'capturedLatitude': capturedLatitude,
      if (capturedLongitude != null) 'capturedLongitude': capturedLongitude,
      'capturedByUid': capturedByUid,
      'capturedAt': capturedAt.toUtc().toIso8601String(),
      'schemaVersion': schemaVersion,
    };
  }
}

/// Checklist item response stored under `tenants/{tenantId}/tasks/{taskId}/checklistResponses/{itemId}`.
class ChecklistResponse {
  final String itemId;
  final String label;
  final bool isRequired;
  final bool isCompleted;
  final bool isNotApplicable;
  final String? notApplicableReason;
  final DateTime? updatedAt;

  const ChecklistResponse({
    required this.itemId,
    required this.label,
    this.isRequired = true,
    this.isCompleted = false,
    this.isNotApplicable = false,
    this.notApplicableReason,
    this.updatedAt,
  });

  /// Valid per WRK-EV-04: required items must be complete OR marked N/A with a reason.
  bool get isSatisfied {
    if (!isRequired) return true;
    if (isCompleted) return true;
    return isNotApplicable &&
        notApplicableReason != null &&
        notApplicableReason!.trim().isNotEmpty;
  }

  factory ChecklistResponse.fromJson(Map<String, dynamic> json) {
    return ChecklistResponse(
      itemId: json['itemId'] as String? ?? '',
      label: json['label'] as String? ?? '',
      isRequired: json['isRequired'] as bool? ?? true,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isNotApplicable: json['isNotApplicable'] as bool? ?? false,
      notApplicableReason: json['notApplicableReason'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'label': label,
      'isRequired': isRequired,
      'isCompleted': isCompleted,
      'isNotApplicable': isNotApplicable,
      if (notApplicableReason != null) 'notApplicableReason': notApplicableReason,
      if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    };
  }
}

/// Structured category-specific measurement stored under
/// `tenants/{tenantId}/tasks/{taskId}/measurements/{measurementId}`.
class MeasurementRecord {
  final String id;
  final String fieldKey;
  final String label;
  final double value;
  final String unit;
  final DateTime recordedAt;
  final String recordedByUid;

  const MeasurementRecord({
    required this.id,
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.recordedByUid,
  });

  factory MeasurementRecord.fromJson(Map<String, dynamic> json) {
    return MeasurementRecord(
      id: json['id'] as String? ?? '',
      fieldKey: json['fieldKey'] as String? ?? '',
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      recordedByUid: json['recordedByUid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fieldKey': fieldKey,
      'label': label,
      'value': value,
      'unit': unit,
      'recordedAt': recordedAt.toUtc().toIso8601String(),
      'recordedByUid': recordedByUid,
    };
  }
}

/// Citizen in-app acknowledgement record stored under
/// `tenants/{tenantId}/tasks/{taskId}/acknowledgements/{ackId}`.
class AcknowledgementRecord {
  final String id;
  final String taskId;
  final AcknowledgementStatus status;
  final bool serverConfirmed;
  final String? note;
  final DateTime updatedAt;

  const AcknowledgementRecord({
    required this.id,
    required this.taskId,
    required this.status,
    this.serverConfirmed = false,
    this.note,
    required this.updatedAt,
  });

  factory AcknowledgementRecord.fromJson(Map<String, dynamic> json) {
    return AcknowledgementRecord(
      id: json['id'] as String? ?? '',
      taskId: json['taskId'] as String? ?? '',
      status: AcknowledgementStatus.fromValue(json['status'] as String?),
      serverConfirmed: json['serverConfirmed'] as bool? ?? false,
      note: json['note'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'status': status.value,
      'serverConfirmed': serverConfirmed,
      if (note != null) 'note': note,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}
