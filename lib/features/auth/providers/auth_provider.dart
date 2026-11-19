import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/worker_profile.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../models/auth_state.dart';
import '../services/firebase_auth_service.dart';
import '../services/mock_auth_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // If Firebase is not initialized (e.g. in unit/widget test environments),
  // fallback gracefully to MockAuthService.
  if (Firebase.apps.isEmpty) {
    final mockService = MockAuthService();
    ref.onDispose(mockService.dispose);
    return mockService;
  }

  final service = FirebaseAuthService();
  ref.onDispose(service.dispose);
  return service;
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepo);
});

/// Convenience provider for reading the authenticated WorkerProfile
final currentWorkerProfileProvider = Provider<WorkerProfile?>((ref) {
  return ref.watch(authNotifierProvider).profile;
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  Timer? _countdownTimer;

  AuthNotifier(this._authRepo) : super(const AuthState()) {
    // Listen to worker stream if available
    _authRepo.watchActiveWorker().listen((profile) {
      if (profile != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          profile: profile,
        );
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(resendCountdown: 60);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdown <= 1) {
        timer.cancel();
        state = state.copyWith(resendCountdown: 0);
      } else {
        state = state.copyWith(resendCountdown: state.resendCountdown - 1);
      }
    });
  }

  /// Sends phone verification OTP
  Future<void> sendOtp(String rawPhone) async {
    final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.length < 10) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Please enter a valid 10-digit phone number.',
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.sendingOtp,
      phoneNumber: rawPhone,
      clearError: true,
    );

    final authRepo = _authRepo;
    if (authRepo is FirebaseAuthService) {
      await authRepo.sendVerificationCode(
        phoneNumber: rawPhone,
        forceResendingToken: state.resendToken,
        onCodeSent: (verificationId, resendToken) {
          state = state.copyWith(
            status: AuthStatus.otpSent,
            verificationId: verificationId,
            resendToken: resendToken,
            phoneNumber: rawPhone,
          );
          _startCountdown();
        },
        onError: (errorMsg) {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: errorMsg,
          );
        },
      );
    } else {
      // Mock / fallback repository
      try {
        await _authRepo.requestOtp(phoneNumber: rawPhone);
        state = state.copyWith(
          status: AuthStatus.otpSent,
          verificationId: 'mock-verification-id',
          phoneNumber: rawPhone,
        );
        _startCountdown();
      } catch (e) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  /// Verifies submitted OTP code
  Future<bool> verifyOtp(String otpCode) async {
    if (state.phoneNumber == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Missing phone number session. Please request OTP again.',
      );
      return false;
    }

    state = state.copyWith(
      status: AuthStatus.verifying,
      clearError: true,
    );

    try {
      final profile = await _authRepo.verifyOtp(
        phoneNumber: state.phoneNumber!,
        otpCode: otpCode,
        verificationId: state.verificationId,
      );

      _countdownTimer?.cancel();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        profile: profile,
        resendCountdown: 0,
      );
      return true;
    } on UnregisteredWorkerException catch (e) {
      _countdownTimer?.cancel();
      state = state.copyWith(
        status: AuthStatus.unregisteredWorker,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Sets worker profile directly (used by tests and seed actions)
  void setAuthenticatedWorker(WorkerProfile profile) {
    _countdownTimer?.cancel();
    state = state.copyWith(
      status: AuthStatus.authenticated,
      profile: profile,
      phoneNumber: profile.phoneNumber,
    );
  }

  /// Sets state to OTP sent without starting continuous timer (used by tests)
  void setOtpSentState({
    required String phoneNumber,
    String verificationId = 'mock-v-id',
    int resendCountdown = 60,
  }) {
    _countdownTimer?.cancel();
    state = state.copyWith(
      status: AuthStatus.otpSent,
      phoneNumber: phoneNumber,
      verificationId: verificationId,
      resendCountdown: resendCountdown,
    );
  }

  /// Clears any transient error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Re-sets back to phone number entry step
  void resetToPhoneInput() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      clearVerification: true,
      clearError: true,
      resendCountdown: 0,
    );
  }

  /// Signs out and resets state
  Future<void> signOut() async {
    _countdownTimer?.cancel();
    await _authRepo.signOutAndPurgeCache();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
