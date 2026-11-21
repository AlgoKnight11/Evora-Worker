import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/worker_task.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/task_filter.dart';
import '../repositories/task_repository.dart';
import '../services/firestore_task_service.dart';
import '../services/mock_task_service.dart';

/// Provider for the TaskRepository implementation.
/// Defaults to [FirestoreTaskService] if Firebase is initialized, otherwise falls back to [MockTaskService].
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirestoreTaskService();
    }
  } catch (_) {}
  return MockTaskService();
});

/// Real-time stream of all active municipal tasks dispatched to the logged-in worker & crew.
final tasksStreamProvider = StreamProvider<List<WorkerTask>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final profile = authState.profile;

  if (profile == null) {
    return Stream.value(const []);
  }

  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTasksForWorker(
    tenantId: profile.tenantId,
    workerUid: profile.uid,
    teamId: profile.teamId,
  );
});

/// Selected filter state for the task inbox queue.
final taskFilterProvider = StateProvider<TaskFilter>((ref) {
  return const TaskFilter();
});

/// Active list of tasks filtered by tab, priority, assignment scope, and search.
final filteredTasksProvider = Provider<List<WorkerTask>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final filter = ref.watch(taskFilterProvider);
  final workerUid = ref.watch(authNotifierProvider).profile?.uid ?? '';

  return tasksAsync.maybeWhen(
    data: (tasks) => tasks.where((t) => filter.matches(t, workerUid)).toList(),
    orElse: () => const [],
  );
});

/// Metrics for the Overview dashboard (`/overview`).
class OverviewMetrics {
  final int totalToday;
  final int assignedCount;
  final int inProgressCount;
  final int blockedCount;
  final List<WorkerTask> urgentTasks;

  const OverviewMetrics({
    required this.totalToday,
    required this.assignedCount,
    required this.inProgressCount,
    required this.blockedCount,
    required this.urgentTasks,
  });

  const OverviewMetrics.empty()
      : totalToday = 0,
        assignedCount = 0,
        inProgressCount = 0,
        blockedCount = 0,
        urgentTasks = const [];
}

/// Provider computing metrics from the active task stream for the Overview dashboard.
final overviewMetricsProvider = Provider<OverviewMetrics>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);

  return tasksAsync.maybeWhen(
    data: (tasks) {
      int assigned = 0;
      int inProgress = 0;
      int blocked = 0;
      final urgent = <WorkerTask>[];

      for (final t in tasks) {
        if (t.status == TaskStatus.assigned) assigned++;
        if (t.status == TaskStatus.inProgress) inProgress++;
        if (t.status == TaskStatus.blocked) blocked++;

        if (t.priority == TaskPriority.p1 || t.isOverdue) {
          urgent.add(t);
        }
      }

      return OverviewMetrics(
        totalToday: tasks.length,
        assignedCount: assigned,
        inProgressCount: inProgress,
        blockedCount: blocked,
        urgentTasks: urgent,
      );
    },
    orElse: () => const OverviewMetrics.empty(),
  );
});

/// State controller for task assignment operations (accept, decline, claim, dismiss).
class TaskOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final TaskRepository _repo;
  final Ref _ref;

  TaskOperationsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> acceptTask(String taskId) async {
    final profile = _ref.read(authNotifierProvider).profile;
    if (profile == null) return false;

    state = const AsyncValue.loading();
    try {
      await _repo.acceptTask(
        tenantId: profile.tenantId,
        taskId: taskId,
        workerUid: profile.uid,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> declineTask({
    required String taskId,
    required DeclineReason reason,
    String? note,
  }) async {
    final profile = _ref.read(authNotifierProvider).profile;
    if (profile == null) return false;

    state = const AsyncValue.loading();
    try {
      await _repo.declineTask(
        tenantId: profile.tenantId,
        taskId: taskId,
        workerUid: profile.uid,
        reason: reason,
        note: note,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> claimTeamPoolTask(String taskId) async {
    final profile = _ref.read(authNotifierProvider).profile;
    if (profile == null) return false;

    state = const AsyncValue.loading();
    try {
      await _repo.claimTeamPoolTask(
        tenantId: profile.tenantId,
        taskId: taskId,
        workerUid: profile.uid,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> dismissPoolTask(String taskId) async {
    final profile = _ref.read(authNotifierProvider).profile;
    if (profile == null) return false;

    state = const AsyncValue.loading();
    try {
      await _repo.dismissPoolTask(
        tenantId: profile.tenantId,
        taskId: taskId,
        workerUid: profile.uid,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final taskOperationsProvider =
    StateNotifierProvider<TaskOperationsNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return TaskOperationsNotifier(repo, ref);
});
