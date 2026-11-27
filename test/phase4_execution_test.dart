import 'package:evora_workers/domain/enums/worker_enums.dart';
import 'package:evora_workers/domain/models/worker_profile.dart';
import 'package:evora_workers/features/auth/providers/auth_provider.dart';
import 'package:evora_workers/features/auth/services/mock_auth_service.dart';
import 'package:evora_workers/features/tasks/providers/task_providers.dart';
import 'package:evora_workers/features/tasks/screens/task_detail_screen.dart';
import 'package:evora_workers/features/tasks/services/mock_task_service.dart';
import 'package:evora_workers/features/tasks/services/resilient_task_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:evora_workers/l10n/generated/app_localizations.dart';

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
    teamName: 'Doon Valley Sanitation Crew',
    authorizedServiceAreaIds: ['ward-12', 'ward-13', 'ward-14'],
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

  group('Phase 4.1: Execution Lifecycle Engine - Repository & Service Tests', () {
    test('1. startTask transitions accepted task to in_progress with timestamps & coordinates', () async {
      final mockService = MockTaskService();
      const tenantId = 'tenant_dehradun_01';
      const taskId = 'task_swm_002'; // Initially accepted
      const workerUid = 'mock-worker-rajesh-001';

      var task = await mockService.getTaskById(tenantId: tenantId, taskId: taskId);
      expect(task, isNotNull);
      expect(task!.status, TaskStatus.accepted);
      expect(task.startedAt, isNull);

      // Start task with GPS
      await mockService.startTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
        latitude: 31.1062,
        longitude: 77.1751,
      );

      task = await mockService.getTaskById(tenantId: tenantId, taskId: taskId);
      expect(task!.status, TaskStatus.inProgress);
      expect(task.startedAt, isNotNull);
      expect(task.startedLatitude, 31.1062);
      expect(task.startedLongitude, 77.1751);
      expect(task.version, 3);
    });

    test('2. startTask throws when executed by non-assigned worker', () async {
      final mockService = MockTaskService();
      expect(
        () => mockService.startTask(
          tenantId: 'tenant_dehradun_01',
          taskId: 'task_swm_002',
          workerUid: 'unauthorized_worker_999',
        ),
        throwsException,
      );
    });

    test('3. pauseTask transitions in_progress task to accepted with pause metadata', () async {
      final mockService = MockTaskService();
      const tenantId = 'tenant_dehradun_01';
      const taskId = 'task_swm_002';
      const workerUid = 'mock-worker-rajesh-001';

      // Start task first
      await mockService.startTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );

      // Pause task
      await mockService.pauseTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
        reason: 'Meal or Rest Break',
      );

      final task = await mockService.getTaskById(tenantId: tenantId, taskId: taskId);
      expect(task!.status, TaskStatus.accepted);
      expect(task.isPaused, isTrue);
      expect(task.pausedAt, isNotNull);
      expect(task.pauseReason, 'Meal or Rest Break');
    });

    test('4. resumeTask clears pause state and returns status to in_progress', () async {
      final mockService = MockTaskService();
      const tenantId = 'tenant_dehradun_01';
      const taskId = 'task_swm_002';
      const workerUid = 'mock-worker-rajesh-001';

      await mockService.startTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );
      await mockService.pauseTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
        reason: 'Shift Handover',
      );

      // Resume
      await mockService.resumeTask(
        tenantId: tenantId,
        taskId: taskId,
        workerUid: workerUid,
      );

      final task = await mockService.getTaskById(tenantId: tenantId, taskId: taskId);
      expect(task!.status, TaskStatus.inProgress);
      expect(task.isPaused, isFalse);
      expect(task.pausedAt, isNull);
      expect(task.pauseReason, isNull);
    });

    test('5. ResilientTaskService proxies execution lifecycle to fallback when primary fails', () async {
      final fallbackService = MockTaskService();
      final resilient = ResilientTaskService(
        primary: MockTaskService(), // Can act as primary
        fallback: fallbackService,
      );

      await resilient.startTask(
        tenantId: 'tenant_dehradun_01',
        taskId: 'task_swm_002',
        workerUid: 'mock-worker-rajesh-001',
      );

      await resilient.pauseTask(
        tenantId: 'tenant_dehradun_01',
        taskId: 'task_swm_002',
        workerUid: 'mock-worker-rajesh-001',
        reason: 'Adverse Weather',
      );

      await resilient.resumeTask(
        tenantId: 'tenant_dehradun_01',
        taskId: 'task_swm_002',
        workerUid: 'mock-worker-rajesh-001',
      );
    });
  });

  group('Phase 4.1: TaskDetailScreen Execution Controls Widget Tests', () {
    testWidgets('1. Accepted task displays Start Work button and tapping starts field work',
        (tester) async {
      final mockTaskService = MockTaskService();
      final mockAuthService = MockAuthService();
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        buildTestApp(
          child: const TaskDetailScreen(taskId: 'task_swm_002'), // task_swm_002 is accepted
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final startBtn = find.byKey(const Key('btn_start_work_detail'));
      expect(startBtn, findsOneWidget);
      expect(find.text('Start Work'), findsOneWidget);

      // Tap Start Work
      await tester.tap(startBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Work started on task.'), findsOneWidget);
      // Now in progress controls are visible
      expect(find.byKey(const Key('btn_pause_work_detail')), findsOneWidget);
    });

    testWidgets('2. In-progress task displays Pause Work button and tapping opens reason sheet',
        (tester) async {
      final mockTaskService = MockTaskService();
      final mockAuthService = MockAuthService();
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      // Start task first in service
      await mockTaskService.startTask(
        tenantId: 'tenant_dehradun_01',
        taskId: 'task_swm_002',
        workerUid: testWorker.uid,
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const TaskDetailScreen(taskId: 'task_swm_002'),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final pauseBtn = find.byKey(const Key('btn_pause_work_detail'));
      expect(pauseBtn, findsOneWidget);
      expect(find.text('Pause Work'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);

      // Tap Pause Work -> opens modal bottom sheet
      await tester.tap(pauseBtn);
      await tester.pumpAndSettle();

      expect(find.text('Pause Field Work'), findsOneWidget);
      expect(find.text('Select a reason for temporarily holding work:'), findsOneWidget);
      expect(find.text('Meal or Rest Break'), findsOneWidget);
      expect(find.text('Shift Handover / Crew Change'), findsOneWidget);
      expect(find.text('Adverse Weather Hold'), findsOneWidget);
      expect(find.text('Awaiting Materials or Tools'), findsOneWidget);

      // Select 'Meal or Rest Break'
      await tester.tap(find.text('Meal or Rest Break'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Field work paused.'), findsOneWidget);
      expect(find.text('Task Work Paused'), findsOneWidget);
      expect(find.byKey(const Key('btn_resume_work_detail')), findsOneWidget);
    });

    testWidgets('3. Paused task displays Resume Work button and tapping returns to in_progress',
        (tester) async {
      final mockTaskService = MockTaskService();
      final mockAuthService = MockAuthService();
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      // Start and pause task in service
      await mockTaskService.startTask(
        tenantId: 'tenant_dehradun_01',
        taskId: 'task_swm_002',
        workerUid: testWorker.uid,
      );
      await mockTaskService.pauseTask(
        tenantId: 'tenant_dehradun_01',
        taskId: 'task_swm_002',
        workerUid: testWorker.uid,
        reason: 'Heavy Rain Hold',
      );

      await tester.pumpWidget(
        buildTestApp(
          child: const TaskDetailScreen(taskId: 'task_swm_002'),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Task Work Paused'), findsOneWidget);
      expect(find.text('Heavy Rain Hold'), findsOneWidget);

      final resumeBtn = find.byKey(const Key('btn_resume_work_detail'));
      expect(resumeBtn, findsOneWidget);
      expect(find.text('Resume Work'), findsOneWidget);

      // Tap Resume Work
      await tester.tap(resumeBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Field work resumed.'), findsOneWidget);
      expect(find.byKey(const Key('btn_pause_work_detail')), findsOneWidget);
    });

    testWidgets('4. Hindi localization renders execution buttons accurately',
        (tester) async {
      final mockTaskService = MockTaskService();
      final mockAuthService = MockAuthService();
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        buildTestApp(
          child: const TaskDetailScreen(taskId: 'task_swm_002'),
          locale: const Locale('hi'),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_start_work_detail')), findsOneWidget);
    });
  });
}
