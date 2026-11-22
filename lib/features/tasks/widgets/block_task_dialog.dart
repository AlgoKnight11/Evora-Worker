import 'package:flutter/material.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Modal bottom sheet for structured operational blocker reporting.
/// Synchronizes with municipal dispatch and citizen tracking as an operational delay.
class BlockTaskDialog extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const BlockTaskDialog({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  static Future<({BlockReason reason, String? note})?> show(
    BuildContext context, {
    required String taskId,
    required String taskTitle,
  }) {
    return showModalBottomSheet<({BlockReason reason, String? note})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlockTaskDialog(
        taskId: taskId,
        taskTitle: taskTitle,
      ),
    );
  }

  @override
  State<BlockTaskDialog> createState() => _BlockTaskDialogState();
}

class _BlockTaskDialogState extends State<BlockTaskDialog> {
  BlockReason _selectedReason = BlockReason.accessRestricted;
  final TextEditingController _noteController = TextEditingController();
  bool _showValidationWarning = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final note = _noteController.text.trim();
    if (_selectedReason == BlockReason.other && note.isEmpty) {
      setState(() => _showValidationWarning = true);
      return;
    }

    Navigator.of(context).pop((
      reason: _selectedReason,
      note: note.isNotEmpty ? note : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final reasons = [
      (
        BlockReason.accessRestricted,
        l10n.taskDetailBlockReasonAccess,
        Icons.lock_outline_rounded,
      ),
      (
        BlockReason.weatherCondition,
        l10n.taskDetailBlockReasonWeather,
        Icons.cloudy_snowing,
      ),
      (
        BlockReason.equipmentFailure,
        l10n.taskDetailBlockReasonEquipment,
        Icons.handyman_outlined,
      ),
      (
        BlockReason.materialUnavailable,
        l10n.taskDetailBlockReasonMaterial,
        Icons.inventory_2_outlined,
      ),
      (
        BlockReason.awaitingAuthority,
        l10n.taskDetailBlockReasonAuthority,
        Icons.policy_outlined,
      ),
      (
        BlockReason.unsafeSite,
        l10n.taskDetailBlockReasonSafety,
        Icons.warning_amber_rounded,
      ),
      (
        BlockReason.other,
        l10n.taskDetailBlockReasonOther,
        Icons.more_horiz_rounded,
      ),
    ];

    return Material(
      color: isDark ? const Color(0xFF14241B) : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
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
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFFCBD5E1),
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        color: Color(0xFFD97706),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.taskDetailBlockDialogTitle,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : EvoraColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.taskTitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: EvoraColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Informational Subtitle
                Text(
                  l10n.taskDetailBlockDialogDesc,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),

                // Safety Alert Warning Box if unsafeSite selected
                if (_selectedReason == BlockReason.unsafeSite) ...[
                  Container(
                    key: const Key('alert_unsafe_site_warning'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.emergency_rounded,
                          color: EvoraColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.taskDetailSafetyCriticalAlert,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF991B1B),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Reason Selection Radio Tiles
                ...reasons.map((item) {
                  final (reason, label, icon) = item;
                  final isSelected = _selectedReason == reason;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: Key('block_reason_${reason.value}'),
                        onTap: () {
                          setState(() {
                            _selectedReason = reason;
                            _showValidationWarning = false;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF2A2415)
                                    : const Color(0xFFFFFBEB))
                                : (isDark
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD97706)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                size: 18,
                                color: isSelected
                                    ? const Color(0xFFD97706)
                                    : (isDark
                                        ? Colors.white70
                                        : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? (isDark
                                            ? Colors.white
                                            : const Color(0xFF92400E))
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.9)
                                            : EvoraColors.onSurface),
                                  ),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFD97706)
                                        : (isDark
                                            ? Colors.white38
                                            : const Color(0xFF94A3B8)),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD97706),
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

                // Note Text Field
                Text(
                  l10n.taskDetailBlockNoteLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _showValidationWarning
                        ? EvoraColors.error
                        : (isDark ? Colors.white70 : EvoraColors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('input_block_note'),
                  controller: _noteController,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.white : EvoraColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.taskDetailBlockNoteHint,
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _showValidationWarning
                            ? EvoraColors.error
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFCBD5E1)),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _showValidationWarning
                            ? EvoraColors.error
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : const Color(0xFFCBD5E1)),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD97706),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                if (_showValidationWarning) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'An explanation is required when selecting "Other".',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: EvoraColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Action Buttons: Cancel and Confirm Block
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        key: const Key('btn_cancel_block_task'),
                        onPressed: () => Navigator.of(context).pop(),
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
                          l10n.tasksCancel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        key: const Key('btn_confirm_block_task'),
                        onPressed: _onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.block_rounded, size: 18),
                        label: Text(
                          l10n.taskDetailBlockConfirm,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
