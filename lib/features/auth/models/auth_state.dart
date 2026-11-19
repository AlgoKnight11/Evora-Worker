import '../../../domain/models/worker_profile.dart';

/// Represents high-level state of Worker Authentication.
enum AuthStatus {
  unauthenticated,
  sendingOtp,
  otpSent,
  verifying,
  authenticated,
  unregisteredWorker,
  error,
}

/// Immutable state containing the current worker session, verification state,
/// and cooldown countdown.
class AuthState {
  final AuthStatus status;
  final WorkerProfile? profile;
  final String? phoneNumber;
  final String? verificationId;
  final int? resendToken;
  final String? errorMessage;
  final int resendCountdown;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.profile,
    this.phoneNumber,
    this.verificationId,
    this.resendToken,
    this.errorMessage,
    this.resendCountdown = 0,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && profile != null;
  bool get isBusy => status == AuthStatus.sendingOtp || status == AuthStatus.verifying;
  bool get canResendOtp => resendCountdown <= 0 && !isBusy;

  AuthState copyWith({
    AuthStatus? status,
    WorkerProfile? profile,
    String? phoneNumber,
    String? verificationId,
    int? resendToken,
    String? errorMessage,
    int? resendCountdown,
    bool clearError = false,
    bool clearVerification = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: clearVerification ? null : (verificationId ?? this.verificationId),
      resendToken: clearVerification ? null : (resendToken ?? this.resendToken),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      resendCountdown: resendCountdown ?? this.resendCountdown,
    );
  }
}
