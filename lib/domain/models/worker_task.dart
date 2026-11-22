import '../enums/worker_enums.dart';

/// Location snapshot embedded on a task for map display and offline textual fallback.
class TaskLocation {
  final double latitude;
  final double longitude;
  final String? geohash;
  final String addressSummary;
  final String? landmark;
  final String wardId;
  final String? wardNameSnapshot;

  const TaskLocation({
    required this.latitude,
    required this.longitude,
    this.geohash,
    required this.addressSummary,
    this.landmark,
    required this.wardId,
    this.wardNameSnapshot,
  });

  factory TaskLocation.fromJson(Map<String, dynamic> json) {
    return TaskLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      geohash: json['geohash'] as String?,
      addressSummary: json['addressSummary'] as String? ?? '',
      landmark: json['landmark'] as String?,
      wardId: json['wardId'] as String? ?? '',
      wardNameSnapshot: json['wardNameSnapshot'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (geohash != null) 'geohash': geohash,
      'addressSummary': addressSummary,
      if (landmark != null) 'landmark': landmark,
      'wardId': wardId,
      if (wardNameSnapshot != null) 'wardNameSnapshot': wardNameSnapshot,
    };
  }
}

/// Authoritative Field Worker Task mapped to `tenants/{tenantId}/tasks/{taskId}`.
class WorkerTask {
  final String id;
  final String tenantId;
  final SourceType sourceType;

  /// Nullable for standalone work orders (`MUNICIPAL_WORK_ORDER`, `PREVENTIVE_MAINTENANCE`, `CAMPAIGN`).
  final String? civicFlowCaseId;
  final String? workOrderId;

  /// Null when dispatched to a claimable team pool (`teamId` must be set).
  final String? workerUid;
  final String? teamId;
  final String departmentId;
  final String? departmentNameSnapshot;
  final String wardId;
  final String categoryId;
  final String? categoryNameSnapshot;

  final TaskStatus status;
  final TaskPriority priority;
  final String title;
  final String instructions;
  final List<String> safetyPrecautions;
  final List<String> requiredEvidence;

  final TaskLocation location;
  final String assignedByUid;
  final DateTime assignedAt;
  final DateTime dueAt;
  final DateTime updatedAt;
  final int version;
  final int schemaVersion;

  /// Optional execution lifecycle fields (Phase 4)
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final String? pauseReason;
  final double? startedLatitude;
  final double? startedLongitude;

  /// Optional operational blocker fields (Phase 4.2)
  final BlockReason? blockReason;
  final String? blockNote;
  final DateTime? blockedAt;
  final String? blockerPhotoPath;

  /// Optional supervisor help request fields (Phase 4.3)
  final bool helpRequested;
  final String? helpRequestType;
  final String? helpRequestMessage;
  final DateTime? helpRequestedAt;

  const WorkerTask({
    required this.id,
    required this.tenantId,
    required this.sourceType,
    this.civicFlowCaseId,
    this.workOrderId,
    this.workerUid,
    this.teamId,
    required this.departmentId,
    this.departmentNameSnapshot,
    required this.wardId,
    required this.categoryId,
    this.categoryNameSnapshot,
    required this.status,
    required this.priority,
    required this.title,
    required this.instructions,
    this.safetyPrecautions = const [],
    this.requiredEvidence = const [],
    required this.location,
    required this.assignedByUid,
    required this.assignedAt,
    required this.dueAt,
    required this.updatedAt,
    this.version = 1,
    this.schemaVersion = 1,
    this.startedAt,
    this.pausedAt,
    this.pauseReason,
    this.startedLatitude,
    this.startedLongitude,
    this.blockReason,
    this.blockNote,
    this.blockedAt,
    this.blockerPhotoPath,
    this.helpRequested = false,
    this.helpRequestType,
    this.helpRequestMessage,
    this.helpRequestedAt,
  });

  /// True if the task is currently unclaimed in a team pool.
  bool get isUnclaimedTeamPool =>
      workerUid == null && teamId != null && status == TaskStatus.assigned;

  /// True if the task is linked to a formal CivicFlow grievance.
  bool get isCivicFlowLinked =>
      sourceType == SourceType.civicFlowCase && civicFlowCaseId != null;

  /// True if the task is temporarily paused during active work.
  bool get isPaused => pausedAt != null && status == TaskStatus.accepted;

  /// True if the task is actively blocked by an operational obstacle.
  bool get isBlocked => status == TaskStatus.blocked;

  /// True if worker has requested supervisor advisory or equipment assistance.
  bool get isHelpRequested => helpRequested;

  bool get isOverdue =>
      status.isActiveQueue &&
      status != TaskStatus.submittedForReview &&
      DateTime.now().isAfter(dueAt);

  WorkerTask copyWith({
    String? workerUid,
    TaskStatus? status,
    DateTime? updatedAt,
    int? version,
    DateTime? startedAt,
    DateTime? pausedAt,
    String? pauseReason,
    bool clearPaused = false,
    double? startedLatitude,
    double? startedLongitude,
    BlockReason? blockReason,
    String? blockNote,
    DateTime? blockedAt,
    String? blockerPhotoPath,
    bool clearBlocked = false,
    bool? helpRequested,
    String? helpRequestType,
    String? helpRequestMessage,
    DateTime? helpRequestedAt,
    bool clearHelp = false,
  }) {
    return WorkerTask(
      id: id,
      tenantId: tenantId,
      sourceType: sourceType,
      civicFlowCaseId: civicFlowCaseId,
      workOrderId: workOrderId,
      workerUid: workerUid ?? this.workerUid,
      teamId: teamId,
      departmentId: departmentId,
      departmentNameSnapshot: departmentNameSnapshot,
      wardId: wardId,
      categoryId: categoryId,
      categoryNameSnapshot: categoryNameSnapshot,
      status: status ?? this.status,
      priority: priority,
      title: title,
      instructions: instructions,
      safetyPrecautions: safetyPrecautions,
      requiredEvidence: requiredEvidence,
      location: location,
      assignedByUid: assignedByUid,
      assignedAt: assignedAt,
      dueAt: dueAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      schemaVersion: schemaVersion,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: clearPaused ? null : (pausedAt ?? this.pausedAt),
      pauseReason: clearPaused ? null : (pauseReason ?? this.pauseReason),
      startedLatitude: startedLatitude ?? this.startedLatitude,
      startedLongitude: startedLongitude ?? this.startedLongitude,
      blockReason: clearBlocked ? null : (blockReason ?? this.blockReason),
      blockNote: clearBlocked ? null : (blockNote ?? this.blockNote),
      blockedAt: clearBlocked ? null : (blockedAt ?? this.blockedAt),
      blockerPhotoPath: clearBlocked ? null : (blockerPhotoPath ?? this.blockerPhotoPath),
      helpRequested: clearHelp ? false : (helpRequested ?? this.helpRequested),
      helpRequestType: clearHelp ? null : (helpRequestType ?? this.helpRequestType),
      helpRequestMessage: clearHelp ? null : (helpRequestMessage ?? this.helpRequestMessage),
      helpRequestedAt: clearHelp ? null : (helpRequestedAt ?? this.helpRequestedAt),
    );
  }

  factory WorkerTask.fromJson(Map<String, dynamic> json) {
    return WorkerTask(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      sourceType: SourceType.fromValue(json['sourceType'] as String?),
      civicFlowCaseId: json['civicFlowCaseId'] as String?,
      workOrderId: json['workOrderId'] as String?,
      workerUid: json['workerUid'] as String?,
      teamId: json['teamId'] as String?,
      departmentId: json['departmentId'] as String? ?? '',
      departmentNameSnapshot: json['departmentNameSnapshot'] as String?,
      wardId: json['wardId'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categoryNameSnapshot: json['categoryNameSnapshot'] as String?,
      status: TaskStatus.fromValue(json['status'] as String?),
      priority: TaskPriority.fromValue(json['priority'] as String?),
      title: json['title'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      safetyPrecautions: (json['safetyPrecautions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      requiredEvidence: (json['requiredEvidence'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      location: TaskLocation.fromJson(
        (json['location'] as Map<String, dynamic>?) ?? const {},
      ),
      assignedByUid: json['assignedByUid'] as String? ?? '',
      assignedAt: DateTime.tryParse(json['assignedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dueAt: DateTime.tryParse(json['dueAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      version: (json['version'] as num?)?.toInt() ?? 1,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      pausedAt: json['pausedAt'] != null
          ? DateTime.tryParse(json['pausedAt'] as String)
          : null,
      pauseReason: json['pauseReason'] as String?,
      startedLatitude: (json['startedLatitude'] as num?)?.toDouble(),
      startedLongitude: (json['startedLongitude'] as num?)?.toDouble(),
      blockReason: json['blockReason'] != null
          ? BlockReason.fromValue(json['blockReason'] as String)
          : null,
      blockNote: json['blockNote'] as String?,
      blockedAt: json['blockedAt'] != null
          ? DateTime.tryParse(json['blockedAt'] as String)
          : null,
      blockerPhotoPath: json['blockerPhotoPath'] as String?,
      helpRequested: json['helpRequested'] as bool? ?? false,
      helpRequestType: json['helpRequestType'] as String?,
      helpRequestMessage: json['helpRequestMessage'] as String?,
      helpRequestedAt: json['helpRequestedAt'] != null
          ? DateTime.tryParse(json['helpRequestedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'sourceType': sourceType.value,
      'civicFlowCaseId': civicFlowCaseId,
      if (workOrderId != null) 'workOrderId': workOrderId,
      'workerUid': workerUid,
      'teamId': teamId,
      'departmentId': departmentId,
      if (departmentNameSnapshot != null)
        'departmentNameSnapshot': departmentNameSnapshot,
      'wardId': wardId,
      'categoryId': categoryId,
      if (categoryNameSnapshot != null)
        'categoryNameSnapshot': categoryNameSnapshot,
      'status': status.value,
      'priority': priority.value,
      'title': title,
      'instructions': instructions,
      'safetyPrecautions': safetyPrecautions,
      'requiredEvidence': requiredEvidence,
      'location': location.toJson(),
      'assignedByUid': assignedByUid,
      'assignedAt': assignedAt.toUtc().toIso8601String(),
      'dueAt': dueAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'version': version,
      'schemaVersion': schemaVersion,
      if (startedAt != null) 'startedAt': startedAt!.toUtc().toIso8601String(),
      if (pausedAt != null) 'pausedAt': pausedAt!.toUtc().toIso8601String(),
      if (pauseReason != null) 'pauseReason': pauseReason,
      if (startedLatitude != null) 'startedLatitude': startedLatitude,
      if (startedLongitude != null) 'startedLongitude': startedLongitude,
      if (blockReason != null) 'blockReason': blockReason!.value,
      if (blockNote != null) 'blockNote': blockNote,
      if (blockedAt != null) 'blockedAt': blockedAt!.toUtc().toIso8601String(),
      if (blockerPhotoPath != null) 'blockerPhotoPath': blockerPhotoPath,
      if (helpRequested) 'helpRequested': helpRequested,
      if (helpRequestType != null) 'helpRequestType': helpRequestType,
      if (helpRequestMessage != null) 'helpRequestMessage': helpRequestMessage,
      if (helpRequestedAt != null)
        'helpRequestedAt': helpRequestedAt!.toUtc().toIso8601String(),
    };
  }
}

/// Append-only audit event under `tenants/{tenantId}/tasks/{taskId}/events/{eventId}`.
class TaskEvent {
  final String id;
  final String taskId;
  final String tenantId;
  final String actorUid;
  final String eventType;
  final TaskStatus? fromStatus;
  final TaskStatus? toStatus;
  final String? reasonCode;
  final String? note;
  final String idempotencyKey;
  final DateTime createdAt;

  const TaskEvent({
    required this.id,
    required this.taskId,
    required this.tenantId,
    required this.actorUid,
    required this.eventType,
    this.fromStatus,
    this.toStatus,
    this.reasonCode,
    this.note,
    required this.idempotencyKey,
    required this.createdAt,
  });

  factory TaskEvent.fromJson(Map<String, dynamic> json) {
    return TaskEvent(
      id: json['id'] as String? ?? '',
      taskId: json['taskId'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      actorUid: json['actorUid'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      fromStatus: json['fromStatus'] != null
          ? TaskStatus.fromValue(json['fromStatus'] as String?)
          : null,
      toStatus: json['toStatus'] != null
          ? TaskStatus.fromValue(json['toStatus'] as String?)
          : null,
      reasonCode: json['reasonCode'] as String?,
      note: json['note'] as String?,
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'tenantId': tenantId,
      'actorUid': actorUid,
      'eventType': eventType,
      if (fromStatus != null) 'fromStatus': fromStatus!.value,
      if (toStatus != null) 'toStatus': toStatus!.value,
      if (reasonCode != null) 'reasonCode': reasonCode,
      if (note != null) 'note': note,
      'idempotencyKey': idempotencyKey,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}
