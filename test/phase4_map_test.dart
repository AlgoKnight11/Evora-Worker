import 'package:evora_workers/domain/models/worker_profile.dart';
import 'package:evora_workers/features/auth/providers/auth_provider.dart';
import 'package:evora_workers/features/auth/services/mock_auth_service.dart';
import 'package:evora_workers/features/map/screens/task_map_screen.dart';
import 'package:evora_workers/features/tasks/providers/task_providers.dart';
import 'package:evora_workers/features/tasks/services/mock_task_service.dart';
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
    List<Override> overrides = const [],
    Locale locale = const Locale('en'),
  }) {
    return ProviderScope(
      overrides: overrides,
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

  group('Phase 4.5: Task Map & Work Area View Tests', () {
    late MockTaskService mockService;
    late MockAuthService mockAuthService;

    setUp(() {
      mockService = MockTaskService();
      mockAuthService = MockAuthService();
    });

    testWidgets('TaskMapScreen renders service area header, metric pills, visual canvas, and selected card',
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
          child: const TaskMapScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Service Area Header & metric pills
      expect(find.textContaining('Approved Service Area: WARD 12, WARD 13, WARD 14'), findsOneWidget);
      expect(find.byKey(const Key('pill_total_pins')), findsOneWidget);
      expect(find.byKey(const Key('pill_critical_pins')), findsOneWidget);
      expect(find.byKey(const Key('pill_overdue_pins')), findsOneWidget);

      // 2. Verify Visual Map Canvas & Compass
      expect(find.byKey(const Key('container_interactive_map')), findsOneWidget);
      expect(find.text('N'), findsOneWidget);

      // 3. Verify Bottom Selected Card and buttons
      expect(find.byKey(const Key('card_selected_task_preview')), findsOneWidget);
      expect(find.byKey(const Key('btn_map_navigate')), findsOneWidget);
      expect(find.byKey(const Key('btn_map_view_details')), findsOneWidget);

      // 4. Tap another pin to select it
      final pin2 = find.byKey(const Key('task_pin_task_swm_002'));
      if (pin2.evaluate().isNotEmpty) {
        await tester.tap(pin2);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('card_selected_task_preview')), findsOneWidget);
      }
    });

    testWidgets('TaskMapScreen switches to Turn-by-Turn Route fallback list and displays sequential stops',
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
          child: const TaskMapScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Turn-by-Turn tab
      final directionsTab = find.byKey(const Key('tab_map_directions'));
      expect(directionsTab, findsOneWidget);
      await tester.tap(directionsTab);
      await tester.pumpAndSettle();

      // Verify route list is visible
      expect(find.byKey(const Key('list_turn_by_turn_route')), findsOneWidget);
      expect(find.byKey(const Key('route_stop_1')), findsOneWidget);
      expect(find.byKey(const Key('btn_route_navigate_1')), findsOneWidget);
      expect(find.byKey(const Key('btn_route_detail_1')), findsOneWidget);
    });

    testWidgets('TaskMapScreen filter popup filters tasks by scope',
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
          child: const TaskMapScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Open filter menu
      final filterBtn = find.byKey(const Key('btn_map_filter_menu'));
      expect(filterBtn, findsOneWidget);
      await tester.tap(filterBtn);
      await tester.pumpAndSettle();

      // Select urgent
      final urgentItem = find.byKey(const Key('filter_scope_urgent'));
      expect(urgentItem, findsOneWidget);
      await tester.tap(urgentItem);
      await tester.pumpAndSettle();

      // Visual map remains rendered with filtered pins
      expect(find.byKey(const Key('container_interactive_map')), findsOneWidget);
    });
  });
}
