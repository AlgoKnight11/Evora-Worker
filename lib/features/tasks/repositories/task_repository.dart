import 'dart:async';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/worker_task.dart';

/// Thrown when an atomic claim collision occurs on a team-pool task.
class TaskAlreadyClaimedException implements Exception {
  final String taskId;
  final String? claimedByUid;
  final String message;

  const TaskAlreadyClaimedException({
    required this.taskId,
    this.claimedByUid,
    this.message = 'This task has already been claimed by another team member.',
  });

  @override
  String toString() => 'TaskAlreadyClaimedException: $message (Task: $taskId)';
}

/// Abstract contract for managing municipal field tasks.
abstract class TaskRepository {
  /// Real-time stream of all active and relevant tasks for a worker and their crew.
  Stream<List<WorkerTask>> watchTasksForWorker({
    required String tenantId,
    required String workerUid,
    String? teamId,
  });

  /// Single snapshot fetch of tasks for a worker.
  Future<List<WorkerTask>> getTasksForWorker({
    required String tenantId,
    required String workerUid,
    String? teamId,
  });

  /// Fetch a single task by its unique ID within a tenant.
  Future<WorkerTask?> getTaskById({
    required String tenantId,
    required String taskId,
  });

  /// Transition an individually assigned task from `assigned` to `accepted`.
  Future<void> acceptTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  });

  /// Decline an individually assigned task with a mandatory municipal reason.
  Future<void> declineTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    required DeclineReason reason,
    String? note,
  });

  /// Atomically claim an unassigned team-pool task for the claiming worker.
  /// Throws [TaskAlreadyClaimedException] if another worker claimed it first.
  Future<void> claimTeamPoolTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  });

  /// Dismiss an unclaimed team-pool task from this worker's local inbox view.
  Future<void> dismissPoolTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  });

  /// Transition an accepted task to `in_progress`, recording start timestamp and optional GPS location.
  Future<void> startTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    double? latitude,
    double? longitude,
  });

  /// Temporarily pause an in-progress task (e.g. for shift handover, weather hold, or meal break).
  Future<void> pauseTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    String? reason,
  });

  /// Resume a previously paused task back to `in_progress`.
  Future<void> resumeTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  });

  /// Transition an active task to `blocked` with a structured municipal reason and explanation note.
  Future<void> blockTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
    required BlockReason reason,
    String? note,
  });

  /// Remove blocker condition and resume task to `in_progress`.
  Future<void> unblockTask({
    required String tenantId,
    required String taskId,
    required String workerUid,
  });
}
