import 'package:flutter/material.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../core/widgets/evora_state_view.dart';
import '../../../l10n/generated/app_localizations.dart';

enum _TaskQueueFilter { all, individual, teamPool }

/// My Tasks (`/tasks`): Active assigned, accepted, in-progress, blocked, and pending-review work.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TaskQueueFilter _selectedFilter = _TaskQueueFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            l10n.tasksSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: EvoraColors.onSurfaceVariant,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              ChoiceChip(
                label: Text(l10n.tasksFilterAll),
                selected: _selectedFilter == _TaskQueueFilter.all,
                onSelected: (_) =>
                    setState(() => _selectedFilter = _TaskQueueFilter.all),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.tasksFilterIndividual),
                selected: _selectedFilter == _TaskQueueFilter.individual,
                onSelected: (_) => setState(
                    () => _selectedFilter = _TaskQueueFilter.individual),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.tasksFilterTeamPool),
                selected: _selectedFilter == _TaskQueueFilter.teamPool,
                onSelected: (_) =>
                    setState(() => _selectedFilter = _TaskQueueFilter.teamPool),
              ),
            ],
          ),
        ),
        Expanded(
          child: EvoraStateView(
            kind: EvoraScreenStateKind.empty,
            icon: Icons.assignment_outlined,
            title: l10n.tasksEmptyTitle,
            subtitle: l10n.tasksEmptySubtitle,
          ),
        ),
      ],
    );
  }
}
