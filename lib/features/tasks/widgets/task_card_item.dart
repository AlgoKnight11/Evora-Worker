import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../core/widgets/evora_status_badge.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/worker_task.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Interactive high-contrast municipal task card designed for outdoor visibility.
class TaskCardItem extends StatelessWidget {
  final WorkerTask task;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onClaim;
  final VoidCallback? onDismiss;
  final VoidCallback? onStartWork;

  const TaskCardItem({
    super.key,
    required this.task,
    required this.onTap,
    this.onAccept,
    this.onDecline,
    this.onClaim,
    this.onDismiss,
    this.onStartWork,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (pBg, pFg, pIcon, pLabel) = switch (task.priority) {
      TaskPriority.p1 => (
          EvoraColors.errorContainer,
          EvoraColors.error,
          Icons.emergency_rounded,
          'P1 Critical',
        ),
      TaskPriority.p2 => (
          const Color(0xFFFFE0B2),
          const Color(0xFFD97706),
          Icons.priority_high_rounded,
          'P2 High',
        ),
      TaskPriority.p3 => (
          const Color(0xFFFFF9C4),
          const Color(0xFFB45309),
          Icons.info_outline_rounded,
          'P3 Medium',
        ),
      TaskPriority.p4 => (
          const Color(0xFFF1F5F9),
          const Color(0xFF64748B),
          Icons.low_priority_rounded,
          'P4 Low',
        ),
    };

    final categoryIcon = switch (task.categoryId) {
      'bin_overflow' || 'garbage_collection' || 'sanitation' =>
        Icons.delete_sweep_rounded,
      'pipeline_leak' || 'water_supply' || 'drainage' =>
        Icons.water_drop_rounded,
      'street_light' || 'electrical_hazard' =>
        Icons.electric_bolt_rounded,
      'road_pothole' || 'road_repair' || 'infrastructure' =>
        Icons.construction_rounded,
      _ => Icons.assignment_outlined,
    };

    final slaDiff = task.dueAt.difference(DateTime.now());
    final isSlaBreached = task.isOverdue || slaDiff.isNegative;

    return Semantics(
      button: true,
      label: '${task.title}, Priority ${task.priority.value}, Status ${task.status.value}',
      child: Material(
        color: isDark ? const Color(0xFF1E2922) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: task.priority == TaskPriority.p1
                    ? EvoraColors.error.withValues(alpha: 0.45)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                width: task.priority == TaskPriority.p1 ? 1.5 : 1.0,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Badges Row: Priority Pill, Status Badge, CivicFlow Tag
                Row(
                  children: [
                    // Priority Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(pIcon, size: 13, color: pFg),
                          const SizedBox(width: 4),
                          Text(
                            pLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: pFg,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Operational Status Badge
                    TaskStatusBadge(status: task.status),

                    const Spacer(),

                    // CivicFlow Citizen Case Tag if linked
                    if (task.civicFlowCaseId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: EvoraColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: EvoraColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_alt_outlined,
                              size: 11,
                              color: EvoraColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.civicFlowCaseId!.replaceFirst('case_', '').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: EvoraColors.primary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Category & Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: EvoraColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        categoryIcon,
                        size: 18,
                        color: EvoraColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.categoryNameSnapshot ?? task.categoryId,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: EvoraColors.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : EvoraColors.onSurface,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Location Row (Address, Landmark, Ward)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: EvoraColors.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${task.location.addressSummary} • ${task.wardId.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.8)
                                : const Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 4. SLA Countdown & Assignment Mode Row
                Row(
                  children: [
                    // SLA indicator
                    Icon(
                      isSlaBreached ? Icons.error_outline_rounded : Icons.timer_outlined,
                      size: 14,
                      color: isSlaBreached ? EvoraColors.error : const Color(0xFF0D9488),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isSlaBreached
                          ? l10n.tasksSlaOverdue
                          : '${slaDiff.inHours}h ${slaDiff.inMinutes % 60}m remaining',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isSlaBreached ? EvoraColors.error : const Color(0xFF0D9488),
                      ),
                    ),

                    const Spacer(),

                    // Team Pool Indicator
                    if (task.isUnclaimedTeamPool)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.30),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.groups_rounded, size: 12, color: Color(0xFF0284C7)),
                            SizedBox(width: 4),
                            Text(
                              'Team Pool',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // 5. Contextual Action Bar
                if (_hasActions) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  _buildActionBar(context, l10n),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasActions {
    if (task.isUnclaimedTeamPool && onClaim != null) return true;
    if (task.status == TaskStatus.assigned && (onAccept != null || onDecline != null)) {
      return true;
    }
    if ((task.status == TaskStatus.accepted || task.status == TaskStatus.inProgress) &&
        onStartWork != null) {
      return true;
    }
    return false;
  }

  Widget _buildActionBar(BuildContext context, AppLocalizations l10n) {
    // A. Team Pool Unclaimed Task: Claim Task & Dismiss
    if (task.isUnclaimedTeamPool && onClaim != null) {
      return Row(
        children: [
          if (onDismiss != null)
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppConstants.minTouchTargetSize),
                foregroundColor: const Color(0xFF64748B),
              ),
              child: Text(l10n.tasksActionDismiss),
            ),
          const Spacer(),
          ElevatedButton.icon(
            key: Key('btn_claim_task_${task.id}'),
            onPressed: onClaim,
            style: ElevatedButton.styleFrom(
              backgroundColor: EvoraColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(130, AppConstants.minTouchTargetSize),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.touch_app_rounded, size: 16),
            label: Text(
              l10n.tasksActionClaim,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      );
    }

    // B. Assigned Task: Accept & Decline Buttons
    if (task.status == TaskStatus.assigned) {
      return Row(
        children: [
          if (onDecline != null)
            Expanded(
              child: OutlinedButton(
                key: Key('btn_decline_task_${task.id}'),
                onPressed: onDecline,
                style: OutlinedButton.styleFrom(
                  foregroundColor: EvoraColors.error,
                  side: const BorderSide(color: EvoraColors.error),
                  minimumSize: const Size(0, AppConstants.minTouchTargetSize),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  l10n.tasksActionDecline,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          if (onAccept != null && onDecline != null) const SizedBox(width: 10),
          if (onAccept != null)
            Expanded(
              child: ElevatedButton(
                key: Key('btn_accept_task_${task.id}'),
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvoraColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, AppConstants.minTouchTargetSize),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  l10n.tasksActionAccept,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
        ],
      );
    }

    // C. Accepted or In-Progress: Start / Continue Work
    if (onStartWork != null) {
      final isStarted = task.status == TaskStatus.inProgress;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: Key('btn_start_work_${task.id}'),
          onPressed: onStartWork,
          style: ElevatedButton.styleFrom(
            backgroundColor: EvoraColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, AppConstants.minTouchTargetSize),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          icon: Icon(isStarted ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded, size: 18),
          label: Text(
            isStarted ? l10n.tasksActionContinueWork : l10n.tasksActionStartWork,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
