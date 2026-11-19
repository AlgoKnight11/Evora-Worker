import 'package:evora_workers/core/constants/app_constants.dart';
import 'package:evora_workers/core/localization/locale_provider.dart';
import 'package:evora_workers/features/auth/models/auth_state.dart';
import 'package:evora_workers/features/auth/providers/auth_provider.dart';
import 'package:evora_workers/features/auth/screens/login_screen.dart';
import 'package:evora_workers/features/auth/screens/otp_verification_screen.dart';
import 'package:evora_workers/features/auth/services/firebase_auth_service.dart';
import 'package:evora_workers/features/auth/services/mock_auth_service.dart';
import 'package:evora_workers/features/auth/widgets/unregistered_worker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 2.1: Phone Normalization & Zero Self-Registration Logic', () {
    test('Phone number normalizer formats Indian 10-digit numbers to E.164', () {
      expect(FirebaseAuthService.normalizePhoneNumber('9999999999'), '+919999999999');
      expect(FirebaseAuthService.normalizePhoneNumber('9876543210'), '+919876543210');
      expect(FirebaseAuthService.normalizePhoneNumber('+919876543210'), '+919876543210');
      expect(FirebaseAuthService.normalizePhoneNumber('919876543210'), '+919876543210');
      expect(FirebaseAuthService.normalizePhoneNumber('+14155552671'), '+14155552671');
    });

    test('Mock directory contains provisioned test worker and rejects unregistered', () async {
      final mockAuth = MockAuthService();

      // Test provisioned active worker (Rajesh Kumar - Sanitation)
      final profile = await mockAuth.verifyOtp(
        phoneNumber: '9999999999',
        otpCode: '123456',
      );
      expect(profile.displayName, 'Rajesh Kumar');
      expect(profile.employeeCode, 'EVR-SWM-4091');
      expect(profile.departmentId, 'dept-swm');
      expect(profile.isActive, isTrue);

      // Test provisioned crew lead (Sunita Sharma - Water Supply)
      final leadProfile = await mockAuth.verifyOtp(
        phoneNumber: '9876543210',
        otpCode: '123456',
      );
      expect(leadProfile.displayName, 'Sunita Sharma');
      expect(leadProfile.departmentId, 'dept-water');

      // Test unregistered number throws UnregisteredWorkerException
      expect(
        () => mockAuth.verifyOtp(phoneNumber: '9800000000', otpCode: '123456'),
        throwsA(isA<UnregisteredWorkerException>()),
      );

      // Test deactivated worker throws UnregisteredWorkerException
      expect(
        () => mockAuth.verifyOtp(phoneNumber: '9111111111', otpCode: '123456'),
        throwsA(isA<UnregisteredWorkerException>()),
      );

      // Test invalid OTP code throws general Exception
      expect(
        () => mockAuth.verifyOtp(phoneNumber: '9999999999', otpCode: '000000'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Phase 2.2: Auth State Notifier Transitions & Sign Out', () {
    test('State transitions from unauthenticated -> otpSent -> authenticated -> signedOut',
        () async {
      final mockAuth = MockAuthService();
      final notifier = AuthNotifier(mockAuth);

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.isAuthenticated, isFalse);

      // Send OTP
      await notifier.sendOtp('9999999999');
      expect(notifier.state.status, AuthStatus.otpSent);
      expect(notifier.state.phoneNumber, '9999999999');
      expect(notifier.state.resendCountdown, greaterThan(0));

      // Verify OTP
      final success = await notifier.verifyOtp('123456');
      expect(success, isTrue);
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.profile?.displayName, 'Rajesh Kumar');

      // Sign out
      await notifier.signOut();
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.profile, isNull);
      expect(notifier.state.isAuthenticated, isFalse);

      notifier.dispose();
    });

    test('Unregistered worker marks state as unregisteredWorker', () async {
      final mockAuth = MockAuthService();
      final notifier = AuthNotifier(mockAuth);

      await notifier.sendOtp('9800000000');
      final success = await notifier.verifyOtp('123456');

      expect(success, isFalse);
      expect(notifier.state.status, AuthStatus.unregisteredWorker);
      expect(notifier.state.isAuthenticated, isFalse);

      notifier.dispose();
    });
  });

  group('Phase 2.3: UI Widget Rendering & Verification Flow', () {
    testWidgets('LoginScreen renders brand logo, input, test chip, and footnote',
        (tester) async {
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
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Evora-Workers'), findsOneWidget);
      expect(find.text('Municipal Field Worker Sign In'), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);
      expect(find.text('Quick Test Worker (9999999999)'), findsOneWidget);
      expect(find.text('Get Verification OTP'), findsOneWidget);
      expect(
        find.text('Authorized Municipal Staff Only • Self-registration is disabled.'),
        findsOneWidget,
      );
    });

    testWidgets('OtpVerificationScreen displays test banner for 9999999999',
        (tester) async {
      final mockAuth = MockAuthService();
      final notifier = AuthNotifier(mockAuth);
      notifier.setOtpSentState(phoneNumber: '9999999999');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authNotifierProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: OtpVerificationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verify One-Time Password'), findsOneWidget);
      expect(find.text('Test Mode: Use verification code 123456'), findsOneWidget);
      expect(find.text('Verify & Sign In'), findsOneWidget);
    });

    testWidgets('UnregisteredWorkerDialog renders guidance and helpline',
        (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  UnregisteredWorkerDialog.show(
                    ctx,
                    phoneNumber: '+91 98000 00000',
                    onDismiss: () => dismissed = true,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted: Not Provisioned'), findsOneWidget);
      expect(find.text('Municipal Control Room: 112'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);

      await tester.tap(find.text('Back to Sign In'));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });
  });
}
