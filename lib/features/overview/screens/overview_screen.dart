import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/sync_status_provider.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../core/theme/evora_typography.dart';
import '../../../l10n/generated/app_localizations.dart';

/// My Overview (`/overview`): Today's tasks, urgent work, overdue count, notices, and sync state.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final syncState = ref.watch(syncStatusProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome Operational Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [EvoraColors.primary, EvoraColors.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.overviewGreeting,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: EvoraColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.appSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: EvoraColors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: EvoraColors.onPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.engineering_rounded,
                  color: EvoraColors.onPrimary,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2x2 KPI Summary Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 560 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: crossAxisCount == 4 ? 1.25 : 1.45,
              children: [
                _KpiCard(
                  label: l10n.overviewTodayTasks,
                  value: '0',
                  icon: Icons.today_rounded,
                  accent: EvoraColors.primary,
                  tint: EvoraColors.successContainer,
                ),
                _KpiCard(
                  label: l10n.overviewUrgentWork,
                  value: '0',
                  icon: Icons.priority_high_rounded,
                  accent: EvoraColors.error,
                  tint: EvoraColors.errorContainer,
                ),
                _KpiCard(
                  label: l10n.overviewOverdueTasks,
                  value: '0',
                  icon: Icons.schedule_rounded,
                  accent: EvoraColors.tertiary,
                  tint: EvoraColors.warningContainer,
                ),
                _KpiCard(
                  label: l10n.overviewPendingSync,
                  value: '${syncState.pendingOperationCount}',
                  icon: Icons.cloud_upload_outlined,
                  accent: EvoraColors.infoBlue,
                  tint: EvoraColors.infoBlueContainer,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Operational Notices Card
        Text(
          l10n.overviewNoticesTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: EvoraColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: EvoraColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.overviewNoticesEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: EvoraColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Phase 1 Readiness Info Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: EvoraColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: EvoraColors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 20,
                color: EvoraColors.verifiedSeal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.overviewPhaseBanner,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: EvoraColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color tint;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                Text(
                  value,
                  style: EvoraTypography.metricStyle(
                    fontSize: 26,
                    color: EvoraColors.onSurface,
                  ),
                ),
              ],
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: EvoraColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
