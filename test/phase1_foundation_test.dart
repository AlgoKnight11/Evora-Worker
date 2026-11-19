import 'package:evora_workers/core/constants/app_constants.dart';
import 'package:evora_workers/core/localization/locale_provider.dart';
import 'package:evora_workers/core/widgets/evora_state_view.dart';
import 'package:evora_workers/core/widgets/evora_status_badge.dart';
import 'package:evora_workers/domain/enums/worker_enums.dart';
import 'package:evora_workers/domain/models/safety_alert.dart';
import 'package:evora_workers/domain/models/task_evidence.dart';
import 'package:evora_workers/domain/models/worker_profile.dart';
import 'package:evora_workers/domain/models/worker_task.dart';
import 'package:evora_workers/features/auth/providers/auth_provider.dart';
import 'package:evora_workers/features/auth/services/mock_auth_service.dart';
import 'package:evora_workers/l10n/generated/app_localizations.dart';
import 'package:evora_workers/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 1.1: Domain Enums & Contracts', () {
    test('TaskStatus canonical values and queue membership are accurate', () {
      for (final status in TaskStatus.values) {
        expect(TaskStatus.fromValue(status.value), status);
      }
      expect(TaskStatus.assigned.isActiveQueue, isTrue);
      expect(TaskStatus.inProgress.isActiveQueue, isTrue);
      expect(TaskStatus.submittedForReview.isActiveQueue, isTrue);
      expect(TaskStatus.approved.isActiveQueue, isFalse);
      expect(TaskStatus.approved.isHistoryQueue, isTrue);
      expect(TaskStatus.cancelled.isHistoryQueue, isTrue);
      expect(TaskStatus.reassigned.isHistoryQueue, isTrue);
    });

    test('SourceType distinguishes CivicFlow cases from standalone work orders', () {
      expect(SourceType.civicFlowCase.isStandalone, isFalse);
      expect(SourceType.municipalWorkOrder.isStandalone, isTrue);
      expect(SourceType.preventiveMaintenance.isStandalone, isTrue);
      expect(SourceType.campaign.isStandalone, isTrue);
    });

    test('DeclineReason and BlockReason preserve critical safety options', () {
      expect(DeclineReason.safetyConcern.isSafetyCritical, isTrue);
      expect(DeclineReason.outOfArea.isSafetyCritical, isFalse);
      expect(BlockReason.unsafeSite.isSafetyCritical, isTrue);
      expect(BlockReason.weatherCondition.isSafetyCritical, isFalse);
      expect(DeclineReason.values.length, 6);
      expect(BlockReason.values.length, 7);
    });

    test('ChecklistResponse enforces WRK-EV-04 (complete or N/A with reason)', () {
      const incomplete = ChecklistResponse(
        itemId: 'chk_1',
        label: 'Clear drain grate',
        isRequired: true,
        isCompleted: false,
      );
      expect(incomplete.isSatisfied, isFalse);

      const naWithoutReason = ChecklistResponse(
        itemId: 'chk_1',
        label: 'Clear drain grate',
        isRequired: true,
        isNotApplicable: true,
        notApplicableReason: '   ',
      );
      expect(naWithoutReason.isSatisfied, isFalse);

      const naWithReason = ChecklistResponse(
        itemId: 'chk_1',
        label: 'Clear drain grate',
        isRequired: true,
        isNotApplicable: true,
        notApplicableReason: 'No storm drain present at site',
      );
      expect(naWithReason.isSatisfied, isTrue);
    });

    test('WorkerTask supports team-pool and standalone work orders round-trip', () {
      final now = DateTime.utc(2026, 11, 18, 10, 0);
      final poolTask = WorkerTask(
        id: 'task_001',
        tenantId: 'tenant_dehradun',
        sourceType: SourceType.municipalWorkOrder,
        civicFlowCaseId: null,
        workOrderId: 'wo_55',
        workerUid: null,
        teamId: 'team_north',
        departmentId: 'solid_waste',
        wardId: 'ward_12',
        categoryId: 'bin_repair',
        status: TaskStatus.assigned,
        priority: TaskPriority.p2,
        title: 'Repair broken community bin',
        instructions: 'Replace hinges and disinfect perimeter.',
        safetyPrecautions: const ['Wear reflective vest', 'Use heavy gloves'],
        requiredEvidence: const ['before_photo', 'after_photo', 'checklist'],
        location: const TaskLocation(
          latitude: 30.3165,
          longitude: 78.0322,
          addressSummary: 'Rajpur Road Sector 4',
          landmark: 'Near Clock Tower',
          wardId: 'ward_12',
        ),
        assignedByUid: 'sup_01',
        assignedAt: now,
        dueAt: now.add(const Duration(hours: 6)),
        updatedAt: now,
        version: 2,
      );

      expect(poolTask.isUnclaimedTeamPool, isTrue);
      expect(poolTask.isCivicFlowLinked, isFalse);

      final roundTrip = WorkerTask.fromJson(poolTask.toJson());
      expect(roundTrip.id, poolTask.id);
      expect(roundTrip.civicFlowCaseId, isNull);
      expect(roundTrip.sourceType, SourceType.municipalWorkOrder);
      expect(roundTrip.teamId, 'team_north');
      expect(roundTrip.version, 2);
      expect(roundTrip.location.landmark, 'Near Clock Tower');
    });

    test('WorkerProfile, TaskEvidence, Measurement, Ack, and SafetyAlert serialize cleanly', () {
      final now = DateTime.utc(2026, 11, 18, 12, 0);

      const profile = WorkerProfile(
        uid: 'w_101',
        tenantId: 'tenant_001',
        employeeCode: 'EMP-409',
        displayName: 'Ramesh Rawat',
        phoneNumber: '+919876543210',
        departmentId: 'solid_waste',
        teamId: 'team_a',
        authorizedServiceAreaIds: ['ward_1', 'ward_2'],
      );
      expect(WorkerProfile.fromJson(profile.toJson()).employeeCode, 'EMP-409');

      final evidence = TaskEvidence(
        id: 'ev_1',
        taskId: 'task_1',
        tenantId: 'tenant_001',
        kind: EvidenceKind.afterPhoto,
        status: EvidenceStatus.pendingUpload,
        mimeType: 'image/jpeg',
        sizeBytes: 240000,
        capturedByUid: 'w_101',
        capturedAt: now,
      );
      expect(TaskEvidence.fromJson(evidence.toJson()).kind, EvidenceKind.afterPhoto);

      final measurement = MeasurementRecord(
        id: 'm_1',
        fieldKey: 'waste_weight_kg',
        label: 'Waste Cleared',
        value: 45.5,
        unit: 'kg',
        recordedAt: now,
        recordedByUid: 'w_101',
      );
      expect(MeasurementRecord.fromJson(measurement.toJson()).value, 45.5);

      final ack = AcknowledgementRecord(
        id: 'ack_1',
        taskId: 'task_1',
        status: AcknowledgementStatus.citizenUnavailable,
        serverConfirmed: false,
        note: 'Gate locked during visit',
        updatedAt: now,
      );
      expect(
        AcknowledgementRecord.fromJson(ack.toJson()).status,
        AcknowledgementStatus.citizenUnavailable,
      );

      final alert = SafetyAlert(
        id: 'sa_1',
        tenantId: 'tenant_001',
        taskId: 'task_1',
        reportedByUid: 'w_101',
        hazardType: 'LIVE_WIRE',
        description: 'Exposed overhead cable near waterlogging',
        reportedAt: now,
        idempotencyKey: 'op_uuid_1',
      );
      expect(SafetyAlert.fromJson(alert.toJson()).hazardType, 'LIVE_WIRE');
    });
  });

  group('Phase 1.2: First-Launch Language Onboarding & Runtime Switcher', () {
    testWidgets('First install prompts language selection and proceeds in Hindi',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const EvoraWorkersApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Language picker is displayed on first launch
      expect(find.byKey(const Key('lang_option_en')), findsOneWidget);
      expect(find.byKey(const Key('lang_option_hi')), findsOneWidget);

      // Select Hindi and continue
      await tester.tap(find.byKey(const Key('lang_option_hi')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lang_continue_button')));
      await tester.pumpAndSettle();

      // Persisted in SharedPreferences
      expect(prefs.getString(AppConstants.prefLocaleCode), 'hi');
      expect(prefs.getBool(AppConstants.prefHasSelectedLanguage), isTrue);

      // With Phase 2 auth guards, navigates to Login in Hindi
      expect(find.text('नगर निगम फ़ील्ड कार्यकर्ता साइन इन'), findsOneWidget);
      expect(find.text('सत्यापन ओटीपी प्राप्त करें'), findsOneWidget);
    });

    testWidgets(
        'Returning user skips onboarding, navigates all 6 views, and switches language in Profile',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefLocaleCode: 'en',
        AppConstants.prefHasSelectedLanguage: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final testWorker = MockAuthService.mockDirectory['+919999999999']!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authNotifierProvider.overrideWith((ref) {
              final notifier = AuthNotifier(ref.watch(authRepositoryProvider));
              notifier.setAuthenticatedWorker(testWorker);
              return notifier;
            }),
          ],
          child: const EvoraWorkersApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Starts directly on My Overview in English
      expect(find.text('My Overview'), findsOneWidget);

      // Navigate to My Tasks
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      expect(find.text('My Tasks'), findsOneWidget);

      // Navigate to Task Map
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(find.text('Task Map'), findsOneWidget);

      // Navigate to Notifications (via AppBar bell on narrow or Rail on wide)
      final notifBell = find.byKey(const Key('nav_notifications_button'));
      if (notifBell.evaluate().isNotEmpty) {
        await tester.tap(notifBell);
      } else {
        await tester.tap(find.text('Alerts'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);

      // Navigate to Task History
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('Task History'), findsOneWidget);

      // Navigate to Profile & Help
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile & Help'), findsOneWidget);

      // Switch language at runtime to Hindi without losing Profile route
      await tester.tap(find.byKey(const Key('profile_lang_hi')));
      await tester.pumpAndSettle();

      expect(find.text('प्रोफ़ाइल और सहायता'), findsOneWidget);
      expect(prefs.getString(AppConstants.prefLocaleCode), 'hi');
    });

    testWidgets('Status badges and state views render cleanly', (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefLocaleCode: 'en',
        AppConstants.prefHasSelectedLanguage: true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(
              body: Column(
                children: [
                  TaskStatusBadge(status: TaskStatus.blocked),
                  TaskPriorityBadge(priority: TaskPriority.p1),
                  Expanded(
                    child: EvoraStateView(
                      kind: EvoraScreenStateKind.offline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Blocked'), findsOneWidget);
      expect(find.text('P1 Critical'), findsOneWidget);
      expect(find.text('Working offline'), findsOneWidget);
    });
  });
}
