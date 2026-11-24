import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/enums/worker_enums.dart';
import '../../domain/models/worker_task.dart';

/// Production notification service managing system permission prompts,
/// municipal dispatch alerts, and condition analysis notification expansion.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  void Function(String taskId)? onTaskSelected;

  static const String channelId = 'evora_worker_dispatches';
  static const String channelName = 'Municipal Dispatches & Grievances';
  static const String channelDescription =
      'Real-time alerts for citizen complaints and high-priority field dispatches.';

  /// True if the current platform natively supports flutter_local_notifications
  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Initializes the local notification plugin and configures Android notification channel
  Future<void> initialize({void Function(String taskId)? onSelectTask}) async {
    if (_isInitialized) return;

    if (onSelectTask != null) {
      onTaskSelected = onSelectTask;
    }

    if (!isSupportedPlatform) {
      _isInitialized = true;
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            final taskId = payload.startsWith('task:')
                ? payload.substring(5)
                : payload;
            if (taskId.isNotEmpty) {
              onTaskSelected?.call(taskId);
            }
          }
        },
      );

      // Create high-importance municipal dispatch channel on Android
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidImplementation.createNotificationChannel(channel);
      }
    } catch (e) {
      debugPrint('[NotificationService] Initialization note: $e');
    }

    _isInitialized = true;
  }

  /// Requests the runtime notification permission (Android 13+ POST_NOTIFICATIONS)
  Future<bool> requestNotificationPermission() async {
    if (!isSupportedPlatform) return true;
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Request permission error: $e');
      return false;
    }
  }

  /// Checks whether notifications are currently allowed by the operating system
  Future<bool> areNotificationsEnabled() async {
    if (!isSupportedPlatform) return true;
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final enabled = await androidImplementation.areNotificationsEnabled();
        return enabled ?? true;
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  /// Displays an immediate high-priority dispatch notification for a newly registered citizen complaint
  Future<void> showTaskDispatchNotification(WorkerTask task) async {
    if (!isSupportedPlatform) return;
    try {
      final priorityTag = switch (task.priority) {
        TaskPriority.p1 => '🚨 [CRITICAL P1]',
        TaskPriority.p2 => '⚠️ [URGENT P2]',
        TaskPriority.p3 => '📋 [NORMAL P3]',
        TaskPriority.p4 => 'ℹ️ [LOW P4]',
      };

      final title = '$priorityTag ${task.title}';
      final summary =
          '${task.location.addressSummary} • ${task.categoryNameSnapshot ?? task.categoryId}';

      final landmarkStr = task.location.landmark != null &&
              task.location.landmark!.trim().isNotEmpty
          ? ' (Near ${task.location.landmark!.trim()})'
          : '';

      final slaRemainingHours = task.dueAt.difference(DateTime.now()).inHours;
      final slaText = slaRemainingHours > 0
          ? 'Within $slaRemainingHours hours'
          : 'SLA overdue / immediate response';

      final conditionDiscussion = '''
📍 Location: ${task.location.addressSummary}$landmarkStr
⚡ Severity: ${task.priority.value.toUpperCase()}
🔍 Citizen Report: "${task.instructions}"
⏳ SLA Target: $slaText
👉 Tap notification to open full task details & accept dispatch.''';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          conditionDiscussion,
          htmlFormatBigText: false,
          contentTitle: title,
          htmlFormatContentTitle: false,
          summaryText: summary,
          htmlFormatSummaryText: false,
        ),
        ticker: 'New Municipal Dispatch Alert',
        category: AndroidNotificationCategory.reminder,
        playSound: true,
        enableVibration: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final id = task.id.hashCode.abs() % 100000;
      await _notificationsPlugin.show(
        id,
        title,
        '${task.location.addressSummary}: ${task.instructions.length > 80 ? "${task.instructions.substring(0, 80)}..." : task.instructions}',
        notificationDetails,
        payload: 'task:${task.id}',
      );
    } catch (e) {
      if (!e.toString().contains('LateInitializationError')) {
        debugPrint('[NotificationService] Notification dispatch note: $e');
      }
    }
  }

  /// Sends a test notification to verify device sound, vibration, and expanded view
  Future<void> showTestNotification() async {
    final sampleTask = WorkerTask(
      id: 'sample_test_dispatch',
      tenantId: 'tenant-shimla-01',
      sourceType: SourceType.civicFlowCase,
      civicFlowCaseId: 'sample_cf_01',
      departmentId: 'Solid Waste Management',
      wardId: 'Ward 12 - Mall Road',
      categoryId: 'waste_management',
      status: TaskStatus.assigned,
      priority: TaskPriority.p1,
      title: 'Overflowing Garbage Bin at Mall Road',
      instructions:
          'Commercial waste accumulated outside the municipal bin container. Citizen reported waste spilling onto walking promenade.',
      location: const TaskLocation(
        latitude: 31.1048,
        longitude: 77.1734,
        addressSummary: 'Mall Road, Shimla',
        landmark: 'Opposite State Bank',
        wardId: 'Ward 12',
      ),
      assignedByUid: 'Municipal Resident',
      assignedAt: DateTime.now(),
      dueAt: DateTime.now().add(const Duration(hours: 4)),
      updatedAt: DateTime.now(),
    );

    await showTaskDispatchNotification(sampleTask);
  }
}
