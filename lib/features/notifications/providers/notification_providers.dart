import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/municipal_taxonomy.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/worker_task.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tasks/providers/task_providers.dart';

/// Notification Permission state notifier (true = granted, false = denied/unrequested)
class NotificationPermissionNotifier extends StateNotifier<bool> {
  NotificationPermissionNotifier() : super(false) {
    checkPermission();
  }

  Future<void> checkPermission() async {
    final enabled = await NotificationService.instance.areNotificationsEnabled();
    state = enabled;
  }

  Future<bool> requestPermission() async {
    final granted =
        await NotificationService.instance.requestNotificationPermission();
    state = granted;
    return granted;
  }

  Future<void> sendTestNotification() async {
    await NotificationService.instance.showTestNotification();
  }
}

final notificationPermissionProvider =
    StateNotifierProvider<NotificationPermissionNotifier, bool>((ref) {
  return NotificationPermissionNotifier();
});

/// In-app notification item representation
class WorkerNotificationItem {
  final String id;
  final String taskId;
  final String title;
  final String message;
  final TaskPriority priority;
  final DateTime timestamp;
  final bool isRead;

  const WorkerNotificationItem({
    required this.id,
    required this.taskId,
    required this.title,
    required this.message,
    required this.priority,
    required this.timestamp,
    this.isRead = false,
  });

  WorkerNotificationItem copyWith({bool? isRead}) {
    return WorkerNotificationItem(
      id: id,
      taskId: taskId,
      title: title,
      message: message,
      priority: priority,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// State notifier for in-app municipal dispatch alerts and real-time push triggering
class DispatchNotificationNotifier
    extends StateNotifier<List<WorkerNotificationItem>> {
  final SharedPreferences? _prefs;
  final Set<String> _knownTaskIds = {};

  static const String _prefKnownTaskIdsKey = 'evora_worker_known_task_ids_v2';

  DispatchNotificationNotifier(this._prefs) : super(const []) {
    _loadKnownTaskIds();
  }

  void _loadKnownTaskIds() {
    if (_prefs != null) {
      final list = _prefs.getStringList(_prefKnownTaskIdsKey) ?? [];
      _knownTaskIds.addAll(list);
    }
  }

  void _saveKnownTaskIds() {
    _prefs?.setStringList(_prefKnownTaskIdsKey, _knownTaskIds.toList());
  }

  /// Processes active tasks from stream, filtering by worker department and alerting on new grievances
  void processIncomingTasks(List<WorkerTask> tasks, {String? workerDepartment}) {
    // 1. Department Scoping: Only process tasks that match the worker's operational department
    final relevantTasks = tasks.where((task) {
      if (workerDepartment == null || workerDepartment.trim().isEmpty) return true;
      if (task.workerUid != null) return true; // directly assigned to this worker
      return MunicipalTaxonomyBridge.matchesWorkerDepartment(
        workerDepartment: workerDepartment,
        taskDepartment: task.departmentId,
        taskCategory: task.categoryId,
      );
    }).toList();

    final newItems = <WorkerNotificationItem>[];
    final unnotifiedTasks = <WorkerTask>[];

    for (final task in relevantTasks) {
      if (!_knownTaskIds.contains(task.id)) {
        _knownTaskIds.add(task.id);
        unnotifiedTasks.add(task);

        // Add to in-app notification list
        final item = WorkerNotificationItem(
          id: 'notif_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
          taskId: task.id,
          title: task.title,
          message:
              '${task.location.addressSummary}: ${task.instructions.length > 80 ? "${task.instructions.substring(0, 80)}..." : task.instructions}',
          priority: task.priority,
          timestamp: task.assignedAt,
        );
        newItems.add(item);
      }
    }

    // Trigger system notifications on the phone for newly detected grievance dispatches
    if (unnotifiedTasks.isNotEmpty) {
      _saveKnownTaskIds();
      // Sort so most urgent complaints alert first
      unnotifiedTasks.sort((a, b) => a.priority.index.compareTo(b.priority.index));
      for (final task in unnotifiedTasks.take(3)) {
        debugPrint('[DispatchNotificationNotifier] Alerting worker on dispatch: ${task.id} - ${task.title}');
        NotificationService.instance.showTaskDispatchNotification(task);
      }
    }

    if (newItems.isNotEmpty) {
      state = [...newItems, ...state];
    }
  }

  void markAsRead(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
  }

  void clearAll() {
    state = const [];
  }
}

final dispatchNotificationProvider = StateNotifierProvider<
    DispatchNotificationNotifier, List<WorkerNotificationItem>>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {}

  final notifier = DispatchNotificationNotifier(prefs);
  final workerDept = ref.watch(authNotifierProvider).profile?.departmentId;

  // Seed with current tasks if already loaded
  final currentTasks = ref.watch(tasksStreamProvider).valueOrNull;
  if (currentTasks != null && currentTasks.isNotEmpty) {
    notifier.processIncomingTasks(currentTasks, workerDepartment: workerDept);
  }

  // Bind to tasksStreamProvider to continuously detect newly filed citizen complaints
  ref.listen<AsyncValue<List<WorkerTask>>>(tasksStreamProvider, (_, next) {
    next.whenData((tasks) {
      final dept = ref.read(authNotifierProvider).profile?.departmentId;
      notifier.processIncomingTasks(tasks, workerDepartment: dept);
    });
  });

  return notifier;
});
