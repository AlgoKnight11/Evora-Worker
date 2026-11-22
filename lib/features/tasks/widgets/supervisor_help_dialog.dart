import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Modal bottom sheet for requesting in-task supervisor callback or equipment assistance.
/// Crucially, this acts as an in-task advisory flag without pausing active work.
class SupervisorHelpDialog extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final String? supervisorName;
  final String? supervisorPhone;

  const SupervisorHelpDialog({
    super.key,
    required this.taskId,
    required this.taskTitle,
    this.supervisorName,
    this.supervisorPhone,
  });

  static Future<({String helpType, String message})?> show(
    BuildContext context, {
    required String taskId,
    required String taskTitle,
    String? supervisorName,
    String? supervisorPhone,
  }) {
    return showModalBottomSheet<({String helpType, String message})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SupervisorHelpDialog(
        taskId: taskId,
        taskTitle: taskTitle,
        supervisorName: supervisorName,
        supervisorPhone: supervisorPhone,
      ),
    );
  }

  @override
  State<SupervisorHelpDialog> createState() => _SupervisorHelpDialogState();
}

class _SupervisorHelpDialogState extends State<SupervisorHelpDialog> {
  String _selectedType = 'callback';
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    Navigator.of(context).pop((
      helpType: _selectedType,
      message: _messageController.text.trim(),
    ));
  }

  Future<void> _callSupervisor(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final categories = [
      ('callback', l10n.taskDetailHelpTypeCallback, Icons.phone_in_talk_rounded),
      ('equipment', l10n.taskDetailHelpTypeEquipment, Icons.precision_manufacturing_rounded),
      ('manpower', l10n.taskDetailHelpTypeManpower, Icons.groups_rounded),
      ('material', l10n.taskDetailHelpTypeMaterial, Icons.handyman_rounded),
      ('other', l10n.taskDetailHelpTypeOther, Icons.more_horiz_rounded),
    ];

    return Material(
      key: const Key('sheet_supervisor_help'),
      color: isDark ? const Color(0xFF14241B) : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title and Description
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Color(0xFF0284C7),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.taskDetailHelpDialogTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : EvoraColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.taskDetailHelpDialogDesc,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : EvoraColors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Supervisor Quick Contact Card (if available)
              if (widget.supervisorPhone != null && widget.supervisorPhone!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2E25)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? EvoraColors.primary.withValues(alpha: 0.3)
                          : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 280;
                      final callButton = InkWell(
                        key: const Key('btn_call_supervisor_dialog'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _callSupervisor(widget.supervisorPhone!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: EvoraColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.call_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                l10n.taskDetailActionCallSupervisor,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_pin_rounded,
                                  color: EvoraColors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.supervisorName ?? 'Supervisor on Duty',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF166534),
                                        ),
                                      ),
                                      Text(
                                        widget.supervisorPhone!,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF15803D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: callButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          const Icon(
                            Icons.person_pin_rounded,
                            color: EvoraColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.supervisorName ?? 'Supervisor on Duty',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF166534),
                                  ),
                                ),
                                Text(
                                  widget.supervisorPhone!,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          callButton,
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Assistance Type Title
              Text(
                'Assistance Type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : EvoraColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Categories List
              ...categories.map((item) {
                final (type, label, icon) = item;
                final isSelected = _selectedType == type;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: Key('help_type_$type'),
                      onTap: () => setState(() => _selectedType = type),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                                  : const Color(0xFFF0F9FF))
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0284C7)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE2E8F0)),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 20,
                              color: isSelected
                                  ? const Color(0xFF0284C7)
                                  : (isDark
                                      ? Colors.white54
                                      : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 12),
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
                                          : const Color(0xFF0369A1))
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
                                      ? const Color(0xFF0284C7)
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
                                          color: Color(0xFF0284C7),
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

              // Notes Input
              Text(
                l10n.taskDetailHelpNoteLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : EvoraColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('input_help_message'),
                controller: _messageController,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : EvoraColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: l10n.taskDetailHelpNoteHint,
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF0284C7),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      key: const Key('btn_cancel_help'),
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
                      key: const Key('btn_submit_help'),
                      onPressed: _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        l10n.taskDetailHelpSubmit,
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
    );
  }
}
