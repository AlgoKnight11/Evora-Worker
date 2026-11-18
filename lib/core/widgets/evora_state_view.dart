import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/evora_colors.dart';

/// Standard data-driven screen states required across all EVORA portals (Sec. 6.4).
enum EvoraScreenStateKind {
  loading,
  empty,
  error,
  offline,
  permissionDenied,
  staleData,
}

/// Reusable accessible state widget supporting loading, empty, error,
/// offline, permission-denied, and stale-data presentations.
class EvoraStateView extends StatelessWidget {
  final EvoraScreenStateKind kind;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EvoraStateView({
    super.key,
    required this.kind,
    this.title,
    this.subtitle,
    this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final (defaultIcon, accentColor, bgColor, defaultTitle, defaultSubtitle) =
        switch (kind) {
      EvoraScreenStateKind.loading => (
          Icons.sync_rounded,
          EvoraColors.primary,
          EvoraColors.successContainer,
          l10n.stateLoadingTitle,
          l10n.stateLoadingSubtitle,
        ),
      EvoraScreenStateKind.empty => (
          Icons.inbox_outlined,
          EvoraColors.primary,
          EvoraColors.surfaceContainerLow,
          l10n.stateEmptyTitle,
          l10n.stateEmptySubtitle,
        ),
      EvoraScreenStateKind.error => (
          Icons.error_outline_rounded,
          EvoraColors.error,
          EvoraColors.errorContainer,
          l10n.stateErrorTitle,
          l10n.stateErrorSubtitle,
        ),
      EvoraScreenStateKind.offline => (
          Icons.cloud_off_rounded,
          EvoraColors.warmOchre,
          EvoraColors.warningContainer,
          l10n.stateOfflineTitle,
          l10n.stateOfflineSubtitle,
        ),
      EvoraScreenStateKind.permissionDenied => (
          Icons.lock_outline_rounded,
          EvoraColors.error,
          EvoraColors.errorContainer,
          l10n.statePermissionDeniedTitle,
          l10n.statePermissionDeniedSubtitle,
        ),
      EvoraScreenStateKind.staleData => (
          Icons.history_toggle_off_rounded,
          EvoraColors.warmOchre,
          EvoraColors.warningContainer,
          l10n.stateStaleDataTitle,
          l10n.stateStaleDataSubtitle,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: kind == EvoraScreenStateKind.loading
                    ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: EvoraColors.primary,
                        ),
                      )
                    : Icon(
                        icon ?? defaultIcon,
                        size: 32,
                        color: accentColor,
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                title ?? defaultTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle ?? defaultSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: EvoraColors.onSurfaceVariant,
                ),
              ),
              if (onAction != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(
                    kind == EvoraScreenStateKind.staleData
                        ? Icons.refresh_rounded
                        : Icons.replay_rounded,
                    size: 18,
                  ),
                  label: Text(
                    actionLabel ??
                        (kind == EvoraScreenStateKind.staleData
                            ? l10n.actionRefresh
                            : l10n.actionRetry),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
