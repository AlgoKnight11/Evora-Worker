import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../core/widgets/evora_status_badge.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/worker_task.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../routes/app_router.dart';
import '../providers/task_providers.dart';
import '../widgets/decline_task_dialog.dart';

/// Comprehensive Task Detail Screen (`/tasks/:taskId`) for field operatives.
/// Displays detailed work instructions, outdoor GIS coordinates, safety warnings,
/// evidentiary requirements, and contextual lifecycle action controls.
class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isProcessingAction = false;

  void _goBack() {
    try {
      if (context.canPop()) {
        context.pop();
        return;
      }
      context.go(WorkerRoutes.tasks);
      return;
    } catch (_) {}

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleClaim(WorkerTask task, AppLocalizations? l10n) async {
    setState(() => _isProcessingAction = true);
    final success = await ref
        .read(taskOperationsProvider.notifier)
        .claimTeamPoolTask(task.id);
    if (!mounted) return;
    setState(() => _isProcessingAction = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.tasksClaimSuccess ??
              'Task claimed successfully and added to your active queue'),
          backgroundColor: EvoraColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.invalidate(taskDetailProvider(task.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not claim task. It may have already been claimed by another worker.',
          ),
          backgroundColor: EvoraColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleAccept(WorkerTask task, AppLocalizations? l10n) async {
    setState(() => _isProcessingAction = true);
    final success =
        await ref.read(taskOperationsProvider.notifier).acceptTask(task.id);
    if (!mounted) return;
    setState(() => _isProcessingAction = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.tasksAcceptSuccess ??
              'Task accepted and ready for field execution'),
          backgroundColor: EvoraColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.invalidate(taskDetailProvider(task.id));
    }
  }

  Future<void> _handleDecline(WorkerTask task, AppLocalizations? l10n) async {
    final result = await DeclineTaskDialog.show(
      context,
      taskId: task.id,
      taskTitle: task.title,
    );

    if (result != null) {
      setState(() => _isProcessingAction = true);
      final success = await ref
          .read(taskOperationsProvider.notifier)
          .declineTask(taskId: task.id, reason: result.reason, note: result.note);
      if (!mounted) return;
      setState(() => _isProcessingAction = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.tasksDeclineSuccess ??
                'Task assignment declined and returned to dispatch pool'),
            backgroundColor: EvoraColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _goBack();
      }
    }
  }

  Future<void> _handleDismissPoolTask(
      WorkerTask task, AppLocalizations? l10n) async {
    setState(() => _isProcessingAction = true);
    final success =
        await ref.read(taskOperationsProvider.notifier).dismissPoolTask(task.id);
    if (!mounted) return;
    setState(() => _isProcessingAction = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.tasksDismissSuccess ??
              'Pool task dismissed from your feed'),
          backgroundColor: EvoraColors.onSurfaceVariant,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _goBack();
    }
  }

  void _openInMaps(WorkerTask task) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening coordinates (${task.location.latitude.toStringAsFixed(4)}, ${task.location.longitude.toStringAsFixed(4)}) in Maps',
        ),
        backgroundColor: EvoraColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101914) : EvoraColors.surface,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF14241B) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          key: const Key('btn_back_task_detail'),
          icon: const Icon(Icons.arrow_back_rounded),
          color: isDark ? Colors.white : EvoraColors.onSurface,
          tooltip: l10n?.taskDetailBackToList ?? 'Back to Tasks',
          onPressed: _goBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.taskDetailTitle ?? 'Task Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : EvoraColors.onSurface,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              widget.taskId,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : EvoraColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: taskAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: EvoraColors.primary,
          ),
        ),
        error: (err, _) => _buildNotFoundState(context, isDark, l10n),
        data: (task) {
          if (task == null) {
            return _buildNotFoundState(context, isDark, l10n);
          }
          return _buildTaskDetailContent(context, task, isDark, l10n);
        },
      ),
    );
  }

  Widget _buildNotFoundState(
      BuildContext context, bool isDark, AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : EvoraColors.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.taskDetailNotFound ?? 'Task Not Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : EvoraColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.taskDetailNotFoundSubtitle ??
                  'The requested municipal task could not be located or may have been reassigned.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : EvoraColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _goBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: EvoraColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(l10n?.taskDetailBackToList ?? 'Back to Tasks'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetailContent(BuildContext context, WorkerTask task,
      bool isDark, AppLocalizations? l10n) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Card (Title, Category, Priority, SLA, Status)
                _buildHeaderCard(context, task, isDark, l10n),
                const SizedBox(height: 14),

                // 2. Location & Dispatch Coordinates Card
                _buildLocationCard(context, task, isDark, l10n),
                const SizedBox(height: 14),

                // 3. Work Order Instructions Card
                _buildInstructionsCard(context, task, isDark, l10n),
                const SizedBox(height: 14),

                // 4. Safety Precautions Card
                _buildSafetyCard(context, task, isDark, l10n),
                const SizedBox(height: 14),

                // 5. Required Evidence Checklist Card
                _buildEvidenceCard(context, task, isDark, l10n),
                const SizedBox(height: 14),

                // 6. Timeline & Custody Card
                _buildTimelineCard(context, task, isDark, l10n),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // 7. Contextual Bottom Action Bar
        _buildBottomActionBar(context, task, isDark, l10n, bottomInset),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, WorkerTask task, bool isDark,
      AppLocalizations? l10n) {
    // Priority styling
    final (pFg, pBg, pIcon, pLabel) = switch (task.priority) {
      TaskPriority.p1 => (
          EvoraColors.error,
          EvoraColors.error.withValues(alpha: 0.12),
          Icons.emergency_rounded,
          'Critical'
        ),
      TaskPriority.p2 => (
          const Color(0xFFC2410C),
          const Color(0xFFC2410C).withValues(alpha: 0.12),
          Icons.warning_amber_rounded,
          'Urgent'
        ),
      TaskPriority.p3 => (
          EvoraColors.warmOchre,
          EvoraColors.warmOchre.withValues(alpha: 0.12),
          Icons.priority_high_rounded,
          'High'
        ),
      TaskPriority.p4 => (
          const Color(0xFF0369A1),
          const Color(0xFF0369A1).withValues(alpha: 0.12),
          Icons.low_priority_rounded,
          'Medium'
        ),
    };

    // Category Icon
    final catIcon = switch (task.categoryId) {
      'solid_waste' => Icons.delete_outline_rounded,
      'roads' => Icons.edit_road_rounded,
      'drainage' => Icons.water_damage_outlined,
      'lighting' => Icons.lightbulb_outline_rounded,
      'water' => Icons.water_drop_outlined,
      'sanitation' => Icons.cleaning_services_rounded,
      _ => Icons.assignment_outlined,
    };

    // SLA Calculation
    final now = DateTime.now();
    final remaining = task.dueAt.difference(now);
    final isBreached = remaining.isNegative;
    final String slaText;
    final Color slaFg;
    final Color slaBg;

    if (isBreached) {
      slaText = l10n?.tasksSlaOverdue ?? 'SLA Breached';
      slaFg = EvoraColors.error;
      slaBg = EvoraColors.error.withValues(alpha: 0.12);
    } else if (remaining.inHours < 4) {
      slaText = '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left';
      slaFg = const Color(0xFFC2410C);
      slaBg = const Color(0xFFC2410C).withValues(alpha: 0.12);
    } else if (remaining.inDays > 0) {
      slaText = '${remaining.inDays}d ${remaining.inHours.remainder(24)}h SLA';
      slaFg = EvoraColors.primary;
      slaBg = EvoraColors.primary.withValues(alpha: 0.10);
    } else {
      slaText = '${remaining.inHours}h left';
      slaFg = EvoraColors.primary;
      slaBg = EvoraColors.primary.withValues(alpha: 0.10);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18261E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Priority + Status + SLA
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(pIcon, size: 14, color: pFg),
                    const SizedBox(width: 4),
                    Text(
                      pLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: pFg,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TaskStatusBadge(status: task.status),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: slaBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBreached ? Icons.timer_off_outlined : Icons.timer_outlined,
                      size: 13,
                      color: slaFg,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      slaText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: slaFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            task.title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : EvoraColors.onSurface,
              letterSpacing: -0.2,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Category & Department Snapshot
          Row(
            children: [
              Icon(catIcon, size: 16, color: EvoraColors.primary),
              const SizedBox(width: 6),
              Text(
                task.categoryNameSnapshot ?? task.categoryId,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : EvoraColors.onSurface,
                ),
              ),
              if (task.departmentNameSnapshot != null) ...[
                Text(
                  ' • ',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : EvoraColors.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    task.departmentNameSnapshot!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : EvoraColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Source Tag: CivicFlow Case or Standalone
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: task.isCivicFlowLinked
                  ? const Color(0xFF0369A1).withValues(alpha: 0.08)
                  : EvoraColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: task.isCivicFlowLinked
                    ? const Color(0xFF0369A1).withValues(alpha: 0.25)
                    : EvoraColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  task.isCivicFlowLinked
                      ? Icons.campaign_rounded
                      : Icons.build_circle_outlined,
                  size: 14,
                  color: task.isCivicFlowLinked
                      ? const Color(0xFF0369A1)
                      : EvoraColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  task.isCivicFlowLinked
                      ? 'CivicFlow #${task.civicFlowCaseId}'
                      : (l10n?.taskDetailSourceStandalone ?? 'Municipal Work Order'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: task.isCivicFlowLinked
                        ? const Color(0xFF0369A1)
                        : EvoraColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, WorkerTask task, bool isDark,
      AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18261E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 20, color: EvoraColors.primary),
              const SizedBox(width: 8),
              Text(
                l10n?.taskDetailLocationSection ?? 'Location & Coordinates',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : EvoraColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Street Address
          Text(
            task.location.addressSummary,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : EvoraColors.onSurface,
            ),
          ),

          // Landmark
          if (task.location.landmark != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.near_me_outlined,
                  size: 14,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : EvoraColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Landmark: ${task.location.landmark}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : EvoraColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),

          // Ward & Coordinates Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.location.wardNameSnapshot ??
                      'Ward ${task.location.wardId}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : EvoraColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${task.location.latitude.toStringAsFixed(4)}°, ${task.location.longitude.toStringAsFixed(4)}°',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : EvoraColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Open in Maps Button
          OutlinedButton.icon(
            key: const Key('btn_open_in_maps'),
            onPressed: () => _openInMaps(task),
            style: OutlinedButton.styleFrom(
              foregroundColor: EvoraColors.primary,
              side: const BorderSide(color: EvoraColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            ),
            icon: const Icon(Icons.directions_rounded, size: 18),
            label: Text(
              l10n?.taskDetailOpenMaps ?? 'Open in Maps',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(BuildContext context, WorkerTask task,
      bool isDark, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18261E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 20, color: EvoraColors.primary),
              const SizedBox(width: 8),
              Text(
                l10n?.taskDetailInstructionsSection ?? 'Work Order Instructions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : EvoraColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF101914)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              task.instructions.isNotEmpty
                  ? task.instructions
                  : 'Follow municipal standard operating procedure for this assignment.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : EvoraColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard(BuildContext context, WorkerTask task, bool isDark,
      AppLocalizations? l10n) {
    final precautions = task.safetyPrecautions;
    if (precautions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF261D12)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EvoraColors.warmOchre.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 20, color: EvoraColors.warmOchre),
              const SizedBox(width: 8),
              Text(
                l10n?.taskDetailSafetySection ?? 'Safety Precautions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...precautions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 15, color: EvoraColors.warmOchre),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF78350F),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(BuildContext context, WorkerTask task, bool isDark,
      AppLocalizations? l10n) {
    final evidenceItems = task.requiredEvidence;
    if (evidenceItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18261E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded,
                  size: 20, color: EvoraColors.primary),
              const SizedBox(width: 8),
              Text(
                l10n?.taskDetailEvidenceSection ?? 'Required Evidence',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : EvoraColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...evidenceItems.map(
            (ev) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      size: 16, color: EvoraColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ev,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : EvoraColors.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: EvoraColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Mandatory',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: EvoraColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, WorkerTask task, bool isDark,
      AppLocalizations? l10n) {
    String formatDateTime(DateTime dt) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18261E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 20, color: EvoraColors.primary),
              const SizedBox(width: 8),
              Text(
                l10n?.taskDetailTimelineSection ?? 'Timeline & Custody',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : EvoraColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimelineRow(
            label: l10n?.taskDetailAssignedBy ?? 'Assigned By',
            value: task.assignedByUid,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildTimelineRow(
            label: l10n?.taskDetailAssignedAt ?? 'Assigned At',
            value: formatDateTime(task.assignedAt),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildTimelineRow(
            label: l10n?.taskDetailDueAt ?? 'Resolution Deadline',
            value: formatDateTime(task.dueAt),
            isDark: isDark,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required String label,
    required String value,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : EvoraColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight
                ? EvoraColors.primary
                : (isDark ? Colors.white : EvoraColors.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context, WorkerTask task,
      bool isDark, AppLocalizations? l10n, double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14241B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _buildContextualControls(context, task, isDark, l10n),
      ),
    );
  }

  Widget _buildContextualControls(BuildContext context, WorkerTask task,
      bool isDark, AppLocalizations? l10n) {
    if (_isProcessingAction) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(color: EvoraColors.primary),
        ),
      );
    }

    // 1. Unclaimed Pool Task
    if (task.isUnclaimedTeamPool) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton(
              key: const Key('btn_dismiss_task_detail'),
              onPressed: () => _handleDismissPoolTask(task, l10n),
              style: OutlinedButton.styleFrom(
                foregroundColor: EvoraColors.onSurfaceVariant,
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : EvoraColors.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                l10n?.tasksActionDismiss ?? 'Dismiss',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              key: const Key('btn_claim_task_detail'),
              onPressed: () => _handleClaim(task, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: EvoraColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              icon: const Icon(Icons.pan_tool_outlined, size: 18),
              label: Text(
                l10n?.tasksActionClaim ?? 'Claim Task',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      );
    }

    // 2. Assigned Task
    if (task.status == TaskStatus.assigned) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton(
              key: const Key('btn_decline_task_detail'),
              onPressed: () => _handleDecline(task, l10n),
              style: OutlinedButton.styleFrom(
                foregroundColor: EvoraColors.error,
                side: const BorderSide(color: EvoraColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                l10n?.tasksActionDecline ?? 'Decline',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              key: const Key('btn_accept_task_detail'),
              onPressed: () => _handleAccept(task, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: EvoraColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(
                l10n?.tasksActionAccept ?? 'Accept Task',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      );
    }

    // 3. Accepted Task (Ready for execution)
    if (task.status == TaskStatus.accepted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const Key('btn_start_work_detail'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Task is accepted. Field execution engine unlocks in Phase 4.',
                ),
                backgroundColor: EvoraColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: EvoraColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: Text(
            l10n?.tasksActionStartWork ?? 'Start Field Work',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      );
    }

    // 4. In Progress Task
    if (task.status == TaskStatus.inProgress) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: EvoraColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EvoraColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.engineering_rounded,
                size: 20, color: EvoraColors.primary),
            const SizedBox(width: 8),
            Text(
              l10n?.taskDetailActionInProgress ??
                  'Task In Progress • Field Execution Active',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: EvoraColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    // 5. Blocked Task
    if (task.status == TaskStatus.blocked) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: EvoraColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EvoraColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block_rounded, size: 20, color: EvoraColors.error),
            const SizedBox(width: 8),
            Text(
              l10n?.taskDetailActionBlocked ??
                  'Task Blocked • Operational Delay Logged',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: EvoraColors.error,
              ),
            ),
          ],
        ),
      );
    }

    // Default / Review / Other
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          l10n?.taskDetailActionReview ??
              'Task Submitted • Awaiting Supervisor Review',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : EvoraColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
