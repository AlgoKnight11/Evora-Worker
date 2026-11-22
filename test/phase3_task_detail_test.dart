import 'package:evora_workers/core/theme/evora_colors.dart';
import 'package:evora_workers/domain/enums/worker_enums.dart';
import 'package:evora_workers/features/auth/providers/auth_provider.dart';
import 'package:evora_workers/features/auth/services/mock_auth_service.dart';
import 'package:evora_workers/features/tasks/providers/task_providers.dart';
import 'package:evora_workers/features/tasks/screens/task_detail_screen.dart';
import 'package:evora_workers/features/tasks/services/mock_task_service.dart';
import 'package:evora_workers/features/tasks/widgets/decline_task_dialog.dart';
import 'package:evora_workers/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _buildTestApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
      locale: const Locale('en'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: EvoraColors.primary),
        useMaterial3: true,
      ),
      home: child,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 3.4: Comprehensive Task Detail Screen Tests', () {
    late MockTaskService mockTaskService;
    late MockAuthService mockAuthService;
    final testWorker = MockAuthService.mockDirectory['+919999999999']!;

    setUp(() {
      mockTaskService = MockTaskService();
      mockAuthService = MockAuthService();
    });

    testWidgets('1. Renders task detail header, ID, title, and priority pill',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TaskDetailScreen(taskId: 'task_swm_001'),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Title
      expect(find.text('Task Details'), findsOneWidget);
      expect(find.text('task_swm_001'), findsOneWidget);
      expect(find.text('Overflowing Community Garbage Bin near Mall Road'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('CivicFlow #case_cf_7101'), findsOneWidget);
      expect(find.text('Sanitation & Waste'), findsOneWidget);
    });

    testWidgets('2. Renders location card with landmark, ward, and coordinates',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TaskDetailScreen(taskId: 'task_swm_001'),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Location & Coordinates'), findsOneWidget);
      expect(find.text('Mall Road, near Lower Bazaar Steps'), findsOneWidget);
      expect(find.text('Landmark: Opposite State Bank Building'), findsOneWidget);
      expect(find.text('Ward 12 - Mall Road Central'), findsOneWidget);
      expect(find.byKey(const Key('btn_open_in_maps')), findsOneWidget);

      // Tap Open in Maps
      await tester.tap(find.byKey(const Key('btn_open_in_maps')));
      await tester.pump();

      expect(find.textContaining('Opening coordinates'), findsOneWidget);
    });

    testWidgets('3. Renders work instructions, safety precautions, and required evidence',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TaskDetailScreen(taskId: 'task_swm_001'),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Work Order Instructions'), findsOneWidget);
      expect(find.textContaining('Clear overflowed solid waste'), findsOneWidget);

      // Safety Precautions
      expect(find.text('Safety Precautions'), findsOneWidget);
      expect(find.textContaining('Wear high-visibility reflective safety vest'), findsOneWidget);

      // Required Evidence
      expect(find.text('Required Completion Evidence'), findsOneWidget);
      expect(find.text('before_photo'), findsOneWidget);
      expect(find.text('after_photo'), findsOneWidget);
    });

    testWidgets('4. Contextual actions for Assigned task: Accept updates task state',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TaskDetailScreen(taskId: 'task_swm_001'),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final acceptBtn = find.byKey(const Key('btn_accept_task_detail'));
      final declineBtn = find.byKey(const Key('btn_decline_task_detail'));

      expect(acceptBtn, findsOneWidget);
      expect(declineBtn, findsOneWidget);

      await tester.tap(acceptBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Task accepted and ready for field execution'), findsOneWidget);
    });

    testWidgets('5. Contextual actions for Assigned task: Decline opens municipal dialog',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TaskDetailScreen(taskId: 'task_swm_001'),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final declineBtn = find.byKey(const Key('btn_decline_task_detail'));
      await tester.tap(declineBtn);
      await tester.pumpAndSettle();

      expect(find.byType(DeclineTaskDialog), findsOneWidget);
      expect(find.text('Decline Assignment'), findsOneWidget);
      expect(find.text('Active safety hazard at site'), findsOneWidget);

      // Select safety reason
      await tester.tap(find.byKey(const Key('decline_reason_SAFETY_CONCERN')));
      await tester.pumpAndSettle();

      // Submit decline
      await tester.tap(find.byKey(const Key('btn_confirm_decline_submit')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Task declined and returned to dispatch'), findsOneWidget);
    });

    testWidgets('6. Contextual actions for Team-Pool task: Claim task succeeds',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TaskDetailScreen(taskId: 'task_swm_003'),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final claimBtn = find.byKey(const Key('btn_claim_task_detail'));
      final dismissBtn = find.byKey(const Key('btn_dismiss_task_detail'));

      expect(claimBtn, findsOneWidget);
      expect(dismissBtn, findsOneWidget);

      await tester.tap(claimBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Task successfully claimed into your queue'), findsOneWidget);
    });

    testWidgets('7. Accepted task renders Start Field Work button',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TaskDetailScreen(taskId: 'task_swm_002'),
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

      await tester.tap(startBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Work started on task'), findsOneWidget);
    });

    testWidgets('8. Non-existent task renders Not Found state with Back button',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TaskDetailScreen(taskId: 'non_existent_999'),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Task Not Found'), findsOneWidget);
      expect(find.text('The requested municipal task could not be located or may have been reassigned.'), findsOneWidget);
      expect(find.text('Back to Tasks'), findsOneWidget);
    });
  });
}
