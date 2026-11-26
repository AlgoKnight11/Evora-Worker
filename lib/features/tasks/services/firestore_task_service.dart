import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/municipal_taxonomy.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/safety_alert.dart';
import '../../../domain/models/worker_task.dart';
import '../repositories/task_repository.dart';

/// Production Cloud Firestore task repository mapped to `tenants/{tenantId}/tasks/{taskId}`
/// with real-time bidirectional synchronization with Citizen complaints (`civicFlowCases`).
class FirestoreTaskService implements TaskRepository {
  final FirebaseFirestore _firestore;

  FirestoreTaskService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksCollection(String tenantId) {
    return _firestore.collection('tenants').doc(tenantId).collection('tasks');
  }

  CollectionReference<Map<String, dynamic>> _casesCollection(String tenantId) {
    return _firestore.collection('tenants').doc(tenantId).collection('civicFlowCases');
  }

  CollectionReference<Map<String, dynamic>> _safetyAlertsCollection(String tenantId) {
    return _firestore.collection('tenants').doc(tenantId).collection('safetyAlerts');
  }

  static DateTime? _parseDocDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      final dt = (value as dynamic).toDate();
      if (dt is DateTime) return dt;
    } catch (_) {}
    return null;
  }

  WorkerTask _caseDocToTask(DocumentSnapshot<Map<String, dynamic>> doc, String tenantId) {
    final data = doc.data() ?? {};
    final caseId = doc.id;
    final caseNumber = data['caseNumber'] as String? ??
        'CF-${doc.id.substring(0, doc.id.length > 6 ? 6 : doc.id.length)}';
    final category = data['category'] as String? ?? 'general';
    final subcategory = data['subcategory'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final landmark = data['landmark'] as String?;
    final locality = data['locality'] as String? ?? 'Municipal Area';
    final lat = (data['latitude'] as num?)?.toDouble() ?? 31.1048;
    final lng = (data['longitude'] as num?)?.toDouble() ?? 77.1734;
    final priorityStr = (data['priority'] as String?)?.toLowerCase() ?? 'medium';
    final statusStr = (data['status'] as String?)?.toLowerCase() ?? 'submitted';
    final assignedDept = data['assignedDepartment'] as String? ?? 'Municipal Services';
    final citizenName = data['citizenName'] as String? ?? 'Resident';

    final priority = switch (priorityStr) {
      'urgent' => TaskPriority.p1,
      'high' => TaskPriority.p2,
      'low' => TaskPriority.p4,
      _ => TaskPriority.p3,
    };

    final status = switch (statusStr) {
      'submitted' || 'under_triage' || 'verified' || 'assigned' => TaskStatus.assigned,
      'in_progress' => TaskStatus.inProgress,
      'blocked' => TaskStatus.blocked,
      'resolved_pending' => TaskStatus.submittedForReview,
      'resolved' || 'closed' => TaskStatus.approved,
      _ => TaskStatus.assigned,
    };

    final createdAt = _parseDocDateTime(data['createdAt']) ?? DateTime.now();
    final updatedAt = _parseDocDateTime(data['updatedAt']) ?? createdAt;

    final slaHours = switch (priority) {
      TaskPriority.p1 => 4,
      TaskPriority.p2 => 12,
      TaskPriority.p4 => 48,
      _ => 24,
    };

    final title =
        '[$caseNumber] ${subcategory.isNotEmpty ? subcategory : category.toUpperCase().replaceAll('_', ' ')}';

    return WorkerTask(
      id: 'task_$caseId',
      tenantId: tenantId,
      sourceType: SourceType.civicFlowCase,
      civicFlowCaseId: caseId,
      workerUid: null,
      teamId: null,
      departmentId: assignedDept,
      departmentNameSnapshot: assignedDept,
      wardId: locality,
      categoryId: category,
      categoryNameSnapshot: subcategory.isNotEmpty ? subcategory : category,
      status: status,
      priority: priority,
      title: title,
      instructions: description,
      safetyPrecautions: const [
        'Wear high-visibility vest and municipal field PPE.',
        'Assess ground stability and vehicular traffic before operating.',
      ],
      requiredEvidence: const ['geo_tagged_photo', 'completion_signature'],
      location: TaskLocation(
        latitude: lat,
        longitude: lng,
        addressSummary: locality,
        landmark: landmark,
        wardId: locality,
        wardNameSnapshot: locality,
      ),
      assignedByUid: citizenName,
      assignedAt: createdAt,
      dueAt: createdAt.add(Duration(hours: slaHours)),
      updatedAt: updatedAt,
      version: 1,
      schemaVersion: 1,
    );
  }

  /// Syncs task progress and status updates back to the parent Citizen grievance
  Future<void> _syncCaseStatus({
    required String tenantId,
    required String caseId,
    required String caseStatus,
    required String timelineTitle,
    required String timelineDescription,
    required String actor,
  }) async {
    try {
      final cleanCaseId = caseId.startsWith('task_') ? caseId.substring(5) : caseId;
      final caseRef = _casesCollection(tenantId).doc(cleanCaseId);
      final caseSnap = await caseRef.get();
      if (!caseSnap.exists) return;

      final now = DateTime.now();
      final newTimelineEvent = {
        'status': caseStatus,
        'title': timelineTitle,
        'description': timelineDescription,
        'timestamp': now.toIso8601String(),
        'actor': actor,
      };

      await caseRef.update({
        'status': caseStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'timeline': FieldValue.arrayUnion([newTimelineEvent]),
      });
    } catch (e) {
      debugPrint('[FirestoreTaskService] Sync to civicFlowCases note: $e');
    }
  }

  @override
  Stream<List<WorkerTask>> watchTasksForWorker({
    required String tenantId,
    required String workerUid,
    String? teamId,
    String? departmentId,
  }) {
    final controller = StreamController<List<WorkerTask>>.broadcast();
    List<WorkerTask> currentTasks = [];
    List<WorkerTask> currentCasesAsTasks = [];

    void emitMerged() {
      final Map<String, WorkerTask> merged = {};

      for (final t in currentCasesAsTasks) {
        merged[t.id] = t;
      }
      for (final t in currentTasks) {
        if (t.civicFlowCaseId != null) {
          merged['task_${t.civicFlowCaseId}'] = t;
        }
        merged[t.id] = t;
      }

      final filtered = merged.values.where((t) {
        // 1. Explicitly assigned to this individual worker
        if (t.workerUid == workerUid) return true;
        // 2. Assigned to this worker's rapid response crew
        if (teamId != null && teamId.isNotEmpty && t.teamId == teamId) return true;
        // 3. Unassigned municipal grievance: filter by department
        if (t.workerUid == null) {
          return MunicipalTaxonomyBridge.matchesWorkerDepartment(
            workerDepartment: departmentId,
            taskDepartment: t.departmentId,
            taskCategory: t.categoryId,
          );
        }
        return false;
      }).toList();

      filtered.sort((a, b) {
        final pCompare = a.priority.index.compareTo(b.priority.index);
        if (pCompare != 0) return pCompare;
        return a.dueAt.compareTo(b.dueAt);
      });

      if (!controller.isClosed) {
        controller.add(filtered);
      }
    }

    StreamSubscription? tasksSub;
    StreamSubscription? casesSub;

    controller.onListen = () {
      if (FirebaseAuth.instance.currentUser == null) {
        FirebaseAuth.instance.signInAnonymously().catchError((e) {
          debugPrint('[FirestoreTaskService] anonymous auth note: $e');
          return null as dynamic;
        });
      }

      tasksSub = _tasksCollection(tenantId).snapshots().listen(
        (snapshot) {
          currentTasks = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            data['tenantId'] = tenantId;
            return WorkerTask.fromJson(data);
          }).toList();
          emitMerged();
        },
        onError: (e) {
          debugPrint('[FirestoreTaskService] tasks stream error: $e');
        },
      );

      casesSub = _casesCollection(tenantId).snapshots().listen(
        (snapshot) {
          currentCasesAsTasks = snapshot.docs
              .where((doc) {
                final status = (doc.data()['status'] as String?)?.toLowerCase();
                return status != 'closed' && status != 'resolved';
              })
              .map((doc) => _caseDocToTask(doc, tenantId))
              .toList();
          emitMerged();
        },
        onError: (e) {
          debugPrint('[FirestoreTaskService] cases stream error: $e');
        },
      );
    };

    controller.onCancel = () {
      tasksSub?.cancel();
      casesSub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<List<WorkerTask>> getTasksForWorker({
    required String tenantId,
    required String workerUid,
    String? teamId,
    String? departmentId,
  }) async {
    final tasksSnap = await _tasksCollection(tenantId).get();
    final casesSnap = await _casesCollection(tenantId).get();

    final Map<String, WorkerTask> merged = {};

    for (final doc in casesSnap.docs) {
      final status = (doc.data()['status'] as String?)?.toLowerCase();
      if (status != 'closed' && status != 'resolved') {
        final t = _caseDocToTask(doc, tenantId);
        merged[t.id] = t;
      }
    }

    for (final doc in tasksSnap.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      data['tenantId'] = tenantId;
      final t = WorkerTask.fromJson(data);
      if (t.civicFlowCaseId != null) {
        merged['task_${t.civicFlowCaseId}'] = t;
      }
      merged[t.id] = t;
    }

    final filtered = merged.values.where((t) {
      if (t.workerUid == workerUid) return true;
      if (teamId != null && teamId.isNotEmpty && t.teamId == teamId) return true;
      if (t.workerUid == null) {
        return MunicipalTaxonomyBridge.matchesWorkerDepartment(
          workerDepartment: departmentId,
          taskDepartment: t.departmentId,
          taskCategory: t.categoryId,
        );
      }
      return false;
    }).toList();

    filtered.sort((a, b) {
      final pCompare = a.priority.index.compareTo(b.priority.index);
      if (pCompare != 0) return pCompare;
      return a.dueAt.compareTo(b.dueAt);
    });

    return filtered;
  }

  @override
  Future<WorkerTask?> getTaskById({
    required String tenantId,
    required String taskId,
  }) async {
    final doc = await _tasksCollection(tenantId).doc(taskId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      data['tenantId'] = tenantId;
      return WorkerTask.fromJson(data);
    }

    final caseId = taskId.startsWith('task_') ? taskId.substring(5) : taskId;
    final caseDoc = await _casesCollection(tenantId).doc(caseId).get();
    if (caseDoc.exists && caseDoc.data() != null) {
      return _caseDocToTask(caseDoc, tenantId);
    }

    return null;
  }

  @override
  Future<void> acceptTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    final ref = _tasksCollection(tenantId).doc(taskId);
    final doc = await ref.get();

    String? caseId;
    if (doc.exists && doc.data() != null) {
      caseId = doc.data()?['civicFlowCaseId'] as String?;
      await ref.update({
        'status': TaskStatus.accepted.value,
        'workerUid': workerUid,
        'updatedAt': FieldValue.serverTimestamp(),
        'version': FieldValue.increment(1),
      });
    } else {
      caseId = taskId.startsWith('task_') ? taskId.substring(5) : taskId;
      final caseDoc = await _casesCollection(tenantId).doc(caseId).get();
      if (caseDoc.exists && caseDoc.data() != null) {
        final task = _caseDocToTask(caseDoc, tenantId);
        final payload = task.copyWith(
          workerUid: workerUid,
          status: TaskStatus.accepted,
          updatedAt: DateTime.now(),
        ).toJson();
        await ref.set(payload);
      }
    }

    if (caseId != null) {
      await _syncCaseStatus(
        tenantId: tenantId,
        caseId: caseId,
        caseStatus: 'assigned',
        timelineTitle: 'Accepted by Municipal Worker',
        timelineDescription: 'Field crew ($workerUid) accepted the task and is en route.',
        actor: 'Municipal Worker',
      );
    }
  }

  @override
  Future<void> declineTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    required DeclineReason reason,
    String? note,
  }) async {
    final ref = _tasksCollection(tenantId).doc(taskId);

    await ref.update({
      'status': TaskStatus.reassigned.value,
      'workerUid': null,
      'declineReason': reason.value,
      if (note != null && note.isNotEmpty) 'declineNote': note,
      'updatedAt': FieldValue.serverTimestamp(),
      'version': FieldValue.increment(1),
    });

    // Log the refusal event for supervisory audit
    await ref.collection('auditEvents').add({
      'eventType': 'TASK_DECLINED',
      'workerUid': workerUid,
      'reason': reason.value,
      'note': note,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> claimTeamPoolTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    final docRef = _tasksCollection(tenantId).doc(taskId);

    // Atomic transaction preventing two workers from claiming the same task simultaneously
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Task $taskId does not exist');
      }

      final data = snapshot.data();
      final currentWorker = data?['workerUid'];

      if (currentWorker != null && currentWorker != workerUid) {
        throw TaskAlreadyClaimedException(
          taskId: taskId,
          claimedByUid: currentWorker.toString(),
        );
      }

      transaction.update(docRef, {
        'workerUid': workerUid,
        'status': TaskStatus.accepted.value,
        'updatedAt': FieldValue.serverTimestamp(),
        'version': FieldValue.increment(1),
      });

      // Log claim audit
      final auditRef = docRef.collection('auditEvents').doc();
      transaction.set(auditRef, {
        'eventType': 'TASK_CLAIMED_FROM_POOL',
        'workerUid': workerUid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> dismissPoolTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    // Record local worker response dismissal without deleting the task from the crew pool
    final responseRef = _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('members')
        .doc(workerUid)
        .collection('dismissedTasks')
        .doc(taskId);

    await responseRef.set({
      'dismissedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> startTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    double? latitude,
    double? longitude,
  }) async {
    final ref = _tasksCollection(tenantId).doc(taskId);

    final updateData = <String, dynamic>{
      'status': TaskStatus.inProgress.value,
      'startedAt': FieldValue.serverTimestamp(),
      'pausedAt': null,
      'pauseReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'version': FieldValue.increment(1),
    };
    if (latitude != null) updateData['startedLatitude'] = latitude;
    if (longitude != null) updateData['startedLongitude'] = longitude;

    await ref.update(updateData);

    final auditData = <String, dynamic>{
      'eventType': 'TASK_STARTED',
      'workerUid': workerUid,
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (latitude != null) auditData['latitude'] = latitude;
    if (longitude != null) auditData['longitude'] = longitude;

    await ref.collection('auditEvents').add(auditData);

    final caseId = taskId.startsWith('task_') ? taskId.substring(5) : taskId;
    await _syncCaseStatus(
      tenantId: tenantId,
      caseId: caseId,
      caseStatus: 'in_progress',
      timelineTitle: 'Field Work Started',
      timelineDescription: 'Municipal crew is on-site actively resolving the issue.',
      actor: 'Municipal Worker',
    );
  }

  @override
  Future<void> pauseTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    String? reason,
  }) async {
    final ref = _tasksCollection(tenantId).doc(taskId);

    await ref.update({
      'status': TaskStatus.accepted.value,
      'pausedAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.isNotEmpty) 'pauseReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
      'version': FieldValue.increment(1),
    });

    await ref.collection('auditEvents').add({
      'eventType': 'TASK_PAUSED',
      'workerUid': workerUid,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> resumeTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    final ref = _tasksCollection(tenantId).doc(taskId);

    await ref.update({
      'status': TaskStatus.inProgress.value,
      'pausedAt': null,
      'pauseReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'version': FieldValue.increment(1),
    });

    await ref.collection('auditEvents').add({
      'eventType': 'TASK_RESUMED',
      'workerUid': workerUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> blockTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    required BlockReason reason,
    String? note,
  }) async {
    final ref = _tasksCollection(tenantId).doc(taskId);

    final updateData = <String, dynamic>{
      'status': TaskStatus.blocked.value,
      'blockReason': reason.value,
      'blockedAt': FieldValue.serverTimestamp(),
      'pausedAt': null,
      'pauseReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'version': FieldValue.increment(1),
    };
    if (note != null && note.isNotEmpty) updateData['blockNote'] = note;

    await ref.update(updateData);

    final auditData = <String, dynamic>{
      'eventType': 'TASK_BLOCKED',
      'workerUid': workerUid,
      'reason': reason.value,
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (note != null && note.isNotEmpty) auditData['note'] = note;

    await ref.collection('auditEvents').add(auditData);

    final caseId = taskId.startsWith('task_') ? taskId.substring(5) : taskId;
    await _syncCaseStatus(
      tenantId: tenantId,
      caseId: caseId,
      caseStatus: 'blocked',
      timelineTitle: 'Work Temporarily On Hold',
      timelineDescription:
          'Operational delay reported: ${reason.value}${note != null && note.isNotEmpty ? " ($note)" : ""}.',
      actor: 'Municipal Worker',
    );
  }

  @override
  Future<void> unblockTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    final ref = _tasksCollection(tenantId).doc(taskId);

    await ref.update({
      'status': TaskStatus.inProgress.value,
      'blockReason': null,
      'blockNote': null,
      'blockedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'version': FieldValue.increment(1),
    });

    await ref.collection('auditEvents').add({
      'eventType': 'TASK_UNBLOCKED',
      'workerUid': workerUid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final caseId = taskId.startsWith('task_') ? taskId.substring(5) : taskId;
    await _syncCaseStatus(
      tenantId: tenantId,
      caseId: caseId,
      caseStatus: 'in_progress',
      timelineTitle: 'Work Resumed',
      timelineDescription:
          'Operational obstacles resolved; crew resumed field resolution.',
      actor: 'Municipal Worker',
    );
  }

  @override
  Future<void> requestSupervisorHelp({
    required String tenantId,
    required String taskId,
    required String workerUid,
    required String helpType,
    required String message,
  }) async {
    final ref = _tasksCollection(tenantId).doc(taskId);

    await ref.update({
      'helpRequested': true,
      'helpRequestType': helpType,
      'helpRequestMessage': message,
      'helpRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'version': FieldValue.increment(1),
    });

    await ref.collection('auditEvents').add({
      'eventType': 'SUPERVISOR_HELP_REQUESTED',
      'workerUid': workerUid,
      'helpType': helpType,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> cancelSupervisorHelp({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    final ref = _tasksCollection(tenantId).doc(taskId);

    await ref.update({
      'helpRequested': false,
      'helpRequestType': null,
      'helpRequestMessage': null,
      'helpRequestedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'version': FieldValue.increment(1),
    });

    await ref.collection('auditEvents').add({
      'eventType': 'SUPERVISOR_HELP_CANCELLED',
      'workerUid': workerUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<SafetyAlert> reportSafetyIncident({
    required String tenantId,
    required String reportedByUid,
    required String hazardType,
    required String description,
    String? taskId,
    double? latitude,
    double? longitude,
    String? photoStoragePath,
  }) async {
    final col = _safetyAlertsCollection(tenantId);
    final docRef = col.doc();
    final now = DateTime.now();
    final idempotencyKey = 'alert_${docRef.id}_${now.millisecondsSinceEpoch}';

    final alert = SafetyAlert(
      id: docRef.id,
      tenantId: tenantId,
      taskId: taskId,
      reportedByUid: reportedByUid,
      hazardType: hazardType,
      description: description,
      latitude: latitude,
      longitude: longitude,
      photoStoragePath: photoStoragePath,
      escalated: true,
      reportedAt: now,
      idempotencyKey: idempotencyKey,
    );

    final data = alert.toJson();
    data['reportedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);

    if (taskId != null) {
      await _tasksCollection(tenantId).doc(taskId).collection('auditEvents').add({
        'eventType': 'SAFETY_ALERT_REPORTED',
        'alertId': docRef.id,
        'hazardType': hazardType,
        'reportedByUid': reportedByUid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    return alert;
  }

  @override
  Stream<List<SafetyAlert>> watchSafetyAlerts({
    required String tenantId,
    required String workerUid,
  }) {
    return _safetyAlertsCollection(tenantId)
        .where('reportedByUid', isEqualTo: workerUid)
        .snapshots()
        .map((snapshot) {
      final alerts = snapshot.docs.map((doc) {
        final d = doc.data();
        d['id'] = doc.id;
        d['tenantId'] = tenantId;
        return SafetyAlert.fromJson(d);
      }).toList();
      alerts.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      return alerts;
    });
  }
}
