import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../core/widgets/evora_state_view.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../domain/models/worker_task.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../routes/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/task_filter.dart';
import '../providers/task_providers.dart';
import '../widgets/decline_task_dialog.dart';
import '../widgets/task_card_item.dart';
import '../widgets/task_filter_sheet.dart';

/// My Tasks (`/tasks`): Real-time municipal task queue with status tabs,
/// assignment scope filter chips, instant search, multi-criteria filter sheet,
/// and contextual actions (Accept, Decline, Claim, Dismiss).
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(taskFilterProvider).searchQuery;
    if (initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(taskFilterProvider.notifier).state =
        ref.read(taskFilterProvider).copyWith(searchQuery: query.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filter = ref.watch(taskFilterProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final workerUid = ref.watch(authNotifierProvider).profile?.uid ?? '';

    final hasActiveExtraFilters =
        filter.priority != null || filter.wardId != null || filter.showOverdueOnly;

    return Scaffold(
      backgroundColor: EvoraColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Search Bar & Filter BottomSheet Trigger
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2922) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        key: const Key('tasks_search_field'),
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : EvoraColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.tasksSearchPlaceholder,
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: _clearSearch,
                                  color: const Color(0xFF64748B),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Filter Trigger with Active Counter Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: hasActiveExtraFilters
                            ? EvoraColors.primary
                            : isDark
                                ? const Color(0xFF1E2922)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          key: const Key('btn_open_filter_sheet'),
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final allTasks = tasksAsync.value ?? [];
                            final availableWards = allTasks
                                .map((t) => t.wardId)
                                .toSet()
                                .toList()
                              ..sort();

                            final newFilter = await TaskFilterSheet.show(
                              context,
                              currentFilter: filter,
                              availableWards: availableWards.isEmpty
                                  ? const ['ward-04', 'ward-05', 'ward-12', 'ward-13', 'ward-14']
                                  : availableWards,
                            );

                            if (newFilter != null) {
                              ref.read(taskFilterProvider.notifier).state = newFilter;
                            }
                          },
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasActiveExtraFilters
                                    ? EvoraColors.primary
                                    : isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: hasActiveExtraFilters
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                      if (hasActiveExtraFilters)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: EvoraColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Status Segment Ribbon (All, Assigned, Accepted, In Progress, Blocked, Review)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _StatusTabItem(
                    key: const Key('tab_status_all'),
                    label: l10n.tasksTabAll,
                    count: _countForStatus(null, tasksAsync.value, filter, workerUid),
                    isSelected: filter.statusTab == null,
                    onTap: () {
                      ref.read(taskFilterProvider.notifier).state =
                          filter.copyWith(clearStatusTab: true);
                    },
                  ),
                  const SizedBox(width: 8),
                  _StatusTabItem(
                    key: const Key('tab_status_assigned'),
                    label: l10n.tasksTabAssigned,
                    count: _countForStatus(
                        TaskStatus.assigned, tasksAsync.value, filter, workerUid),
                    isSelected: filter.statusTab == TaskStatus.assigned,
                    onTap: () {
                      ref.read(taskFilterProvider.notifier).state =
                          filter.copyWith(statusTab: TaskStatus.assigned);
                    },
                  ),
                  const SizedBox(width: 8),
                  _StatusTabItem(
                    key: const Key('tab_status_accepted'),
                    label: l10n.tasksTabAccepted,
                    count: _countForStatus(
                        TaskStatus.accepted, tasksAsync.value, filter, workerUid),
                    isSelected: filter.statusTab == TaskStatus.accepted,
                    onTap: () {
                      ref.read(taskFilterProvider.notifier).state =
                          filter.copyWith(statusTab: TaskStatus.accepted);
                    },
                  ),
                  const SizedBox(width: 8),
                  _StatusTabItem(
                    key: const Key('tab_status_in_progress'),
                    label: l10n.tasksTabInProgress,
                    count: _countForStatus(
                        TaskStatus.inProgress, tasksAsync.value, filter, workerUid),
                    isSelected: filter.statusTab == TaskStatus.inProgress,
                    onTap: () {
                      ref.read(taskFilterProvider.notifier).state =
                          filter.copyWith(statusTab: TaskStatus.inProgress);
                    },
                  ),
                  const SizedBox(width: 8),
                  _StatusTabItem(
                    key: const Key('tab_status_blocked'),
                    label: l10n.tasksTabBlocked,
                    count: _countForStatus(
                        TaskStatus.blocked, tasksAsync.value, filter, workerUid),
                    isSelected: filter.statusTab == TaskStatus.blocked,
                    onTap: () {
                      ref.read(taskFilterProvider.notifier).state =
                          filter.copyWith(statusTab: TaskStatus.blocked);
                    },
                  ),
                  const SizedBox(width: 8),
                  _StatusTabItem(
                    key: const Key('tab_status_review'),
                    label: l10n.tasksTabReview,
                    count: _countForStatus(
                        TaskStatus.submittedForReview, tasksAsync.value, filter, workerUid),
                    isSelected: filter.statusTab == TaskStatus.submittedForReview,
                    onTap: () {
                      ref.read(taskFilterProvider.notifier).state =
                          filter.copyWith(statusTab: TaskStatus.submittedForReview);
                    },
                  ),
                ],
              ),
            ),

            // 3. Assignment Scope Filter Chips (All, Individual, Team Pool)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  ChoiceChip(
                    key: const Key('chip_scope_all'),
                    label: Text(l10n.tasksFilterAll),
                    selected: filter.scope == TaskScope.all,
                    onSelected: (_) {
                      ref.read(taskFilterProvider.notifier).state =
                          filter.copyWith(scope: TaskScope.all);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    key: const Key('chip_scope_individual'),
                    label: Text(l10n.tasksFilterIndividual),
                    selected: filter.scope == TaskScope.individual,
                    onSelected: (_) {
                      ref.read(taskFilterProvider.notifier).state =
                          filter.copyWith(scope: TaskScope.individual);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    key: const Key('chip_scope_team_pool'),
                    label: Text(l10n.tasksFilterTeamPool),
                    selected: filter.scope == TaskScope.teamPool,
                    onSelected: (_) {
                      ref.read(taskFilterProvider.notifier).state =
                          filter.copyWith(scope: TaskScope.teamPool);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 4. Task Feed List or Empty State
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: EvoraColors.primary),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync_problem_rounded, size: 48, color: EvoraColors.error),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load dispatch tasks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : EvoraColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString().contains('permission-denied')
                              ? 'Dispatch access restricted. Operating in local crew mode.'
                              : '$err',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : EvoraColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.refresh(tasksStreamProvider),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EvoraColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (_) {
                  if (filteredTasks.isEmpty) {
                    final isFiltered = filter.statusTab != null ||
                        filter.scope != TaskScope.all ||
                        filter.priority != null ||
                        filter.wardId != null ||
                        filter.searchQuery.isNotEmpty ||
                        filter.showOverdueOnly;

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EvoraStateView(
                              kind: EvoraScreenStateKind.empty,
                              icon: Icons.assignment_outlined,
                              title: isFiltered
                                  ? l10n.tasksNoMatchingTitle
                                  : l10n.tasksEmptyTitle,
                              subtitle: isFiltered
                                  ? l10n.tasksNoMatchingSubtitle
                                  : l10n.tasksEmptySubtitle,
                            ),
                            if (isFiltered) ...[
                              const SizedBox(height: 12),
                              ElevatedButton(
                                key: const Key('btn_clear_all_filters'),
                                onPressed: () {
                                  _clearSearch();
                                  ref.read(taskFilterProvider.notifier).state =
                                      const TaskFilter();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EvoraColors.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(160, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(l10n.tasksFilterReset),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: EvoraColors.primary,
                    onRefresh: () async {
                      ref.invalidate(tasksStreamProvider);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filteredTasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return TaskCardItem(
                          key: Key('task_card_${task.id}'),
                          task: task,
                          onTap: () {
                            try {
                              context.go(WorkerRoutes.taskDetail(task.id));
                            } catch (_) {}
                          },
                          onClaim: task.isUnclaimedTeamPool
                              ? () => _claimTask(task.id, l10n)
                              : null,
                          onDismiss: task.isUnclaimedTeamPool
                              ? () => _dismissTask(task.id, l10n)
                              : null,
                          onAccept: task.status == TaskStatus.assigned
                              ? () => _acceptTask(task.id, l10n)
                              : null,
                          onDecline: task.status == TaskStatus.assigned
                              ? () => _showDeclineDialog(task, l10n)
                              : null,
                          onStartWork: (task.status == TaskStatus.accepted ||
                                  task.status == TaskStatus.inProgress)
                              ? () {
                                  try {
                                    context.go(WorkerRoutes.taskDetail(task.id));
                                  } catch (_) {}
                                }
                              : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countForStatus(
    TaskStatus? status,
    List<WorkerTask>? allTasks,
    TaskFilter currentFilter,
    String workerUid,
  ) {
    if (allTasks == null) return 0;
    final testFilter = currentFilter.copyWith(
      statusTab: status,
      clearStatusTab: status == null,
    );
    return allTasks.where((t) => testFilter.matches(t, workerUid)).length;
  }

  Future<void> _claimTask(String taskId, AppLocalizations l10n) async {
    final success =
        await ref.read(taskOperationsProvider.notifier).claimTeamPoolTask(taskId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? l10n.tasksClaimSuccess : 'Failed to claim task: Already claimed'),
        backgroundColor: success ? EvoraColors.primary : EvoraColors.error,
      ),
    );
  }

  Future<void> _dismissTask(String taskId, AppLocalizations l10n) async {
    final success =
        await ref.read(taskOperationsProvider.notifier).dismissPoolTask(taskId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? l10n.tasksDismissSuccess : 'Failed to dismiss task'),
      ),
    );
  }

  Future<void> _acceptTask(String taskId, AppLocalizations l10n) async {
    final success =
        await ref.read(taskOperationsProvider.notifier).acceptTask(taskId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? l10n.tasksAcceptSuccess : 'Failed to accept task'),
        backgroundColor: success ? EvoraColors.primary : EvoraColors.error,
      ),
    );
  }

  Future<void> _showDeclineDialog(WorkerTask task, AppLocalizations l10n) async {
    final result = await DeclineTaskDialog.show(
      context,
      taskId: task.id,
      taskTitle: task.title,
    );

    if (result != null) {
      final success = await ref.read(taskOperationsProvider.notifier).declineTask(
            taskId: task.id,
            reason: result.reason,
            note: result.note,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.tasksDeclineSuccess : 'Failed to decline task'),
          backgroundColor: success ? EvoraColors.primary : EvoraColors.error,
        ),
      );
    }
  }
}

class _StatusTabItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusTabItem({
    super.key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? EvoraColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? EvoraColors.primary : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
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
