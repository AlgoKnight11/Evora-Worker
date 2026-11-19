import '../models/worker_profile.dart';

/// Repository contract for municipally provisioned phone OTP authentication.
/// Concrete Firebase Auth implementation wired in Phase 2.
abstract class AuthRepository {
  Stream<WorkerProfile?> watchActiveWorker();

  Future<void> requestOtp({required String phoneNumber});

  Future<WorkerProfile> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    String? verificationId,
  });

  /// Verifies server-side tenant membership and active status (immediate revocation check).
  Future<bool> validateActiveSession();

  /// Signs out and purges locally cached sensitive task data.
  Future<void> signOutAndPurgeCache();
}
