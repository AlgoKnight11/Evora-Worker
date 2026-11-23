import 'package:evora_workers/core/theme/evora_colors.dart';
import 'package:evora_workers/domain/enums/worker_enums.dart';
import 'package:evora_workers/features/auth/providers/auth_provider.dart';
import 'package:evora_workers/features/auth/services/mock_auth_service.dart';
import 'package:evora_workers/features/tasks/providers/task_providers.dart';
import 'package:evora_workers/features/tasks/screens/tasks_screen.dart';
import 'package:evora_workers/features/tasks/services/mock_task_service.dart';
import 'package:evora_workers/features/tasks/widgets/decline_task_dialog.dart';
import 'package:evora_workers/features/tasks/widgets/task_card_item.dart';
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

  group('Phase 3.3: My Tasks Inbox & Filters Screen Tests', () {
    late MockTaskService mockTaskService;
    late MockAuthService mockAuthService;
    final testWorker = MockAuthService.mockDirectory['+919999999999']!;

    setUp(() {
      mockTaskService = MockTaskService();
      mockAuthService = MockAuthService();
    });

    testWidgets('1. Renders search bar, filter button, status tabs, and scope chips',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TasksScreen(),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tasks_search_field')), findsOneWidget);
      expect(find.byKey(const Key('btn_open_filter_sheet')), findsOneWidget);
      expect(find.byKey(const Key('tab_status_all')), findsOneWidget);
      expect(find.byKey(const Key('tab_status_assigned')), findsOneWidget);
      expect(find.byKey(const Key('tab_status_accepted')), findsOneWidget);
      expect(find.byKey(const Key('tab_status_in_progress')), findsOneWidget);
      expect(find.byKey(const Key('tab_status_blocked')), findsOneWidget);
      expect(find.byKey(const Key('chip_scope_all')), findsOneWidget);
      expect(find.byKey(const Key('chip_scope_individual')), findsOneWidget);
      expect(find.byKey(const Key('chip_scope_team_pool')), findsOneWidget);
    });

    testWidgets('2. Renders task cards with priority, SLA, and category details',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TasksScreen(),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TaskCardItem), findsWidgets);
      expect(find.textContaining('P1 Critical'), findsWidgets);
      expect(find.textContaining('Overflowing Community Garbage Bin'), findsOneWidget);
    });

    testWidgets('3. Tapping status tab filters list to only that operational status',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(mockTaskService),
          authNotifierProvider.overrideWith((ref) => authNotifier),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const TasksScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Assigned status tab
      await tester.tap(find.byKey(const Key('tab_status_assigned')));
      await tester.pumpAndSettle();

      final currentFilter = container.read(taskFilterProvider);
      expect(currentFilter.statusTab, TaskStatus.assigned);
    });

    testWidgets('4. Searching query dynamically filters tasks by title or landmark',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TasksScreen(),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Type "Mall Road" in search field
      await tester.enterText(find.byKey(const Key('tasks_search_field')), 'Mall Road');
      await tester.pumpAndSettle();

      expect(find.textContaining('Mall Road'), findsWidgets);

      // Type non-existent query
      await tester.enterText(
          find.byKey(const Key('tasks_search_field')), 'NonExistentPlaceXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No matching tasks found'), findsOneWidget);
      expect(find.byKey(const Key('btn_clear_all_filters')), findsOneWidget);
    });

    testWidgets('5. Claiming a team-pool task updates state and shows SnackBar',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TasksScreen(),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Team Pool filter chip
      await tester.tap(find.byKey(const Key('chip_scope_team_pool')));
      await tester.pumpAndSettle();

      // Find first Claim Task button
      final claimBtn = find.text('Claim Task');
      expect(claimBtn, findsWidgets);

      await tester.tap(claimBtn.first);
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify SnackBar confirmation
      expect(find.text('Task successfully claimed into your queue'), findsOneWidget);
    });

    testWidgets('6. Accepting an assigned task moves it to accepted state',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TasksScreen(),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap Assigned status tab
      await tester.tap(find.byKey(const Key('tab_status_assigned')));
      await tester.pumpAndSettle();

      final acceptBtn = find.text('Accept');
      expect(acceptBtn, findsWidgets);

      await tester.ensureVisible(acceptBtn.first);
      await tester.pumpAndSettle();
      await tester.tap(acceptBtn.first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Task accepted and ready for field execution'), findsOneWidget);
    });

    testWidgets('7. Declining an assigned task opens DeclineTaskDialog with municipal reasons',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const TasksScreen(),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap Assigned status tab
      await tester.tap(find.byKey(const Key('tab_status_assigned')));
      await tester.pumpAndSettle();

      final declineBtn = find.text('Decline');
      expect(declineBtn, findsWidgets);

      await tester.ensureVisible(declineBtn.first);
      await tester.pumpAndSettle();
      await tester.tap(declineBtn.first);
      await tester.pumpAndSettle();

      // Verify Decline Modal opens
      expect(find.byType(DeclineTaskDialog), findsOneWidget);
      expect(find.text('Decline Assignment'), findsOneWidget);
      expect(find.text('Active safety hazard at site'), findsOneWidget);

      // Select safety concern reason
      await tester.tap(find.byKey(const Key('decline_reason_SAFETY_CONCERN')));
      await tester.pumpAndSettle();

      // Confirm decline
      await tester.tap(find.byKey(const Key('btn_confirm_decline_submit')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Task declined and returned to dispatch'), findsOneWidget);
    });
  });
}
