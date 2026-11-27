import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../constants/municipal_taxonomy.dart';
import '../../domain/models/worker_task.dart';
import 'notification_service.dart';

/// Top-level callback for flutter_foreground_task.
/// Must be a top-level or static function with @pragma('vm:entry-point')
@pragma('vm:entry-point')
void startForegroundDispatcher() {
  FlutterForegroundTask.setTaskHandler(WorkerDispatchTaskHandler());
}

/// TaskHandler running inside the persistent Android Foreground Service isolate.
/// Because Android grants Foreground Services continuous background execution,
/// this listener survives app swipe-away / task killer events!
class WorkerDispatchTaskHandler extends TaskHandler {
  StreamSubscription? _tasksSub;
  final Set<String> _knownTaskIds = {};
  String _tenantId = AppConstants.defaultTenantId;
  String _departmentId = 'Solid Waste Management';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final prefs = await SharedPreferences.getInstance();
      _tenantId = prefs.getString(ForegroundDispatchService.prefDutyTenantId) ??
          AppConstants.defaultTenantId;
      _departmentId = prefs.getString(ForegroundDispatchService.prefDutyDepartmentId) ??
          'Solid Waste Management';

      await NotificationService.instance.initialize();

      // Seed already existing task IDs so we only alert for NEW complaints!
      try {
        final existing = await FirebaseFirestore.instance
            .collection('tenants')
            .doc(_tenantId)
            .collection('tasks')
            .get();
        for (final doc in existing.docs) {
          _knownTaskIds.add(doc.id);
        }
      } catch (e) {
        debugPrint('[WorkerDispatchTaskHandler] Seed error: $e');
      }

      // Real-time Firestore stream inside persistent foreground service
      _tasksSub = FirebaseFirestore.instance
          .collection('tenants')
          .doc(_tenantId)
          .collection('tasks')
          .snapshots()
          .listen((snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final doc = change.doc;
            final taskId = doc.id;
            final data = doc.data();

            if (data != null && !_knownTaskIds.contains(taskId)) {
              _knownTaskIds.add(taskId);

              final taskDept = data['departmentId'] as String? ?? '';
              final taskCat = data['categoryId'] as String? ?? '';
              final status = data['status'] as String? ?? 'assigned';

              if (MunicipalTaxonomyBridge.matchesWorkerDepartment(
                    workerDepartment: _departmentId,
                    taskDepartment: taskDept,
                    taskCategory: taskCat,
                  ) &&
                  status == 'assigned') {
                _triggerDispatchAlert(data, taskId);
              }
            }
          }
        }
      }, onError: (e) {
        debugPrint('[WorkerDispatchTaskHandler] tasks stream error: $e');
      });
    } catch (e) {
      debugPrint('[WorkerDispatchTaskHandler] onStart fatal: $e');
    }
  }

  void _triggerDispatchAlert(Map<String, dynamic> data, String taskId) {
    try {
      final task = WorkerTask.fromJson(data);
      NotificationService.instance.showTaskDispatchNotification(task);
    } catch (e) {
      final title = data['title'] as String? ?? 'New Municipal Grievance';
      final instructions = data['instructions'] as String? ?? '';
      final locationMap = data['location'] as Map<String, dynamic>?;
      final address = locationMap?['addressSummary'] as String? ?? 'Doon Municipal Area';
      final priority = (data['priority'] as String? ?? 'p3').toUpperCase();

      NotificationService.instance.showCustomNotification(
        title: '🚨 [$priority] $title',
        body: '📍 Location: $address\n⚡ Severity: $priority\n🔍 Report: "$instructions"',
        taskId: taskId,
      );
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    // 30-second resilience cycle: check for any missed assigned tasks
    try {
      if (Firebase.apps.isNotEmpty) {
        final query = await FirebaseFirestore.instance
            .collection('tenants')
            .doc(_tenantId)
            .collection('tasks')
            .where('status', isEqualTo: 'assigned')
            .limit(20)
            .get();

        for (final doc in query.docs) {
          final taskId = doc.id;
          if (!_knownTaskIds.contains(taskId)) {
            _knownTaskIds.add(taskId);
            final data = doc.data();
            final taskDept = data['departmentId'] as String? ?? '';
            final taskCat = data['categoryId'] as String? ?? '';
            if (MunicipalTaxonomyBridge.matchesWorkerDepartment(
                  workerDepartment: _departmentId,
                  taskDepartment: taskDept,
                  taskCategory: taskCat,
                )) {
              _triggerDispatchAlert(data, taskId);
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _tasksSub?.cancel();
    _tasksSub = null;
  }
}

/// Managing service for the worker's "On-Duty / Shift Active" state
class ForegroundDispatchService {
  ForegroundDispatchService._();

  static const String prefDutyTenantId = 'pref_duty_tenant_id';
  static const String prefDutyDepartmentId = 'pref_duty_department_id';
  static const String prefIsOnDuty = 'pref_is_on_duty';

  static bool _initialized = false;

  /// Initializes Android notification channels and ForegroundTask options
  static Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'evora_worker_duty_service',
          channelName: 'Evora Field Duty Active',
          channelDescription:
              'Persistent service keeping municipal field dispatches connected even when closed.',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(30000), // 30s resilience poll
          autoRunOnBoot: true,
          autoRunOnMyPackageReplaced: true,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
    }

    _initialized = true;
  }

  /// Checks if worker is currently marked On-Duty with active Foreground Service
  static Future<bool> isDutyActive() async {
    try {
      return await FlutterForegroundTask.isRunningService;
    } catch (_) {
      return false;
    }
  }

  /// Starts the Foreground Service (Clock-in / On Duty)
  static Future<bool> startDuty({
    required String tenantId,
    required String departmentId,
  }) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return true;
    }
    try {
      await init();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefDutyTenantId, tenantId);
      await prefs.setString(prefDutyDepartmentId, departmentId);
      await prefs.setBool(prefIsOnDuty, true);

      // Request runtime notification permission if needed
      final perm = await FlutterForegroundTask.checkNotificationPermission();
      if (perm != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
        return true;
      }

      final result = await FlutterForegroundTask.startService(
        serviceId: 1001,
        notificationTitle: 'Evora Field Dispatch Active • On Duty',
        notificationText: 'Live monitoring for $departmentId dispatches in Dehradun',
        callback: startForegroundDispatcher,
      );

      return result is ServiceRequestSuccess;
    } catch (e) {
      debugPrint('[ForegroundDispatchService] startDuty error: $e');
      return false;
    }
  }

  /// Stops the Foreground Service (Clock-out / Off Duty)
  static Future<bool> stopDuty() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return true;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefIsOnDuty, false);

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
      return true;
    } catch (e) {
      debugPrint('[ForegroundDispatchService] stopDuty error: $e');
      return false;
    }
  }
}
