import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Modal dialog enforcing structured municipal decline reasons.
class DeclineTaskDialog extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const DeclineTaskDialog({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  static Future<({DeclineReason reason, String? note})?> show(
    BuildContext context, {
    required String taskId,
    required String taskTitle,
  }) {
    return showModalBottomSheet<({DeclineReason reason, String? note})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeclineTaskDialog(
        taskId: taskId,
        taskTitle: taskTitle,
      ),
    );
  }

  @override
  State<DeclineTaskDialog> createState() => _DeclineTaskDialogState();
}

class _DeclineTaskDialogState extends State<DeclineTaskDialog> {
  DeclineReason _selectedReason = DeclineReason.workloadConflict;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final reasons = [
      (DeclineReason.outOfArea, l10n.tasksDeclineReasonOutOfArea, Icons.wrong_location_outlined),
      (DeclineReason.skillMismatch, l10n.tasksDeclineReasonSkillMismatch, Icons.build_circle_outlined),
      (DeclineReason.workloadConflict, l10n.tasksDeclineReasonWorkload, Icons.pending_actions_outlined),
      (DeclineReason.equipmentUnavailable, l10n.tasksDeclineReasonEquipment, Icons.handyman_outlined),
      (DeclineReason.safetyConcern, l10n.tasksDeclineReasonSafety, Icons.warning_amber_rounded),
      (DeclineReason.other, l10n.tasksDeclineReasonOther, Icons.help_outline_rounded),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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

            // Header Row: Title & Warning Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EvoraColors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_return_outlined,
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
                        l10n.tasksDeclineDialogTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        widget.taskTitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Description text
            Text(
              l10n.tasksDeclineDialogDesc,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),

            // Decline Reason Radio Items
            ...reasons.map((item) {
              final isSelected = _selectedReason == item.$1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: isSelected
                      ? EvoraColors.primary.withValues(alpha: 0.08)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    key: Key('decline_reason_${item.$1.value}'),
                    onTap: () => setState(() => _selectedReason = item.$1),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            item.$3,
                            size: 18,
                            color: isSelected ? EvoraColors.primary : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.$2,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? EvoraColors.primary : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? EvoraColors.primary : const Color(0xFF94A3B8),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: EvoraColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),

            // Optional Note Text Field
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: l10n.tasksDeclineNotePlaceholder,
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      minimumSize: const Size(0, AppConstants.minTouchTargetSize),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(l10n.tasksCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('btn_confirm_decline_submit'),
                    onPressed: () {
                      Navigator.of(context).pop((
                        reason: _selectedReason,
                        note: _noteController.text.trim().isEmpty
                            ? null
                            : _noteController.text.trim(),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EvoraColors.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, AppConstants.minTouchTargetSize),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.tasksDeclineConfirm,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
