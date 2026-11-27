import 'package:evora_workers/domain/models/worker_profile.dart';
import 'package:evora_workers/features/auth/providers/auth_provider.dart';
import 'package:evora_workers/features/auth/services/mock_auth_service.dart';
import 'package:evora_workers/features/tasks/providers/task_providers.dart';
import 'package:evora_workers/features/tasks/screens/task_detail_screen.dart';
import 'package:evora_workers/features/tasks/services/mock_task_service.dart';
import 'package:evora_workers/features/tasks/widgets/safety_incident_dialog.dart';
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
    teamName: 'Doon Valley Sanitation Crew',
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

  group('Phase 4.4: High-Priority Safety Incident Subsystem Tests', () {
    late MockTaskService mockService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockService = MockTaskService();
      mockAuthService = MockAuthService();
    });

    test('MockTaskService.reportSafetyIncident creates an escalated out-of-band record and emits to stream', () async {
      final alert = await mockService.reportSafetyIncident(
        tenantId: testWorker.tenantId,
        reportedByUid: testWorker.uid,
        hazardType: 'gas_chemical_leak',
        description: 'Methane gas buildup detected inside storm drain',
        taskId: 'task_swm_004',
        latitude: 31.1048,
        longitude: 77.1734,
      );

      expect(alert.id, startsWith('alert_safe_'));
      expect(alert.hazardType, equals('gas_chemical_leak'));
      expect(alert.description, equals('Methane gas buildup detected inside storm drain'));
      expect(alert.escalated, isTrue);
      expect(alert.taskId, equals('task_swm_004'));
      expect(alert.latitude, equals(31.1048));
      expect(alert.longitude, equals(77.1734));

      final alerts = await mockService
          .watchSafetyAlerts(tenantId: testWorker.tenantId, workerUid: testWorker.uid)
          .first;
      expect(alerts.length, equals(1));
      expect(alerts.first.id, equals(alert.id));
    });

    testWidgets('SafetyIncidentDialog renders emergency speed dial panel, validates input, and returns data',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ({String hazardType, String riskLevel, String description})? result;

      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await SafetyIncidentDialog.show(
                  context,
                  taskId: 'task_swm_004',
                  taskTitle: 'Clear Landslide Debris',
                  latitude: 31.1048,
                  longitude: 77.1734,
                );
              },
              child: const Text('Open Safety Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Safety Dialog'));
      await tester.pumpAndSettle();

      // 1. Verify sheet and instant emergency speed dial panel
      expect(find.byKey(const Key('sheet_safety_incident')), findsOneWidget);
      expect(find.byKey(const Key('panel_emergency_speed_dial')), findsOneWidget);
      expect(find.byKey(const Key('btn_dial_112')), findsOneWidget);
      expect(find.byKey(const Key('btn_dial_108')), findsOneWidget);
      expect(find.byKey(const Key('btn_dial_101')), findsOneWidget);
      expect(find.byKey(const Key('btn_dial_control_room')), findsOneWidget);

      // 2. Select High risk level
      final highRisk = find.byKey(const Key('risk_high'));
      expect(highRisk, findsOneWidget);
      await tester.tap(highRisk);
      await tester.pumpAndSettle();

      // 3. Select Gas / Chemical hazard
      final gasOption = find.byKey(const Key('hazard_type_gas_chemical_leak'));
      expect(gasOption, findsOneWidget);
      await tester.tap(gasOption);
      await tester.pumpAndSettle();

      // 4. Try submitting with empty notes -> validation error
      final submitBtn = find.byKey(const Key('btn_submit_safety'));
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(find.text('Please describe the safety hazard for dispatch.'), findsOneWidget);

      // 5. Enter notes and submit
      final notesField = find.byKey(const Key('input_safety_description'));
      expect(notesField, findsOneWidget);
      await tester.enterText(notesField, 'Active chemical leak spreading on road surface');
      await tester.pumpAndSettle();

      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.hazardType, equals('gas_chemical_leak'));
      expect(result!.riskLevel, equals('high'));
      expect(result!.description, equals('Active chemical leak spreading on road surface'));
    });

    testWidgets('TaskDetailScreen AppBar safety button opens dialog, creates alert, and renders banner',
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

      // 1. Verify safety button in AppBar
      final safetyBtn = find.byKey(const Key('btn_report_safety_detail'));
      expect(safetyBtn, findsOneWidget);

      // 2. Tap to open safety dialog
      await tester.tap(safetyBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sheet_safety_incident')), findsOneWidget);

      // 3. Enter notes
      final notesField = find.byKey(const Key('input_safety_description'));
      await tester.enterText(notesField, 'Live overhead wire snapped and fell across road');
      await tester.pumpAndSettle();

      // 4. Submit
      final submitBtn = find.byKey(const Key('btn_submit_safety'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // 5. Verify safety banner is displayed
      expect(find.byKey(const Key('banner_task_safety')), findsOneWidget);
      expect(find.textContaining('ELECTRICAL HAZARD'), findsOneWidget);
    });
  });
}
