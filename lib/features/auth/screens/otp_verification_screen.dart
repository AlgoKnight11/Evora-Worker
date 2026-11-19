import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../routes/app_router.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';
import '../widgets/numeric_pin_input.dart';
import '../widgets/unregistered_worker_dialog.dart';

/// Screen where municipal field workers enter the 6-digit OTP code received via SMS.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  String _enteredOtp = '';

  void _onVerifyPressed() {
    if (_enteredOtp.trim().length != 6) return;
    ref.read(authNotifierProvider.notifier).verifyOtp(_enteredOtp.trim());
  }

  void _onResendPressed() {
    final phone = ref.read(authNotifierProvider).phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      ref.read(authNotifierProvider.notifier).sendOtp(phone);
    }
  }

  void _onEditPhonePressed() {
    ref.read(authNotifierProvider.notifier).resetToPhoneInput();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);
    final phoneNumber = authState.phoneNumber ?? '';
    final isTestNumber = phoneNumber.contains('9999999999');

    // Handle unregistered worker modal
    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next.status == AuthStatus.unregisteredWorker) {
        UnregisteredWorkerDialog.show(
          context,
          phoneNumber: phoneNumber,
          onDismiss: () {
            ref.read(authNotifierProvider.notifier).resetToPhoneInput();
            context.go(WorkerRoutes.login);
          },
        );
      } else if (next.status == AuthStatus.authenticated) {
        context.go(WorkerRoutes.overview);
      }
    });

    return Scaffold(
      backgroundColor: EvoraColors.cloudSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EvoraColors.slateCharcoal),
          onPressed: _onEditPhonePressed,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon
                Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: EvoraColors.pinePrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: EvoraColors.pinePrimary,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: Text(
                    l10n?.authVerifyTitle ?? 'Verify One-Time Password',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: EvoraColors.slateCharcoal,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    l10n?.authVerifySubtitle(phoneNumber) ??
                        'Enter the 6-digit code sent to $phoneNumber',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: EvoraColors.slateMuted,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _onEditPhonePressed,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: Text(
                      l10n?.authEditPhone ?? 'Change Phone Number',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: EvoraColors.pinePrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(22.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: EvoraColors.cloudBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Test number reminder banner
                      if (isTestNumber) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: EvoraColors.emeraldAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: EvoraColors.emeraldAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: EvoraColors.emeraldAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n?.authTestModeBanner ??
                                      'Test Mode: Use verification code 123456',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: EvoraColors.pinePrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // 6-digit numeric PIN input
                      NumericPinInput(
                        length: 6,
                        enabled: !authState.isBusy,
                        onChanged: (pin) {
                          setState(() {
                            _enteredOtp = pin;
                          });
                        },
                        onCompleted: (pin) {
                          setState(() {
                            _enteredOtp = pin;
                          });
                          _onVerifyPressed();
                        },
                      ),
                      const SizedBox(height: 20),

                      // Resend countdown timer or button
                      Center(
                        child: authState.resendCountdown > 0
                            ? Text(
                                l10n?.authResendIn(authState.resendCountdown) ??
                                    'Resend OTP in ${authState.resendCountdown}s',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: EvoraColors.slateMuted,
                                ),
                              )
                            : TextButton(
                                onPressed:
                                    authState.canResendOtp ? _onResendPressed : null,
                                child: Text(
                                  l10n?.authResendButton ?? 'Resend OTP Code',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: EvoraColors.pinePrimary,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Error banner if any
                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  size: 18, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Verify & Sign In Button
                      SizedBox(
                        height: AppConstants.minTouchTargetSize,
                        child: ElevatedButton(
                          onPressed: (_enteredOtp.trim().length == 6 &&
                                  !authState.isBusy)
                              ? _onVerifyPressed
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EvoraColors.pinePrimary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                EvoraColors.pinePrimary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: authState.status == AuthStatus.verifying
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  l10n?.authVerifyButton ?? 'Verify & Sign In',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
