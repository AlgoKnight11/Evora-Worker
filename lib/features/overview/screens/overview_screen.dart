import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/duty_provider.dart';
import '../../../core/state/sync_status_provider.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../core/theme/evora_typography.dart';
import '../../../core/widgets/evora_status_badge.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/worker_task.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../routes/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tasks/models/task_filter.dart';
import '../../tasks/providers/task_providers.dart';

/// My Overview (`/overview`): Real-time shift dashboard displaying today's tasks,
/// urgent dispatch queue, live metrics ribbon, and route navigation shortcuts.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final profile = authState.profile;
    final syncState = ref.watch(syncStatusProvider);
    final metrics = ref.watch(overviewMetricsProvider);
    final isOnDuty = ref.watch(dutyProvider);

    return Scaffold(
      backgroundColor: EvoraColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tasksStreamProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // 1. Shift & Worker Welcome Banner
            _WorkerShiftBanner(
              profile: profile,
              syncState: syncState,
              isOnDuty: isOnDuty,
              onToggleDuty: () async {
                final newStatus =
                    await ref.read(dutyProvider.notifier).toggleDuty(profile);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newStatus
                            ? 'Shift Active: On Duty (Live dispatches connected even when closed)'
                            : 'Shift Ended: Off Duty',
                      ),
                      backgroundColor: newStatus
                          ? const Color(0xFF00E676)
                          : EvoraColors.onSurfaceVariant,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              l10n: l10n,
              theme: theme,
            ),
            const SizedBox(height: 16),

            // 2. Interactive Operational Metrics Ribbon (Tapping filters /tasks)
            _MetricsRibbon(
              metrics: metrics,
              l10n: l10n,
              onFilterSelected: (filter) {
                ref.read(taskFilterProvider.notifier).state = filter;
                try {
                  context.go(WorkerRoutes.tasks);
                } catch (_) {}
              },
            ),
            const SizedBox(height: 24),

            // 3. Urgent / P1 Dispatch Section
            _UrgentDispatchSection(
              urgentTasks: metrics.urgentTasks,
              l10n: l10n,
              theme: theme,
              onTaskClaimed: (taskId) async {
                final success = await ref
                    .read(taskOperationsProvider.notifier)
                    .claimTeamPoolTask(taskId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Task claimed successfully'
                            : 'Failed to claim task: Already claimed',
                      ),
                      backgroundColor:
                          success ? EvoraColors.primary : EvoraColors.error,
                    ),
                  );
                }
              },
              onTaskAccepted: (taskId) async {
                final success = await ref
                    .read(taskOperationsProvider.notifier)
                    .acceptTask(taskId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Task accepted'
                            : 'Failed to accept task',
                      ),
                      backgroundColor:
                          success ? EvoraColors.primary : EvoraColors.error,
                    ),
                  );
                }
              },
              onViewDetails: (taskId) {
                context.go(WorkerRoutes.taskDetail(taskId));
              },
            ),
            const SizedBox(height: 24),

            // 4. Quick Actions & Work Route Shortcuts
            Text(
              l10n.overviewQuickActionsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    title: l10n.overviewActionViewTasks,
                    badgeCount: metrics.totalToday,
                    icon: Icons.checklist_rounded,
                    accent: EvoraColors.primary,
                    tint: EvoraColors.successContainer,
                    onTap: () {
                      ref.read(taskFilterProvider.notifier).state =
                          const TaskFilter();
                      context.go(WorkerRoutes.tasks);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    title: l10n.overviewActionOpenMap,
                    icon: Icons.map_rounded,
                    accent: EvoraColors.pinePrimary,
                    tint: EvoraColors.surfaceContainerLow,
                    onTap: () => context.go(WorkerRoutes.map),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Municipal Control Room & Emergency Dispatch Helpline
            _ControlRoomHelplineCard(l10n: l10n, theme: theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Header banner displaying authenticated worker, employee code, crew, and sync state.
class _WorkerShiftBanner extends StatelessWidget {
  final dynamic profile;
  final SyncStatusState syncState;
  final bool isOnDuty;
  final VoidCallback? onToggleDuty;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _WorkerShiftBanner({
    required this.profile,
    required this.syncState,
    this.isOnDuty = true,
    this.onToggleDuty,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final workerName = profile?.displayName ?? 'Field Worker';
    final empCode = profile?.employeeCode ?? 'EVR-STAFF';
    final deptName = profile?.departmentName ?? profile?.departmentId ?? 'Municipal Operations';
    final teamName = profile?.teamName ?? profile?.teamId ?? 'General Field Crew';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF072A1D), Color(0xFF02130C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workerName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$empCode • $deptName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: EvoraColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: EvoraColors.secondary.withValues(alpha: 0.40),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: syncState.connectionState == SyncConnectionState.online
                            ? EvoraColors.secondary
                            : EvoraColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      syncState.connectionState == SyncConnectionState.online
                          ? l10n.syncOnline
                          : l10n.syncOffline,
                      style: const TextStyle(
                        color: EvoraColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.group_work_rounded,
                      size: 14,
                      color: EvoraColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        teamName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.90),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // On-Duty Shift Switch
              InkWell(
                onTap: onToggleDuty,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.only(left: 10, right: 4, top: 2, bottom: 2),
                  decoration: BoxDecoration(
                    color: isOnDuty
                        ? const Color(0xFF00E676).withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isOnDuty
                          ? const Color(0xFF00E676).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isOnDuty ? 'On Duty' : 'Off Duty',
                        style: TextStyle(
                          color: isOnDuty ? const Color(0xFF00E676) : Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch.adaptive(
                          value: isOnDuty,
                          onChanged: (_) => onToggleDuty?.call(),
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF00E676),
                          inactiveThumbColor: Colors.white70,
                          inactiveTrackColor: Colors.white24,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 4-card operational KPI summary ribbon.
class _MetricsRibbon extends StatelessWidget {
  final OverviewMetrics metrics;
  final AppLocalizations l10n;
  final ValueChanged<TaskFilter> onFilterSelected;

  const _MetricsRibbon({
    required this.metrics,
    required this.l10n,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 560 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: crossAxisCount == 4 ? 1.3 : 1.45,
          children: [
            _KpiCard(
              key: const Key('kpi_today_tasks'),
              label: l10n.overviewTodayTasks,
              value: '${metrics.totalToday}',
              icon: Icons.calendar_today_rounded,
              accent: EvoraColors.primary,
              tint: EvoraColors.successContainer,
              onTap: () => onFilterSelected(const TaskFilter(scope: TaskScope.all)),
            ),
            _KpiCard(
              key: const Key('kpi_assigned_tasks'),
              label: l10n.overviewAssignedAction,
              value: '${metrics.assignedCount}',
              icon: Icons.inbox_rounded,
              accent: EvoraColors.onSecondaryContainer,
              tint: const Color(0xFFE6F4EA),
              onTap: () => onFilterSelected(
                const TaskFilter(statusTab: TaskStatus.assigned),
              ),
            ),
            _KpiCard(
              key: const Key('kpi_in_progress_tasks'),
              label: l10n.overviewInProgress,
              value: '${metrics.inProgressCount}',
              icon: Icons.run_circle_outlined,
              accent: EvoraColors.tertiary,
              tint: EvoraColors.warningContainer,
              onTap: () => onFilterSelected(
                const TaskFilter(statusTab: TaskStatus.inProgress),
              ),
            ),
            _KpiCard(
              key: const Key('kpi_blocked_tasks'),
              label: l10n.overviewBlockedAlert,
              value: '${metrics.blockedCount}',
              icon: Icons.block_rounded,
              accent: EvoraColors.error,
              tint: EvoraColors.errorContainer,
              onTap: () => onFilterSelected(
                const TaskFilter(statusTab: TaskStatus.blocked),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color tint;
  final VoidCallback onTap;

  const _KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: EvoraColors.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: EvoraColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: EvoraColors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Urgent and SLA-critical task queue section.
class _UrgentDispatchSection extends StatelessWidget {
  final List<WorkerTask> urgentTasks;
  final AppLocalizations l10n;
  final ThemeData theme;
  final ValueChanged<String> onTaskClaimed;
  final ValueChanged<String> onTaskAccepted;
  final ValueChanged<String> onViewDetails;

  const _UrgentDispatchSection({
    required this.urgentTasks,
    required this.l10n,
    required this.theme,
    required this.onTaskClaimed,
    required this.onTaskAccepted,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.overviewUrgentDispatchTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (urgentTasks.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EvoraColors.errorContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${urgentTasks.length}',
                  style: const TextStyle(
                    color: EvoraColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (urgentTasks.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: EvoraColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: EvoraColors.successContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: EvoraColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.overviewUrgentEmptyTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.overviewUrgentEmptySubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: EvoraColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: urgentTasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = urgentTasks[index];
              return _UrgentTaskCard(
                task: task,
                l10n: l10n,
                theme: theme,
                onClaim: () => onTaskClaimed(task.id),
                onAccept: () => onTaskAccepted(task.id),
                onView: () => onViewDetails(task.id),
              );
            },
          ),
      ],
    );
  }
}

class _UrgentTaskCard extends StatelessWidget {
  final WorkerTask task;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onClaim;
  final VoidCallback onAccept;
  final VoidCallback onView;

  const _UrgentTaskCard({
    required this.task,
    required this.l10n,
    required this.theme,
    required this.onClaim,
    required this.onAccept,
    required this.onView,
  });

  String _formatSlaRemaining() {
    final diff = task.dueAt.difference(DateTime.now());
    if (diff.isNegative) {
      final mins = diff.inMinutes.abs();
      return '🚨 Overdue by ${mins}m';
    } else {
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      return '⏳ ${hours}h ${mins}m remaining';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPool = task.isUnclaimedTeamPool;
    final isAssigned = task.status == TaskStatus.assigned && !isPool;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: task.isOverdue
              ? EvoraColors.error.withValues(alpha: 0.5)
              : EvoraColors.outlineVariant.withValues(alpha: 0.6),
          width: task.isOverdue ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top badges: Priority + SLA Remaining + Pool Tag
            Row(
              children: [
                TaskPriorityBadge(priority: task.priority),
                const SizedBox(width: 8),
                if (isPool)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: EvoraColors.infoBlueContainer,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      l10n.overviewClaimPoolTag,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: EvoraColors.infoBlue,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  _formatSlaRemaining(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: task.isOverdue ? EvoraColors.error : EvoraColors.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              task.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),

            // Location Summary
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: EvoraColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.location.landmark != null
                        ? '${task.location.landmark}, ${task.location.addressSummary}'
                        : task.location.addressSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: EvoraColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                if (isPool)
                  FilledButton.icon(
                    onPressed: onClaim,
                    icon: const Icon(Icons.handshake_rounded, size: 16),
                    label: Text(l10n.overviewClaimAction),
                    style: FilledButton.styleFrom(
                      backgroundColor: EvoraColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                else if (isAssigned)
                  FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(l10n.overviewAcceptAction),
                    style: FilledButton.styleFrom(
                      backgroundColor: EvoraColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                const Spacer(),
                OutlinedButton(
                  onPressed: onView,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(l10n.overviewViewDetail),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation shortcut card.
class _QuickActionCard extends StatelessWidget {
  final String title;
  final int? badgeCount;
  final IconData icon;
  final Color accent;
  final Color tint;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    this.badgeCount,
    required this.icon,
    required this.accent,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: EvoraColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (badgeCount != null && badgeCount! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
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

/// Bottom emergency card for field workers.
class _ControlRoomHelplineCard extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;

  const _ControlRoomHelplineCard({
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EvoraColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EvoraColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: EvoraColors.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.phone_in_talk_rounded,
              color: EvoraColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.overviewControlRoomTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.overviewControlRoomSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: EvoraColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
