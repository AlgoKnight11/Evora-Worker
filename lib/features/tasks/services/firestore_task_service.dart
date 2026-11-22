import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/safety_alert.dart';
import '../../../domain/models/worker_task.dart';
import '../repositories/task_repository.dart';

/// Production Cloud Firestore task repository mapped to `tenants/{tenantId}/tasks/{taskId}`.
class FirestoreTaskService implements TaskRepository {
  final FirebaseFirestore _firestore;

  FirestoreTaskService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksCollection(String tenantId) {
    return _firestore.collection('tenants').doc(tenantId).collection('tasks');
  }

  CollectionReference<Map<String, dynamic>> _safetyAlertsCollection(String tenantId) {
    return _firestore.collection('tenants').doc(tenantId).collection('safetyAlerts');
  }

  @override
  Stream<List<WorkerTask>> watchTasksForWorker({
    required String tenantId,
    required String workerUid,
    String? teamId,
  }) {
    final col = _tasksCollection(tenantId);

    // If crew teamId is provided, query both individually assigned and unclaimed team-pool tasks
    final query = teamId != null && teamId.isNotEmpty
        ? col.where(
            Filter.or(
              Filter('workerUid', isEqualTo: workerUid),
              Filter.and(
                Filter('workerUid', isNull: true),
                Filter('teamId', isEqualTo: teamId),
                Filter('status', isEqualTo: TaskStatus.assigned.value),
              ),
            ),
          )
        : col.where('workerUid', isEqualTo: workerUid);

    return query.snapshots().map((snapshot) {
      final tasks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['tenantId'] = tenantId;
        return WorkerTask.fromJson(data);
      }).toList();

      // Sort by priority (P1 -> P4) then dueAt ascending
      tasks.sort((a, b) {
        final pCompare = a.priority.index.compareTo(b.priority.index);
        if (pCompare != 0) return pCompare;
        return a.dueAt.compareTo(b.dueAt);
      });

      return tasks;
    });
  }

  @override
  Future<List<WorkerTask>> getTasksForWorker({
    required String tenantId,
    required String workerUid,
    String? teamId,
  }) async {
    final col = _tasksCollection(tenantId);
    final query = teamId != null && teamId.isNotEmpty
        ? col.where(
            Filter.or(
              Filter('workerUid', isEqualTo: workerUid),
              Filter.and(
                Filter('workerUid', isNull: true),
                Filter('teamId', isEqualTo: teamId),
                Filter('status', isEqualTo: TaskStatus.assigned.value),
              ),
            ),
          )
        : col.where('workerUid', isEqualTo: workerUid);

    final snapshot = await query.get();
    final tasks = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      data['tenantId'] = tenantId;
      return WorkerTask.fromJson(data);
    }).toList();

    tasks.sort((a, b) {
      final pCompare = a.priority.index.compareTo(b.priority.index);
      if (pCompare != 0) return pCompare;
      return a.dueAt.compareTo(b.dueAt);
    });

    return tasks;
  }

  @override
  Future<WorkerTask?> getTaskById({
    required String tenantId,
    required String taskId,
  }) async {
    final doc = await _tasksCollection(tenantId).doc(taskId).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    data['tenantId'] = tenantId;
    return WorkerTask.fromJson(data);
  }

  @override
  Future<void> acceptTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  }) async {
    final ref = _tasksCollection(tenantId).doc(taskId);

    await ref.update({
      'status': TaskStatus.accepted.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'version': FieldValue.increment(1),
    });
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
