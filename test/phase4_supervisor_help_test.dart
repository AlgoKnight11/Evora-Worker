import 'package:evora_workers/domain/models/worker_profile.dart';
import 'package:evora_workers/features/auth/providers/auth_provider.dart';
import 'package:evora_workers/features/auth/services/mock_auth_service.dart';
import 'package:evora_workers/features/tasks/providers/task_providers.dart';
import 'package:evora_workers/features/tasks/screens/task_detail_screen.dart';
import 'package:evora_workers/features/tasks/services/mock_task_service.dart';
import 'package:evora_workers/features/tasks/widgets/supervisor_help_dialog.dart';
import 'package:evora_workers/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const testWorker = WorkerProfile(
    uid: 'mock-worker-rajesh-001',
    tenantId: 'tenant_dehradun_01',
    employeeCode: 'EVR-SWM-4091',
    displayName: 'Rajesh Kumar',
    phoneNumber: '+919999999999',
    departmentId: 'dept-swm',
    departmentName: 'Solid Waste Management',
    teamId: 'crew-alpha-12',
    teamName: 'Mall Road Rapid Response Crew',
    authorizedServiceAreaIds: ['ward-12', 'ward-13', 'ward-14'],
    supervisorName: 'Vikram Verma (Chief Sanitary Inspector)',
    supervisorPhone: '+919816000001',
    isActive: true,
  );

  Widget buildTestApp({
    required Widget child,
    List<dynamic> overrides = const [],
    Locale locale = const Locale('en'),
  }) {
    return ProviderScope(
      overrides: [
        ...overrides,
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('hi')],
        home: child,
      ),
    );
  }

  group('Phase 4.3: Supervisor Help Request Engine & UI Tests', () {
    late MockTaskService mockService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockService = MockTaskService();
      mockAuthService = MockAuthService();
    });

    test('MockTaskService.requestSupervisorHelp updates task help flags without modifying status', () async {
      final initialTasks = await mockService.getTasksForWorker(
        tenantId: testWorker.tenantId,
        workerUid: testWorker.uid,
      );
      final task = initialTasks.firstWhere((t) => t.id == 'task_swm_004');
      expect(task.isHelpRequested, isFalse);
      final initialStatus = task.status;

      await mockService.requestSupervisorHelp(
        tenantId: testWorker.tenantId,
        taskId: task.id,
        workerUid: testWorker.uid,
        helpType: 'equipment',
        message: 'Need hydraulic cutter to clear tangled iron wire',
      );

      final updatedTask = await mockService.getTaskById(
        tenantId: testWorker.tenantId,
        taskId: task.id,
      );

      expect(updatedTask, isNotNull);
      expect(updatedTask!.isHelpRequested, isTrue);
      expect(updatedTask.helpRequestType, equals('equipment'));
      expect(updatedTask.helpRequestMessage, equals('Need hydraulic cutter to clear tangled iron wire'));
      expect(updatedTask.helpRequestedAt, isNotNull);
      // Crucial: Task status remains unchanged
      expect(updatedTask.status, equals(initialStatus));
      expect(updatedTask.version, equals(task.version + 1));
    });

    test('MockTaskService.cancelSupervisorHelp clears help request and increments version', () async {
      await mockService.requestSupervisorHelp(
        tenantId: testWorker.tenantId,
        taskId: 'task_swm_004',
        workerUid: testWorker.uid,
        helpType: 'callback',
        message: 'Quick clarification needed',
      );

      final requestedTask = (await mockService.getTaskById(
        tenantId: testWorker.tenantId,
        taskId: 'task_swm_004',
      ))!;
      expect(requestedTask.isHelpRequested, isTrue);

      await mockService.cancelSupervisorHelp(
        tenantId: testWorker.tenantId,
        taskId: 'task_swm_004',
        workerUid: testWorker.uid,
      );

      final cancelledTask = (await mockService.getTaskById(
        tenantId: testWorker.tenantId,
        taskId: 'task_swm_004',
      ))!;
      expect(cancelledTask.isHelpRequested, isFalse);
      expect(cancelledTask.helpRequestType, isNull);
      expect(cancelledTask.helpRequestMessage, isNull);
      expect(cancelledTask.helpRequestedAt, isNull);
      expect(cancelledTask.version, equals(requestedTask.version + 1));
    });

    testWidgets('SupervisorHelpDialog renders options, handles note input, and returns selected result',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ({String helpType, String message})? result;

      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await SupervisorHelpDialog.show(
                  context,
                  taskId: 'task_swm_004',
                  taskTitle: 'Clear Landslide Debris',
                  supervisorName: 'Vikram Verma',
                  supervisorPhone: '+919816000001',
                );
              },
              child: const Text('Open Help Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Help Dialog'));
      await tester.pumpAndSettle();

      // Verify title & quick call supervisor option
      expect(find.byKey(const Key('sheet_supervisor_help')), findsOneWidget);
      expect(find.byKey(const Key('btn_call_supervisor_dialog')), findsOneWidget);

      // Select 'Heavy Machinery / Equipment Assistance'
      final equipOption = find.byKey(const Key('help_type_equipment'));
      expect(equipOption, findsOneWidget);
      await tester.ensureVisible(equipOption);
      await tester.tap(equipOption);
      await tester.pumpAndSettle();

      // Enter note
      final messageField = find.byKey(const Key('input_help_message'));
      expect(messageField, findsOneWidget);
      await tester.ensureVisible(messageField);
      await tester.enterText(messageField, 'Excavator required on site');
      await tester.pumpAndSettle();

      // Submit
      final submitBtn = find.byKey(const Key('btn_submit_help'));
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.helpType, equals('equipment'));
      expect(result!.message, equals('Excavator required on site'));
    });

    testWidgets('TaskDetailScreen AppBar request help button opens dialog and displays supervisor help banner',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockService),
            authRepositoryProvider.overrideWithValue(mockAuthService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
          child: const TaskDetailScreen(taskId: 'task_swm_004'),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify help button in AppBar
      final helpBtn = find.byKey(const Key('btn_request_help_detail'));
      expect(helpBtn, findsOneWidget);

      // 2. Tap help button to open dialog
      await tester.tap(helpBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sheet_supervisor_help')), findsOneWidget);

      // 3. Submit default help (callback)
      final submitBtn = find.byKey(const Key('btn_submit_help'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // 4. Verify banner is now displayed
      expect(find.byKey(const Key('banner_supervisor_help')), findsOneWidget);
      expect(find.byKey(const Key('btn_call_supervisor_banner')), findsOneWidget);
      expect(find.byKey(const Key('btn_cancel_help_detail')), findsOneWidget);

      // Dismiss any active SnackBar before tapping banner button
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // 5. Tap cancel request in banner
      final cancelBtn = find.byKey(const Key('btn_cancel_help_detail'));
      await tester.ensureVisible(cancelBtn);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // 6. Verify banner is dismissed
      expect(find.byKey(const Key('banner_supervisor_help')), findsNothing);
    });
  });
}
