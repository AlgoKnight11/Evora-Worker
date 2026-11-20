import 'package:evora_workers/core/constants/app_constants.dart';
import 'package:evora_workers/core/localization/locale_provider.dart';
import 'package:evora_workers/features/auth/providers/auth_provider.dart';
import 'package:evora_workers/features/auth/services/mock_auth_service.dart';
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

  group('Worker Splash Screen Tests', () {
    testWidgets('Renders all brand, badge, mission, and progress elements in English',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefLocaleCode: 'en',
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const EvoraWorkersApp(),
        ),
      );

      // Verify municipal badge and branding on splash
      expect(find.text('MUNICIPAL FIELD OPERATIONS'), findsOneWidget);
      expect(
        find.text('Civic Resolution • Rapid Response • Sustainable Cities'),
        findsOneWidget,
      );
      expect(find.text('Connecting to Municipal Dispatch...'), findsOneWidget);
      expect(find.text('EVORA Field Worker Portal • Uttarakhand'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.engineering_rounded), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('Renders properly localized strings in Hindi',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefLocaleCode: 'hi',
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const EvoraWorkersApp(),
        ),
      );

      expect(find.text('नगर निगम फ़ील्ड संचालन'), findsOneWidget);
      expect(
        find.text('नागरिक समाधान • त्वरित प्रतिक्रिया • संधारणीय शहर'),
        findsOneWidget,
      );
      expect(find.text('नगर निगम डिस्पैच से जुड़ रहा है...'), findsOneWidget);
      expect(find.text('EVORA Field Worker Portal • Uttarakhand'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('Full app boot navigates from Splash to Language Select on first launch',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const EvoraWorkersApp(),
        ),
      );

      // First frame shows splash
      expect(find.text('MUNICIPAL FIELD OPERATIONS'), findsOneWidget);

      // Settle transitions past splash into language selection
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lang_option_en')), findsOneWidget);
      expect(find.byKey(const Key('lang_option_hi')), findsOneWidget);
    });

    testWidgets('Full app boot navigates from Splash to Login when language is set',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefLocaleCode: 'en',
        AppConstants.prefHasSelectedLanguage: true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authRepositoryProvider.overrideWithValue(MockAuthService()),
          ],
          child: const EvoraWorkersApp(),
        ),
      );

      // First frame on splash
      expect(find.text('MUNICIPAL FIELD OPERATIONS'), findsOneWidget);

      // Transition to Login
      await tester.pumpAndSettle();
      expect(find.text('Municipal Field Worker Sign In'), findsOneWidget);
      expect(find.text('Get Verification OTP'), findsOneWidget);
    });

    testWidgets('Full app boot navigates from Splash to Overview when authenticated',
        (WidgetTester tester) async {
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

      // First frame on splash
      expect(find.text('MUNICIPAL FIELD OPERATIONS'), findsOneWidget);

      // Settle transition to Overview
      await tester.pumpAndSettle();
      expect(find.text('My Overview'), findsOneWidget);
    });
  });
}
