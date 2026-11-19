import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../routes/app_router.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';

/// Screen where municipal field workers enter their provisioned mobile number
/// to request an SMS login OTP.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onGetOtpPressed() {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) return;
    ref.read(authNotifierProvider.notifier).sendOtp(rawPhone);
  }

  void _fillTestNumber() {
    _phoneController.text = '9999999999';
    _phoneFocusNode.unfocus();
    _onGetOtpPressed();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);

    // Navigate to OTP verify only when code transition actually happens
    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (prev?.status != AuthStatus.otpSent && next.status == AuthStatus.otpSent) {
        context.go(WorkerRoutes.otpVerify);
      }
    });

    return Scaffold(
      backgroundColor: EvoraColors.cloudSurface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header with Transparent Logo
                Center(
                  child: Hero(
                    tag: 'evora_worker_brand_logo',
                    child: Image.asset(
                      AppConstants.logoCroppedAsset,
                      height: 52,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.nature_people_rounded,
                        size: 48,
                        color: EvoraColors.pinePrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: EvoraColors.pinePrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    l10n?.authLoginTitle ?? 'Municipal Field Worker Sign In',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: EvoraColors.slateCharcoal,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

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
                      Text(
                        l10n?.authPhoneLabel ?? 'Mobile Number',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: EvoraColors.slateCharcoal,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Phone Input Row with Country Code
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: EvoraColors.cloudSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: EvoraColors.cloudBorder),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: EvoraColors.slateCharcoal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: EvoraColors.slateCharcoal,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: l10n?.authPhoneHint ?? '98765 43210',
                                hintStyle: const TextStyle(
                                  color: EvoraColors.slateMuted,
                                  fontWeight: FontWeight.w400,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: EvoraColors.cloudBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: EvoraColors.emeraldAccent,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _onGetOtpPressed(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Quick Test Preset Chip
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ActionChip(
                          avatar: const Icon(
                            Icons.verified_user_outlined,
                            size: 16,
                            color: EvoraColors.pinePrimary,
                          ),
                          label: Text(
                            l10n?.authTestChip ?? 'Quick Test Worker (9999999999)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: EvoraColors.pinePrimary,
                            ),
                          ),
                          backgroundColor: EvoraColors.emeraldAccent.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: EvoraColors.emeraldAccent.withValues(alpha: 0.3),
                          ),
                          onPressed: (authState.isBusy ||
                                  authState.status == AuthStatus.otpSent)
                              ? null
                              : _fillTestNumber,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error message if any
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

                      // Get OTP Button
                      SizedBox(
                        height: AppConstants.minTouchTargetSize,
                        child: ElevatedButton(
                          onPressed: (authState.isBusy ||
                                  authState.status == AuthStatus.otpSent)
                              ? null
                              : _onGetOtpPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EvoraColors.pinePrimary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                EvoraColors.pinePrimary.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: authState.status == AuthStatus.sendingOtp
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
                                  l10n?.authGetOtp ?? 'Get Verification OTP',
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

                const SizedBox(height: 24),
                // Security policy footnote
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: EvoraColors.slateMuted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n?.authRestrictedNotice ??
                              'Authorized Municipal Staff Only • Self-registration is disabled.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: EvoraColors.slateMuted,
                            fontWeight: FontWeight.w500,
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
