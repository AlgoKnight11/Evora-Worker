import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/worker_task.dart';
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
  bool _hasSeeded = false;

  static const String _prefKnownTaskIdsKey = 'evora_worker_known_task_ids';

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

  /// Processes active tasks from stream, seeding on first load and triggering push on new complaints
  void processIncomingTasks(List<WorkerTask> tasks) {
    if (!_hasSeeded) {
      for (final t in tasks) {
        _knownTaskIds.add(t.id);
      }
      _hasSeeded = true;
      _saveKnownTaskIds();

      // Seed in-app list with active tasks
      final initialNotifications = tasks.map((t) {
        return WorkerNotificationItem(
          id: 'notif_${t.id}',
          taskId: t.id,
          title: t.title,
          message:
              '${t.location.addressSummary}: ${t.instructions.length > 80 ? "${t.instructions.substring(0, 80)}..." : t.instructions}',
          priority: t.priority,
          timestamp: t.assignedAt,
        );
      }).toList();
      state = initialNotifications;
      return;
    }

    final newItems = <WorkerNotificationItem>[];

    for (final task in tasks) {
      if (!_knownTaskIds.contains(task.id)) {
        _knownTaskIds.add(task.id);

        // 1. Trigger system notification on phone with sound, vibration & BigTextStyle
        NotificationService.instance.showTaskDispatchNotification(task);

        // 2. Add to in-app notification list
        final item = WorkerNotificationItem(
          id: 'notif_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
          taskId: task.id,
          title: task.title,
          message:
              '${task.location.addressSummary}: ${task.instructions.length > 80 ? "${task.instructions.substring(0, 80)}..." : task.instructions}',
          priority: task.priority,
          timestamp: DateTime.now(),
        );
        newItems.add(item);
      }
    }

    if (newItems.isNotEmpty) {
      _saveKnownTaskIds();
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

  // Seed with current tasks if already loaded
  final currentTasks = ref.watch(tasksStreamProvider).valueOrNull;
  if (currentTasks != null && currentTasks.isNotEmpty) {
    notifier.processIncomingTasks(currentTasks);
  }

  // Bind to tasksStreamProvider to continuously detect newly filed citizen complaints
  ref.listen<AsyncValue<List<WorkerTask>>>(tasksStreamProvider, (_, next) {
    next.whenData((tasks) {
      notifier.processIncomingTasks(tasks);
    });
  });

  return notifier;
});
