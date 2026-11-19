import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Modal dialog presented when a verified phone number is not found
/// in the municipal provisioned directory.
class UnregisteredWorkerDialog extends StatelessWidget {
  final String phoneNumber;
  final VoidCallback onDismiss;

  const UnregisteredWorkerDialog({
    super.key,
    required this.phoneNumber,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String phoneNumber,
    required VoidCallback onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UnregisteredWorkerDialog(
        phoneNumber: phoneNumber,
        onDismiss: () {
          Navigator.of(ctx).pop();
          onDismiss();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: EvoraColors.amberAlert.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: EvoraColors.amberAlert,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n?.authUnregisteredTitle ?? 'Access Restricted: Not Provisioned',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: EvoraColors.slateCharcoal,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.authUnregisteredMessage(phoneNumber) ??
                  'The mobile number $phoneNumber is not listed in municipal field records. Contact your supervisor to activate your account.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: EvoraColors.slateMuted,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EvoraColors.cloudSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EvoraColors.cloudBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_in_talk_outlined,
                    color: EvoraColors.pinePrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n?.profileEmergencyHelpline ?? 'Municipal Control Room: 112',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: EvoraColors.slateCharcoal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: AppConstants.minTouchTargetSize,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvoraColors.pinePrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n?.authBackToLogin ?? 'Back to Sign In',
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
    );
  }
}
