import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/worker_task.dart';

/// Scope of work assignment in the queue.
enum TaskScope {
  all,
  individual,
  teamPool,
}

/// Filter state for the worker task inbox.
class TaskFilter {
  final TaskStatus? statusTab;
  final TaskScope scope;
  final TaskPriority? priority;
  final String? wardId;
  final String? categoryId;
  final String searchQuery;
  final bool showOverdueOnly;

  const TaskFilter({
    this.statusTab,
    this.scope = TaskScope.all,
    this.priority,
    this.wardId,
    this.categoryId,
    this.searchQuery = '',
    this.showOverdueOnly = false,
  });

  TaskFilter copyWith({
    TaskStatus? statusTab,
    bool clearStatusTab = false,
    TaskScope? scope,
    TaskPriority? priority,
    bool clearPriority = false,
    String? wardId,
    bool clearWard = false,
    String? categoryId,
    bool clearCategory = false,
    String? searchQuery,
    bool? showOverdueOnly,
  }) {
    return TaskFilter(
      statusTab: clearStatusTab ? null : (statusTab ?? this.statusTab),
      scope: scope ?? this.scope,
      priority: clearPriority ? null : (priority ?? this.priority),
      wardId: clearWard ? null : (wardId ?? this.wardId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      showOverdueOnly: showOverdueOnly ?? this.showOverdueOnly,
    );
  }

  bool matches(WorkerTask task, String currentWorkerUid) {
    // 1. Status tab filter
    if (statusTab != null && task.status != statusTab) {
      return false;
    }

    // 2. Assignment scope filter
    if (scope == TaskScope.individual && task.workerUid != currentWorkerUid) {
      return false;
    }
    if (scope == TaskScope.teamPool && !task.isUnclaimedTeamPool) {
      return false;
    }

    // 3. Priority filter
    if (priority != null && task.priority != priority) {
      return false;
    }

    // 4. Ward filter
    if (wardId != null && task.wardId != wardId) {
      return false;
    }

    // 5. Category filter
    if (categoryId != null && task.categoryId != categoryId) {
      return false;
    }

    // 6. Overdue filter
    if (showOverdueOnly && !task.isOverdue) {
      return false;
    }

    // 7. Search query filter
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      final titleMatch = task.title.toLowerCase().contains(q);
      final idMatch = task.id.toLowerCase().contains(q);
      final landmarkMatch = task.location.landmark?.toLowerCase().contains(q) ?? false;
      final addressMatch = task.location.addressSummary.toLowerCase().contains(q);
      final civicFlowMatch = task.civicFlowCaseId?.toLowerCase().contains(q) ?? false;

      if (!titleMatch && !idMatch && !landmarkMatch && !addressMatch && !civicFlowMatch) {
        return false;
      }
    }

    return true;
  }
}
