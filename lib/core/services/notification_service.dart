import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/enums/worker_enums.dart';
import '../../domain/models/worker_task.dart';

/// Top-level background message handler for FCM.
/// Must be annotated with @pragma('vm:entry-point') to prevent tree-shaking
/// and allow Android OS to wake up this entry point when the app is killed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  debugPrint('[NotificationService] Terminated/Background FCM received: ${message.messageId}');
}

/// Production notification service managing system permission prompts,
/// Firebase Cloud Messaging (FCM) push alerts, municipal dispatch channels,
/// and deep-linking into assigned field tasks.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  void Function(String taskId)? onTaskSelected;
  String? _pendingTaskIdToOpen;

  static const String channelId = 'evora_worker_dispatches_v2';
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

  /// True if Firebase is initialized in the active runtime
  bool get isFirebaseAvailable => Firebase.apps.isNotEmpty;

  /// Pending task ID clicked while app was cold-starting
  String? consumePendingTaskId() {
    final id = _pendingTaskIdToOpen;
    _pendingTaskIdToOpen = null;
    return id;
  }

  /// Initializes the local notification plugin, creates high-priority Android channel,
  /// and configures Firebase Cloud Messaging handlers.
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

      // Initialize Firebase Cloud Messaging if Firebase is initialized
      if (isFirebaseAvailable) {
        await _initializeFirebaseMessaging();
      }
    } catch (e) {
      debugPrint('[NotificationService] Initialization note: $e');
    }

    _isInitialized = true;
  }

  /// Configures FCM background handler, foreground listener, and notification click intents
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // 1. Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // 2. Request permission (safe for Android 13+ and iOS)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // 3. Set foreground presentation options
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Foreground FCM message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[NotificationService] Foreground FCM received: ${message.notification?.title}');
        final notification = message.notification;
        if (notification != null) {
          final taskId = message.data['taskId'] as String?;
          showCustomNotification(
            title: notification.title ?? 'New Municipal Dispatch Alert',
            body: notification.body ?? '',
            taskId: taskId,
          );
        }
      });

      // 5. Background notification click (app in background/recent apps)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[NotificationService] App opened from FCM click: ${message.data}');
        final taskId = message.data['taskId'] as String?;
        if (taskId != null && taskId.isNotEmpty) {
          onTaskSelected?.call(taskId);
        }
      });

      // 6. Cold-start notification click (app was terminated/killed)
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[NotificationService] App launched from terminated state via FCM: ${initialMessage.data}');
        final taskId = initialMessage.data['taskId'] as String?;
        if (taskId != null && taskId.isNotEmpty) {
          _pendingTaskIdToOpen = taskId;
          onTaskSelected?.call(taskId);
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] FirebaseMessaging setup note: $e');
    }
  }

  /// Subscribes worker device to municipal department FCM topics and registers device token
  Future<void> subscribeWorkerTopics({
    required String tenantId,
    required String departmentId,
    String? workerUid,
  }) async {
    if (!isSupportedPlatform || !isFirebaseAvailable) return;
    try {
      final messaging = FirebaseMessaging.instance;

      // Request runtime notification permission
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final cleanTenant = tenantId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
      final deptSlug = normalizeDeptSlug(departmentId);

      final deptTopic = '${cleanTenant}_$deptSlug';
      final allTopic = '${cleanTenant}_all_dispatches';

      await messaging.subscribeToTopic(deptTopic);
      await messaging.subscribeToTopic(allTopic);
      debugPrint('[NotificationService] Subscribed to FCM topics: $deptTopic, $allTopic');

      final token = await messaging.getToken();
      debugPrint('[NotificationService] FCM Registration Token: $token');

      // Save FCM token to worker record in Firestore if available
      if (workerUid != null && token != null && token.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('tenants')
              .doc(tenantId)
              .collection('workers')
              .doc(workerUid)
              .set({
            'fcmToken': token,
            'fcmTopics': [deptTopic, allTopic],
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint('[NotificationService] FCM token saved to worker profile in Firestore');
        } catch (e) {
          debugPrint('[NotificationService] Note saving token to Firestore: $e');
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] subscribeWorkerTopics error: $e');
    }
  }

  /// Normalizes a human or raw department name into a canonical FCM topic slug
  static String normalizeDeptSlug(String department) {
    final d = department.toLowerCase();
    if (d.contains('solid_waste') || d.contains('waste') || d.contains('garbage') || d.contains('clean')) {
      return 'solid_waste';
    } else if (d.contains('road') || d.contains('traffic') || d.contains('street') || d.contains('pothole')) {
      return 'roads';
    } else if (d.contains('water') || d.contains('drain') || d.contains('sewer') || d.contains('leak')) {
      return 'water_supply';
    } else if (d.contains('elect') || d.contains('light') || d.contains('power')) {
      return 'electricity';
    }
    return 'general';
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

  /// Displays a custom or push notification banner with high priority
  Future<void> showCustomNotification({
    required String title,
    required String body,
    String? taskId,
  }) async {
    if (!isSupportedPlatform) return;
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: false,
          contentTitle: title,
          htmlFormatContentTitle: false,
        ),
        ticker: 'New Municipal Dispatch Alert',
        category: AndroidNotificationCategory.reminder,
        playSound: true,
        enableVibration: true,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _notificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(android: androidDetails),
        payload: taskId != null ? 'task:$taskId' : null,
      );
    } catch (e) {
      debugPrint('[NotificationService] showCustomNotification note: $e');
    }
  }

  /// Sends a test notification to verify device sound, vibration, and expanded view
  Future<void> showTestNotification() async {
    final sampleTask = WorkerTask(
      id: 'sample_test_dispatch',
      tenantId: 'tenant_dehradun_01',
      sourceType: SourceType.civicFlowCase,
      civicFlowCaseId: 'sample_cf_01',
      departmentId: 'Solid Waste Management',
      wardId: 'Ward 12 - Rajpur Road',
      categoryId: 'waste_management',
      status: TaskStatus.assigned,
      priority: TaskPriority.p1,
      title: 'Overflowing Garbage Bin at Rajpur Road',
      instructions:
          'Commercial waste accumulated outside the municipal bin container. Citizen reported waste spilling onto walking promenade.',
      location: const TaskLocation(
        latitude: 30.3165,
        longitude: 78.0322,
        addressSummary: 'Rajpur Road, Dehradun',
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
