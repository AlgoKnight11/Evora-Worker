import 'package:evora_workers/domain/enums/worker_enums.dart';
import 'package:evora_workers/domain/models/worker_profile.dart';
import 'package:evora_workers/features/auth/providers/auth_provider.dart';
import 'package:evora_workers/features/auth/services/mock_auth_service.dart';
import 'package:evora_workers/features/tasks/providers/task_providers.dart';
import 'package:evora_workers/features/tasks/screens/task_detail_screen.dart';
import 'package:evora_workers/features/tasks/services/mock_task_service.dart';
import 'package:evora_workers/features/tasks/widgets/block_task_dialog.dart';
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
    tenantId: 'tenant-shimla-01',
    employeeCode: 'EVR-SWM-4091',
    displayName: 'Rajesh Kumar',
    phoneNumber: '+919999999999',
    departmentId: 'dept-swm',
    departmentName: 'Solid Waste Management',
    teamId: 'crew-alpha-12',
    teamName: 'Mall Road Rapid Response Crew',
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

  group('Phase 4.2: Operational Blocker Dialog & Engine Tests', () {
    late MockTaskService mockService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockService = MockTaskService();
      mockAuthService = MockAuthService();
    });

    test('1. MockTaskService: blockTask transitions inProgress task to blocked',
        () async {
      // task_swm_004 is initially inProgress
      final initialTask = await mockService.getTaskById(
        tenantId: 'tenant-shimla-01',
        taskId: 'task_swm_004',
      );
      expect(initialTask?.status, TaskStatus.inProgress);
      expect(initialTask?.isBlocked, false);
      final initialVersion = initialTask?.version ?? 1;

      await mockService.blockTask(
        tenantId: 'tenant-shimla-01',
        taskId: 'task_swm_004',
        workerUid: 'mock-worker-rajesh-001',
        reason: BlockReason.accessRestricted,
        note: 'Main iron gate padlocked with no security guard on duty',
      );

      final updatedTask = await mockService.getTaskById(
        tenantId: 'tenant-shimla-01',
        taskId: 'task_swm_004',
      );

      expect(updatedTask?.status, TaskStatus.blocked);
      expect(updatedTask?.isBlocked, true);
      expect(updatedTask?.blockReason, BlockReason.accessRestricted);
      expect(updatedTask?.blockNote,
          'Main iron gate padlocked with no security guard on duty');
      expect(updatedTask?.blockedAt, isNotNull);
      expect(updatedTask?.version, initialVersion + 1);
    });

    test('2. MockTaskService: unblockTask restores blocked task to inProgress',
        () async {
      // First block the task
      await mockService.blockTask(
        tenantId: 'tenant-shimla-01',
        taskId: 'task_swm_004',
        workerUid: 'mock-worker-rajesh-001',
        reason: BlockReason.equipmentFailure,
        note: 'Hydraulic winch motor overheated',
      );

      final blockedTask = await mockService.getTaskById(
        tenantId: 'tenant-shimla-01',
        taskId: 'task_swm_004',
      );
      expect(blockedTask?.status, TaskStatus.blocked);
      expect(blockedTask?.blockReason, BlockReason.equipmentFailure);
      final blockedVersion = blockedTask?.version ?? 1;

      // Now unblock
      await mockService.unblockTask(
        tenantId: 'tenant-shimla-01',
        taskId: 'task_swm_004',
        workerUid: 'mock-worker-rajesh-001',
      );

      final unblockedTask = await mockService.getTaskById(
        tenantId: 'tenant-shimla-01',
        taskId: 'task_swm_004',
      );

      expect(unblockedTask?.status, TaskStatus.inProgress);
      expect(unblockedTask?.isBlocked, false);
      expect(unblockedTask?.blockReason, isNull);
      expect(unblockedTask?.blockNote, isNull);
      expect(unblockedTask?.blockedAt, isNull);
      expect(unblockedTask?.version, blockedVersion + 1);
    });

    testWidgets(
        '3. BlockTaskDialog displays 7 reasons, safety banner for unsafeSite, and enforces note on other',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ({BlockReason reason, String? note})? result;

      await tester.pumpWidget(
        buildTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('open_dialog'),
                onPressed: () async {
                  result = await BlockTaskDialog.show(
                    context,
                    taskId: 'task_swm_004',
                    taskTitle: 'Clogged Storm Drain Grate',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_dialog')));
      await tester.pumpAndSettle();

      // Check dialog headers
      expect(find.byType(BlockTaskDialog), findsOneWidget);
      expect(find.text('Report Operational Blocker'), findsOneWidget);

      // Check all 7 reasons
      for (final reason in BlockReason.values) {
        expect(find.byKey(Key('block_reason_${reason.value}')),
            findsOneWidget);
      }

      // Check safety alert warning does not show initially (default is accessRestricted)
      expect(find.byKey(const Key('alert_unsafe_site_warning')), findsNothing);

      // Tap unsafeSite reason
      await tester.tap(find.byKey(
          Key('block_reason_${BlockReason.unsafeSite.value}')));
      await tester.pumpAndSettle();

      // Safety warning banner should now be visible
      expect(find.byKey(const Key('alert_unsafe_site_warning')), findsOneWidget);

      // Tap "Other" reason
      await tester.ensureVisible(
          find.byKey(Key('block_reason_${BlockReason.other.value}')));
      await tester.pumpAndSettle();
      await tester.tap(
          find.byKey(Key('block_reason_${BlockReason.other.value}')));
      await tester.pumpAndSettle();

      // Try confirming without entering a note (validation should fail)
      await tester.ensureVisible(find.byKey(const Key('btn_confirm_block_task')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_confirm_block_task')));
      await tester.pumpAndSettle();

      expect(
          find.text('An explanation is required when selecting "Other".'),
          findsOneWidget);
      expect(result, isNull);

      // Now enter an explanation note
      await tester.ensureVisible(find.byKey(const Key('input_block_note')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('input_block_note')), 'Blocked due to local religious procession');
      await tester.pumpAndSettle();

      // Confirm
      await tester.ensureVisible(find.byKey(const Key('btn_confirm_block_task')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_confirm_block_task')));
      await tester.pumpAndSettle();

      // Dialog should close and return result
      expect(result, isNotNull);
      expect(result?.reason, BlockReason.other);
      expect(result?.note, 'Blocked due to local religious procession');
    });

    testWidgets(
        '4. TaskDetailScreen: inProgress displays Report Blocker button, opens dialog, and updates to blocked banner',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        buildTestApp(
          child: const TaskDetailScreen(taskId: 'task_swm_004'),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Verify "Report Blocker" button is present on inProgress task
      final blockerBtn = find.byKey(const Key('btn_block_task_detail'));
      expect(blockerBtn, findsOneWidget);

      // Tap "Report Blocker"
      await tester.tap(blockerBtn);
      await tester.pumpAndSettle();

      // Verify modal sheet opened
      expect(find.byType(BlockTaskDialog), findsOneWidget);

      // Select equipment failure
      await tester.ensureVisible(find.byKey(
          Key('block_reason_${BlockReason.equipmentFailure.value}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(
          Key('block_reason_${BlockReason.equipmentFailure.value}')));
      await tester.pumpAndSettle();

      // Confirm blocker
      await tester.ensureVisible(find.byKey(const Key('btn_confirm_block_task')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_confirm_block_task')));
      await tester.pumpAndSettle();

      // Verify banner appears
      expect(find.byKey(const Key('banner_task_blocked')), findsOneWidget);
      expect(find.text('Task Blocked'), findsOneWidget);

      // Verify "Unblock & Resume Work" button is now visible
      expect(find.byKey(const Key('btn_unblock_task_detail')), findsOneWidget);

      // Dismiss the SnackBar so it doesn't block the button tap
      ScaffoldMessenger.of(tester.element(find.byType(TaskDetailScreen)))
          .hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Tap Unblock
      await tester.tap(find.byKey(const Key('btn_unblock_task_detail')));
      await tester.pumpAndSettle();

      // Verify banner is gone and "Report Blocker" button returns
      expect(find.byKey(const Key('banner_task_blocked')), findsNothing);
      expect(find.byKey(const Key('btn_block_task_detail')), findsOneWidget);
    });
  });
}
