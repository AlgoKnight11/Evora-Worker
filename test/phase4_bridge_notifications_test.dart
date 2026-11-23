import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:evora_workers/core/localization/locale_provider.dart';
import 'package:evora_workers/core/services/notification_service.dart';
import 'package:evora_workers/domain/enums/worker_enums.dart';
import 'package:evora_workers/domain/models/worker_task.dart';
import 'package:evora_workers/features/notifications/providers/notification_providers.dart';
import 'package:evora_workers/features/notifications/screens/notifications_screen.dart';
import 'package:evora_workers/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences testPrefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    testPrefs = await SharedPreferences.getInstance();
  });

  group('Phase 4.6 & Citizen-Worker Bridge: Notification Service Tests', () {
    test('1. NotificationService initializes and formats condition analysis properly', () async {
      final notifService = NotificationService.instance;
      expect(notifService, isNotNull);

      final task = WorkerTask(
        id: 'task_cf_test_101',
        tenantId: 'tenant-shimla-01',
        sourceType: SourceType.civicFlowCase,
        civicFlowCaseId: 'cf_test_101',
        departmentId: 'Solid Waste Management',
        wardId: 'Ward 12 - Mall Road',
        categoryId: 'waste_management',
        categoryNameSnapshot: 'Overflowing Garbage Bin',
        status: TaskStatus.assigned,
        priority: TaskPriority.p1,
        title: '[CF-2026-102938] Overflowing Garbage Bin',
        instructions:
            'Public waste bin overflowing onto main walking footpath. Urgent clearance requested.',
        location: const TaskLocation(
          latitude: 31.1048,
          longitude: 77.1734,
          addressSummary: 'Mall Road, Shimla',
          landmark: 'Near Gandhi Statue',
          wardId: 'Ward 12',
        ),
        assignedByUid: 'Resident Amit',
        assignedAt: DateTime.now(),
        dueAt: DateTime.now().add(const Duration(hours: 4)),
        updatedAt: DateTime.now(),
      );

      // Verify that formatting and notification display completes without error
      await expectLater(
        notifService.showTaskDispatchNotification(task),
        completes,
      );
    });

    test('2. DispatchNotificationNotifier tracks known tasks and triggers alerts on new citizen complaints', () {
      final notifier = DispatchNotificationNotifier(testPrefs);

      final existingTask = WorkerTask(
        id: 'task_cf_initial_01',
        tenantId: 'tenant-shimla-01',
        sourceType: SourceType.civicFlowCase,
        civicFlowCaseId: 'cf_initial_01',
        departmentId: 'Solid Waste Management',
        wardId: 'Ward 12',
        categoryId: 'waste_management',
        status: TaskStatus.assigned,
        priority: TaskPriority.p2,
        title: 'Initial Seed Task',
        instructions: 'Previously registered complaint.',
        location: const TaskLocation(
          latitude: 31.10,
          longitude: 77.17,
          addressSummary: 'Lower Bazaar',
          wardId: 'Ward 12',
        ),
        assignedByUid: 'System',
        assignedAt: DateTime.now(),
        dueAt: DateTime.now().add(const Duration(hours: 12)),
        updatedAt: DateTime.now(),
      );

      // First run: Seeds existing tasks
      notifier.processIncomingTasks([existingTask]);
      expect(notifier.state.length, 1);
      expect(notifier.state.first.taskId, 'task_cf_initial_01');

      // Second run: A new citizen complaint arrives
      final newComplaintTask = WorkerTask(
        id: 'task_cf_new_02',
        tenantId: 'tenant-shimla-01',
        sourceType: SourceType.civicFlowCase,
        civicFlowCaseId: 'cf_new_02',
        departmentId: 'Roads & Infrastructure',
        wardId: 'Ward 14 - Cart Road',
        categoryId: 'pothole',
        status: TaskStatus.assigned,
        priority: TaskPriority.p1,
        title: '[CF-2026-991823] Dangerous Pothole',
        instructions: 'Deep pothole causing vehicle hazard on Cart Road near Lift.',
        location: const TaskLocation(
          latitude: 31.102,
          longitude: 77.171,
          addressSummary: 'Cart Road',
          landmark: 'Near Lift',
          wardId: 'Ward 14',
        ),
        assignedByUid: 'Citizen Priya',
        assignedAt: DateTime.now(),
        dueAt: DateTime.now().add(const Duration(hours: 4)),
        updatedAt: DateTime.now(),
      );

      notifier.processIncomingTasks([existingTask, newComplaintTask]);
      expect(notifier.state.length, 2);
      expect(notifier.state.first.taskId, 'task_cf_new_02');
      expect(notifier.state.first.priority, TaskPriority.p1);
    });

    testWidgets('3. NotificationsScreen renders permission card, test button, and dispatch list', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final testItem = WorkerNotificationItem(
        id: 'notif_1',
        taskId: 'task_cf_101',
        title: '[CF-2026-102938] Overflowing Bin',
        message: 'Mall Road: Commercial waste spilling onto footpath',
        priority: TaskPriority.p1,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(testPrefs),
            notificationPermissionProvider.overrideWith(
              (ref) => NotificationPermissionNotifier(),
            ),
            dispatchNotificationProvider.overrideWith(
              (ref) {
                final n = DispatchNotificationNotifier(testPrefs);
                n.state = [testItem];
                return n;
              },
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header subtitle
      expect(find.text('New assignments, SLA reminders, supervisor feedback, and schedule changes'), findsOneWidget);

      // Verify test notification button exists
      expect(find.byKey(const Key('notif_test_button')), findsOneWidget);

      // Verify dispatch card rendered with priority and details
      expect(find.text('P1 PRIORITY'), findsOneWidget);
      expect(find.text('[CF-2026-102938] Overflowing Bin'), findsOneWidget);
      expect(find.text('Mall Road: Commercial waste spilling onto footpath'), findsOneWidget);
      expect(find.text('View & Accept Task'), findsOneWidget);
    });
  });
}
