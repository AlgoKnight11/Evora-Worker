import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/enums/worker_enums.dart';
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
}
