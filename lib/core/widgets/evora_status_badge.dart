import 'package:flutter/material.dart';
import '../../domain/enums/worker_enums.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/evora_colors.dart';

/// Accessible status chip combining an explicit icon + localized label (never color alone).
class TaskStatusBadge extends StatelessWidget {
  final TaskStatus status;

  const TaskStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (label, icon, fg, bg) = switch (status) {
      TaskStatus.assigned => (
          l10n.statusAssigned,
          Icons.assignment_ind_outlined,
          EvoraColors.infoBlue,
          EvoraColors.infoBlueContainer,
        ),
      TaskStatus.accepted => (
          l10n.statusAccepted,
          Icons.thumb_up_alt_outlined,
          EvoraColors.primary,
          EvoraColors.successContainer,
        ),
      TaskStatus.inProgress => (
          l10n.statusInProgress,
          Icons.engineering_outlined,
          EvoraColors.primaryContainer,
          EvoraColors.successContainer,
        ),
      TaskStatus.blocked => (
          l10n.statusBlocked,
          Icons.pause_circle_outline_rounded,
          EvoraColors.error,
          EvoraColors.errorContainer,
        ),
      TaskStatus.submittedForReview => (
          l10n.statusSubmittedForReview,
          Icons.fact_check_outlined,
          EvoraColors.warmOchre,
          EvoraColors.warningContainer,
        ),
      TaskStatus.returned => (
          l10n.statusReturned,
          Icons.replay_circle_filled_outlined,
          EvoraColors.tertiaryContainer,
          EvoraColors.warningContainer,
        ),
      TaskStatus.approved => (
          l10n.statusApproved,
          Icons.verified_outlined,
          EvoraColors.verifiedSeal,
          EvoraColors.successContainer,
        ),
      TaskStatus.cancelled => (
          l10n.statusCancelled,
          Icons.cancel_outlined,
          EvoraColors.onSurfaceVariant,
          EvoraColors.surfaceContainerHigh,
        ),
      TaskStatus.reassigned => (
          l10n.statusReassigned,
          Icons.swap_horiz_rounded,
          EvoraColors.onSurfaceVariant,
          EvoraColors.surfaceContainerHigh,
        ),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accessible priority badge (P1–P4) combining icon + localized label.
class TaskPriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const TaskPriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (label, icon, fg, bg) = switch (priority) {
      TaskPriority.p1 => (
          l10n.priorityP1,
          Icons.priority_high_rounded,
          EvoraColors.onErrorContainer,
          EvoraColors.errorContainer,
        ),
      TaskPriority.p2 => (
          l10n.priorityP2,
          Icons.keyboard_double_arrow_up_rounded,
          EvoraColors.tertiaryContainer,
          EvoraColors.warningContainer,
        ),
      TaskPriority.p3 => (
          l10n.priorityP3,
          Icons.remove_rounded,
          EvoraColors.infoBlue,
          EvoraColors.infoBlueContainer,
        ),
      TaskPriority.p4 => (
          l10n.priorityP4,
          Icons.keyboard_arrow_down_rounded,
          EvoraColors.onSurfaceVariant,
          EvoraColors.surfaceContainerHigh,
        ),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
