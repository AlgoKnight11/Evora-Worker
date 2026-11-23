import 'package:evora_workers/core/theme/evora_colors.dart';
import 'package:evora_workers/domain/enums/worker_enums.dart';
import 'package:evora_workers/features/auth/providers/auth_provider.dart';
import 'package:evora_workers/features/auth/services/mock_auth_service.dart';
import 'package:evora_workers/features/overview/screens/overview_screen.dart';
import 'package:evora_workers/features/tasks/providers/task_providers.dart';
import 'package:evora_workers/features/tasks/services/mock_task_service.dart';
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

  group('Phase 3.2: Overview Dashboard Tests', () {
    late MockTaskService mockTaskService;
    late MockAuthService mockAuthService;
    final testWorker = MockAuthService.mockDirectory['+919999999999']!;

    setUp(() {
      mockTaskService = MockTaskService();
      mockAuthService = MockAuthService();
    });

    testWidgets('1. Worker shift banner displays name, code, dept, and crew',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const OverviewScreen(),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rajesh Kumar'), findsOneWidget);
      expect(find.textContaining('EVR-SWM-4091'), findsOneWidget);
      expect(find.textContaining('Solid Waste Management'), findsOneWidget);
      expect(find.textContaining('Mall Road Rapid Response Crew'), findsOneWidget);
    });

    testWidgets('2. Renders 4 operational metrics KPI cards with live counts',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const OverviewScreen(),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('kpi_today_tasks')), findsOneWidget);
      expect(find.byKey(const Key('kpi_assigned_tasks')), findsOneWidget);
      expect(find.byKey(const Key('kpi_in_progress_tasks')), findsOneWidget);
      expect(find.byKey(const Key('kpi_blocked_tasks')), findsOneWidget);
    });

    testWidgets('3. Renders urgent dispatch section with P1 Critical tasks',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const OverviewScreen(),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Urgent Dispatch Queue'), findsOneWidget);

      final claimOrAccept = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton ||
            (widget is Text &&
                (widget.data == 'Claim Task' ||
                    widget.data == 'Accept' ||
                    widget.data == 'View Detail')),
      );
      expect(claimOrAccept, findsWidgets);
    });

    testWidgets('4. Renders Municipal Control Room helpline (112)',
        (tester) async {
      final authNotifier = AuthNotifier(mockAuthService);
      authNotifier.setAuthenticatedWorker(testWorker);

      await tester.pumpWidget(
        _buildTestApp(
          child: const OverviewScreen(),
          overrides: [
            taskRepositoryProvider.overrideWithValue(mockTaskService),
            authNotifierProvider.overrideWith((ref) => authNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining('112'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('112'), findsOneWidget);
      expect(find.textContaining('Municipal Control Room'), findsOneWidget);
    });

    testWidgets('5. Tapping KPI card updates taskFilterProvider state',
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
            home: const OverviewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Assigned KPI card
      await tester.tap(find.byKey(const Key('kpi_assigned_tasks')));
      await tester.pumpAndSettle();

      final currentFilter = container.read(taskFilterProvider);
      expect(currentFilter.statusTab, TaskStatus.assigned);
    });
  });
}
