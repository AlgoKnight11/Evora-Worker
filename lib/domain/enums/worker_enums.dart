// Canonical vocabularies for the EVORA Field Worker Portal.
// Strictly aligned with Appendix A and Part IV/V architectural decisions.

enum TaskStatus {
  assigned('assigned'),
  accepted('accepted'),
  inProgress('in_progress'),
  blocked('blocked'),
  submittedForReview('submitted_for_review'),
  returned('returned'),
  approved('approved'),
  cancelled('cancelled'),
  reassigned('reassigned');

  final String value;
  const TaskStatus(this.value);

  bool get isActiveQueue =>
      this == assigned ||
      this == accepted ||
      this == inProgress ||
      this == blocked ||
      this == submittedForReview ||
      this == returned;

  bool get isHistoryQueue =>
      this == approved || this == returned || this == cancelled || this == reassigned;

  static TaskStatus fromValue(String? raw) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => TaskStatus.assigned,
    );
  }
}

enum TaskPriority {
  p1('P1'),
  p2('P2'),
  p3('P3'),
  p4('P4');

  final String value;
  const TaskPriority(this.value);

  static TaskPriority fromValue(String? raw) {
    final normalized = raw?.toUpperCase();
    return TaskPriority.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => TaskPriority.p3,
    );
  }
}

enum SourceType {
  civicFlowCase('CIVIC_FLOW_CASE'),
  municipalWorkOrder('MUNICIPAL_WORK_ORDER'),
  preventiveMaintenance('PREVENTIVE_MAINTENANCE'),
  campaign('CAMPAIGN');

  final String value;
  const SourceType(this.value);

  /// Standalone tasks must never expose citizen data or trigger citizen notifications.
  bool get isStandalone => this != SourceType.civicFlowCase;

  static SourceType fromValue(String? raw) {
    return SourceType.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => SourceType.civicFlowCase,
    );
  }
}

enum DeclineReason {
  outOfArea('OUT_OF_AREA'),
  skillMismatch('SKILL_MISMATCH'),
  workloadConflict('WORKLOAD_CONFLICT'),
  equipmentUnavailable('EQUIPMENT_UNAVAILABLE'),
  safetyConcern('SAFETY_CONCERN'),
  other('OTHER');

  final String value;
  const DeclineReason(this.value);

  bool get isSafetyCritical => this == safetyConcern;

  static DeclineReason fromValue(String? raw) {
    return DeclineReason.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => DeclineReason.other,
    );
  }
}

enum BlockReason {
  unsafeSite('UNSAFE_SITE'),
  accessRestricted('ACCESS_RESTRICTED'),
  weatherCondition('WEATHER_CONDITION'),
  equipmentFailure('EQUIPMENT_FAILURE'),
  materialUnavailable('MATERIAL_UNAVAILABLE'),
  awaitingAuthority('AWAITING_AUTHORITY'),
  other('OTHER');

  final String value;
  const BlockReason(this.value);

  bool get isSafetyCritical => this == unsafeSite;

  static BlockReason fromValue(String? raw) {
    return BlockReason.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => BlockReason.other,
    );
  }
}

enum AcknowledgementStatus {
  notRequired('NOT_REQUIRED'),
  pending('PENDING'),
  confirmed('CONFIRMED'),
  disputed('DISPUTED'),
  citizenUnavailable('CITIZEN_UNAVAILABLE');

  final String value;
  const AcknowledgementStatus(this.value);

  static AcknowledgementStatus fromValue(String? raw) {
    return AcknowledgementStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => AcknowledgementStatus.notRequired,
    );
  }
}

enum EvidenceStatus {
  notRequired('not_required'),
  pendingUpload('pending_upload'),
  uploaded('uploaded'),
  scanning('scanning'),
  pendingReview('pending_review'),
  approved('approved'),
  rejected('rejected'),
  expired('expired');

  final String value;
  const EvidenceStatus(this.value);

  static EvidenceStatus fromValue(String? raw) {
    return EvidenceStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => EvidenceStatus.pendingUpload,
    );
  }
}

enum EvidenceKind {
  beforePhoto('before_photo'),
  afterPhoto('after_photo'),
  documentPdf('document_pdf'),
  blockerPhoto('blocker_photo'),
  safetyPhoto('safety_photo');

  final String value;
  const EvidenceKind(this.value);

  static EvidenceKind fromValue(String? raw) {
    return EvidenceKind.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => EvidenceKind.afterPhoto,
    );
  }
}

enum SyncConnectionState {
  online,
  offline,
  syncing,
}
