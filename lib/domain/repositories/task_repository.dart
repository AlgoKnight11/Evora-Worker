import '../enums/worker_enums.dart';
import '../models/safety_alert.dart';
import '../models/task_evidence.dart';
import '../models/worker_task.dart';

/// Repository contract for Field Worker task queries and server-validated commands.
/// Concrete Firestore + Cloud Functions implementation wired in Phases 3–5.
abstract class TaskRepository {
  Stream<List<WorkerTask>> watchAssignedTasks({
    required String tenantId,
    required String workerUid,
  });

  Stream<List<WorkerTask>> watchTeamPoolTasks({
    required String tenantId,
    required String teamId,
    required String workerUid,
  });

  Future<WorkerTask> acceptTask({
    required String taskId,
    required int expectedVersion,
    required String idempotencyKey,
  });

  /// Atomic first-successful claim for an unclaimed team-pool task.
  Future<WorkerTask> claimTeamPoolTask({
    required String taskId,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<void> declineTask({
    required String taskId,
    required DeclineReason reason,
    String? note,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<WorkerTask> updateTaskProgress({
    required String taskId,
    required TaskStatus targetStatus,
    required int expectedVersion,
    required String idempotencyKey,
    double? latitude,
    double? longitude,
  });

  Future<WorkerTask> blockTask({
    required String taskId,
    required BlockReason reason,
    required String note,
    String? blockerPhotoPath,
    required int expectedVersion,
    required String idempotencyKey,
  });

  Future<void> requestSupervisorHelp({
    required String taskId,
    required String message,
    required String idempotencyKey,
  });

  Future<SafetyAlert> reportSafetyIncident({
    required String tenantId,
    String? taskId,
    required String hazardType,
    required String description,
    double? latitude,
    double? longitude,
    String? photoStoragePath,
    required String idempotencyKey,
  });

  Future<WorkerTask> submitTaskCompletion({
    required String taskId,
    required String completionNote,
    required List<TaskEvidence> evidence,
    required List<ChecklistResponse> checklistResponses,
    required List<MeasurementRecord> measurements,
    required AcknowledgementRecord acknowledgement,
    required int expectedVersion,
    required String idempotencyKey,
  });
}
