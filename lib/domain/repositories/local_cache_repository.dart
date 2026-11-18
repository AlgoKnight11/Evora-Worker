import '../models/worker_task.dart';

/// Represents a queued offline command waiting for idempotent server replay.
class QueuedWorkerOperation {
  final String operationId;
  final String idempotencyKey;
  final String commandType;
  final String taskId;
  final int expectedVersion;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const QueuedWorkerOperation({
    required this.operationId,
    required this.idempotencyKey,
    required this.commandType,
    required this.taskId,
    required this.expectedVersion,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });
}

/// Repository contract for encrypted local mobile storage (SQLite / secure storage)
/// and local app-private media staging.
/// Respects the configurable 24-hour TTL and full purge on sign-out.
/// Concrete implementation wired in Phase 6.
abstract class LocalCacheRepository {
  Future<void> cacheAuthorizedTasks(List<WorkerTask> tasks, {Duration? ttl});

  Future<List<WorkerTask>> getCachedTasks();

  Future<void> enqueueOperation(QueuedWorkerOperation operation);

  Future<List<QueuedWorkerOperation>> getPendingOperations();

  Future<void> markOperationSynced(String operationId);

  Future<void> pruneExpiredEntries();

  /// Clears all cached sensitive data immediately on sign-out or session expiry.
  Future<void> purgeAllSensitiveData();
}
