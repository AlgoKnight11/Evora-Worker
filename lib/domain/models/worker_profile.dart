/// Provisioned Field Worker identity & tenant membership record.
/// Mapped to `tenants/{tenantId}/members/{uid}`.
class WorkerProfile {
  final String uid;
  final String tenantId;
  final String employeeCode;
  final String displayName;
  final String phoneNumber;
  final String departmentId;
  final String? departmentName;
  final String? teamId;
  final String? teamName;
  final List<String> authorizedServiceAreaIds;
  final String? supervisorName;
  final String? supervisorPhone;
  final bool isActive;
  final bool isContractor;
  final DateTime? lastSessionValidatedAt;

  const WorkerProfile({
    required this.uid,
    required this.tenantId,
    required this.employeeCode,
    required this.displayName,
    required this.phoneNumber,
    required this.departmentId,
    this.departmentName,
    this.teamId,
    this.teamName,
    this.authorizedServiceAreaIds = const [],
    this.supervisorName,
    this.supervisorPhone,
    this.isActive = true,
    this.isContractor = false,
    this.lastSessionValidatedAt,
  });

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    return WorkerProfile(
      uid: json['uid'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      departmentName: json['departmentName'] as String?,
      teamId: json['teamId'] as String?,
      teamName: json['teamName'] as String?,
      authorizedServiceAreaIds: (json['authorizedServiceAreaIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      supervisorName: json['supervisorName'] as String?,
      supervisorPhone: json['supervisorPhone'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      isContractor: json['isContractor'] as bool? ?? false,
      lastSessionValidatedAt: json['lastSessionValidatedAt'] != null
          ? DateTime.tryParse(json['lastSessionValidatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'tenantId': tenantId,
      'employeeCode': employeeCode,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'departmentId': departmentId,
      if (departmentName != null) 'departmentName': departmentName,
      if (teamId != null) 'teamId': teamId,
      if (teamName != null) 'teamName': teamName,
      'authorizedServiceAreaIds': authorizedServiceAreaIds,
      if (supervisorName != null) 'supervisorName': supervisorName,
      if (supervisorPhone != null) 'supervisorPhone': supervisorPhone,
      'isActive': isActive,
      'isContractor': isContractor,
      if (lastSessionValidatedAt != null)
        'lastSessionValidatedAt': lastSessionValidatedAt!.toUtc().toIso8601String(),
    };
  }
}
