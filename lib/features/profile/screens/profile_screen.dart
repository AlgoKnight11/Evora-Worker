import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';

/// Profile & Help (`/profile`): Worker identity, department and ward assignments,
/// runtime Hindi/English switcher, emergency guidance, and secure sign-out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _changeLanguage(
    BuildContext context,
    WidgetRef ref,
    Locale locale,
  ) async {
    await ref.read(localeProvider.notifier).selectLanguage(locale);
    if (!context.mounted) return;
    final label = locale.languageCode == 'hi' ? 'हिन्दी' : 'English';
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.languageChangedNotice(label)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n?.authSignOutConfirmTitle ?? 'Confirm Sign Out',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: EvoraColors.slateCharcoal,
          ),
        ),
        content: Text(
          l10n?.authSignOutConfirmMessage ??
              'Are you sure you want to sign out? Your session on this device will end.',
          style: const TextStyle(
            fontSize: 14,
            color: EvoraColors.slateMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n?.authCancel ?? 'Cancel',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: EvoraColors.slateMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authNotifierProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n?.authSignOut ?? 'Sign Out',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeState = ref.watch(localeProvider);
    final authState = ref.watch(authNotifierProvider);
    final profile = authState.profile;

    final displayName = profile?.displayName ?? 'Field Worker';
    final employeeCode = profile?.employeeCode ?? 'EVR-MUNICIPAL';
    final department = profile?.departmentName ??
        profile?.departmentId ??
        l10n.profileDepartmentPending;
    final crew = profile?.teamName ?? profile?.teamId ?? 'Municipal Quick Response';
    final supervisor = profile?.supervisorName ?? l10n.profileSupervisorPending;
    final supervisorPhone = profile?.supervisorPhone ?? '112';
    final serviceAreas = (profile?.authorizedServiceAreaIds.isNotEmpty == true)
        ? profile!.authorizedServiceAreaIds.join(', ')
        : 'Assigned Municipal Wards';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Worker Identity Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: EvoraColors.successContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          AppConstants.leafBadgeAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person_rounded,
                            color: EvoraColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: EvoraColors.emeraldAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: EvoraColors.pinePrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: $employeeCode • ${profile?.phoneNumber ?? ""}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: EvoraColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.business_outlined,
                  label: l10n.profileDepartmentLabel,
                  value: '$department ($crew)',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.map_outlined,
                  label: 'Authorized Service Area',
                  value: serviceAreas,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.support_agent_rounded,
                  label: l10n.profileSupervisorLabel,
                  value: '$supervisor ($supervisorPhone)',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Runtime Hindi / English Language Switcher Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.translate_rounded,
                      color: EvoraColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.languageSettingsTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            l10n.languageSettingsSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: EvoraColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _LanguageSwitchButton(
                        key: const Key('profile_lang_en'),
                        label: 'English',
                        selected: !localeState.isHindi,
                        onTap: () => _changeLanguage(
                          context,
                          ref,
                          SupportedWorkerLocales.english,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LanguageSwitchButton(
                        key: const Key('profile_lang_hi'),
                        label: 'हिन्दी (Hindi)',
                        selected: localeState.isHindi,
                        onTap: () => _changeLanguage(
                          context,
                          ref,
                          SupportedWorkerLocales.hindi,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Field Safety & Offline Emergency Guidance Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EvoraColors.errorContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: EvoraColors.error.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.health_and_safety_outlined,
                    color: EvoraColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.profileSafetyTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: EvoraColors.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.profileSafetyDesc,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: EvoraColors.onErrorContainer,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: EvoraColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emergency_rounded,
                      size: 18,
                      color: EvoraColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.profileEmergencyHelpline,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: EvoraColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Sign Out Button
        SizedBox(
          height: AppConstants.minTouchTargetSize,
          child: OutlinedButton.icon(
            onPressed: () => _showSignOutDialog(context, ref),
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: Text(
              l10n.authSignOut,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          l10n.profileVersionLabel,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: EvoraColors.outline,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: EvoraColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: EvoraColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageSwitchButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageSwitchButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? EvoraColors.primary
          : EvoraColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? EvoraColors.primary : EvoraColors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: EvoraColors.onPrimary,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? EvoraColors.onPrimary
                        : EvoraColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
