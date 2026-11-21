import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/task_filter.dart';

/// Modal bottom sheet allowing multi-criteria filtering by priority, ward, and overdue SLA.
class TaskFilterSheet extends StatefulWidget {
  final TaskFilter initialFilter;
  final List<String> availableWards;

  const TaskFilterSheet({
    super.key,
    required this.initialFilter,
    this.availableWards = const ['ward-04', 'ward-05', 'ward-12', 'ward-13', 'ward-14'],
  });

  static Future<TaskFilter?> show(
    BuildContext context, {
    required TaskFilter currentFilter,
    List<String> availableWards = const ['ward-04', 'ward-05', 'ward-12', 'ward-13', 'ward-14'],
  }) {
    return showModalBottomSheet<TaskFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TaskFilterSheet(
        initialFilter: currentFilter,
        availableWards: availableWards,
      ),
    );
  }

  @override
  State<TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<TaskFilterSheet> {
  late TaskPriority? _selectedPriority;
  late String? _selectedWard;
  late bool _showOverdueOnly;

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.initialFilter.priority;
    _selectedWard = widget.initialFilter.wardId;
    _showOverdueOnly = widget.initialFilter.showOverdueOnly;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Text(
                l10n.tasksFilterSheetTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              TextButton(
                key: const Key('btn_reset_filters'),
                onPressed: () {
                  setState(() {
                    _selectedPriority = null;
                    _selectedWard = null;
                    _showOverdueOnly = false;
                  });
                },
                child: Text(
                  l10n.tasksFilterReset,
                  style: const TextStyle(
                    color: EvoraColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Priority Section
          Text(
            l10n.tasksFilterPriorityLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All Priorities'),
                selected: _selectedPriority == null,
                onSelected: (_) => setState(() => _selectedPriority = null),
              ),
              ...TaskPriority.values.map((p) {
                return ChoiceChip(
                  key: Key('filter_priority_${p.value}'),
                  label: Text(p.value),
                  selected: _selectedPriority == p,
                  onSelected: (selected) {
                    setState(() => _selectedPriority = selected ? p : null);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Ward / Service Area Section
          Text(
            l10n.tasksFilterWardLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All Wards'),
                selected: _selectedWard == null,
                onSelected: (_) => setState(() => _selectedWard = null),
              ),
              ...widget.availableWards.map((w) {
                return ChoiceChip(
                  key: Key('filter_ward_$w'),
                  label: Text(w.toUpperCase()),
                  selected: _selectedWard == w,
                  onSelected: (selected) {
                    setState(() => _selectedWard = selected ? w : null);
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 18),

          // 3. Overdue Only Toggle
          SwitchListTile(
            key: const Key('switch_overdue_only'),
            value: _showOverdueOnly,
            onChanged: (val) => setState(() => _showOverdueOnly = val),
            title: Text(
              l10n.tasksFilterOverdueOnly,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            contentPadding: EdgeInsets.zero,
            activeTrackColor: EvoraColors.primary,
          ),
          const SizedBox(height: 20),

          // 4. Apply Filters Button
          ElevatedButton(
            key: const Key('btn_apply_filters'),
            onPressed: () {
              final updated = widget.initialFilter.copyWith(
                priority: _selectedPriority,
                clearPriority: _selectedPriority == null,
                wardId: _selectedWard,
                clearWard: _selectedWard == null,
                showOverdueOnly: _showOverdueOnly,
              );
              Navigator.of(context).pop(updated);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EvoraColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, AppConstants.minTouchTargetSize),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              l10n.tasksFilterApply,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
