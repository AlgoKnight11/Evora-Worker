import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Modal bottom sheet for reporting high-priority out-of-band safety hazards
/// and immediate access to emergency services (112, 108, 101, municipal helpline).
class SafetyIncidentDialog extends StatefulWidget {
  final String? taskId;
  final String? taskTitle;
  final double? latitude;
  final double? longitude;

  const SafetyIncidentDialog({
    super.key,
    this.taskId,
    this.taskTitle,
    this.latitude,
    this.longitude,
  });

  static Future<({String hazardType, String riskLevel, String description})?> show(
    BuildContext context, {
    String? taskId,
    String? taskTitle,
    double? latitude,
    double? longitude,
  }) {
    return showModalBottomSheet<({String hazardType, String riskLevel, String description})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafetyIncidentDialog(
        taskId: taskId,
        taskTitle: taskTitle,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  @override
  State<SafetyIncidentDialog> createState() => _SafetyIncidentDialogState();
}

class _SafetyIncidentDialogState extends State<SafetyIncidentDialog> {
  String _selectedHazard = 'electrical_hazard';
  String _selectedRisk = 'critical';
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _dialEmergency(String number) async {
    final clean = number.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final hazards = [
      ('electrical_hazard', l10n.safetyHazardElectrical, Icons.flash_on_rounded),
      ('structural_collapse', l10n.safetyHazardStructural, Icons.domain_disabled_rounded),
      ('gas_chemical_leak', l10n.safetyHazardGasChemical, Icons.waves_rounded),
      ('violent_obstruction', l10n.safetyHazardViolence, Icons.shield_rounded),
      ('traffic_collision', l10n.safetyHazardTraffic, Icons.car_crash_rounded),
      ('other_hazard', l10n.safetyHazardOther, Icons.warning_amber_rounded),
    ];

    return Material(
      key: const Key('sheet_safety_incident'),
      color: isDark ? const Color(0xFF14241B) : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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
                const SizedBox(height: 16),

                // Title Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.emergency_rounded,
                        color: Color(0xFFDC2626),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.safetyDialogTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : EvoraColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.safetyDialogDesc,
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

                // 1. Instant Emergency Speed Dial Panel
                Container(
                  key: const Key('panel_emergency_speed_dial'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_in_talk_rounded,
                              size: 16, color: Color(0xFFDC2626)),
                          const SizedBox(width: 6),
                          Text(
                            l10n.safetyEmergencySpeedDial,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _EmergencyChip(
                            key: const Key('btn_dial_112'),
                            label: l10n.safetyEmergencyCallPolice,
                            icon: Icons.local_police_rounded,
                            onTap: () => _dialEmergency('112'),
                          ),
                          _EmergencyChip(
                            key: const Key('btn_dial_108'),
                            label: l10n.safetyEmergencyCallAmbulance,
                            icon: Icons.medical_services_rounded,
                            onTap: () => _dialEmergency('108'),
                          ),
                          _EmergencyChip(
                            key: const Key('btn_dial_101'),
                            label: l10n.safetyEmergencyCallFire,
                            icon: Icons.local_fire_department_rounded,
                            onTap: () => _dialEmergency('101'),
                          ),
                          _EmergencyChip(
                            key: const Key('btn_dial_control_room'),
                            label: l10n.safetyEmergencyCallMunicipal,
                            icon: Icons.support_agent_rounded,
                            onTap: () => _dialEmergency('1916'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Risk Level Segmented Buttons
                Text(
                  l10n.safetyRiskLevelTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : EvoraColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: const Key('risk_critical'),
                        onTap: () => setState(() => _selectedRisk = 'critical'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedRisk == 'critical'
                                ? const Color(0xFFDC2626)
                                : (isDark ? const Color(0xFF1E2922) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedRisk == 'critical'
                                  ? const Color(0xFFDC2626)
                                  : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.safetyRiskCritical,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _selectedRisk == 'critical'
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : EvoraColors.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        key: const Key('risk_high'),
                        onTap: () => setState(() => _selectedRisk = 'high'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedRisk == 'high'
                                ? const Color(0xFFEA580C)
                                : (isDark ? const Color(0xFF1E2922) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedRisk == 'high'
                                  ? const Color(0xFFEA580C)
                                  : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.safetyRiskHigh,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _selectedRisk == 'high'
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : EvoraColors.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 3. Hazard Classification Options
                Text(
                  l10n.safetyHazardTypeTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : EvoraColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...hazards.map((item) {
                  final (type, label, icon) = item;
                  final isSelected = _selectedHazard == type;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: Key('hazard_type_$type'),
                        onTap: () => setState(() => _selectedHazard = type),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFDC2626)
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
                                    ? const Color(0xFFDC2626)
                                    : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isDark ? Colors.white : EvoraColors.onSurface,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: Color(0xFFDC2626),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),

                // 4. Incident Description Input (Mandatory)
                Text(
                  l10n.safetyNotesLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : EvoraColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('input_safety_description'),
                  controller: _notesController,
                  maxLines: 3,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please describe the safety hazard for dispatch.';
                    }
                    return null;
                  },
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : EvoraColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.safetyNotesHint,
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Actions: Cancel & Submit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        key: const Key('btn_cancel_safety'),
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EvoraColors.onSurfaceVariant,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : const Color(0xFFCBD5E1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        key: const Key('btn_submit_safety'),
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            Navigator.of(context).pop((
                              hazardType: _selectedHazard,
                              riskLevel: _selectedRisk,
                              description: _notesController.text.trim(),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          l10n.safetySubmitButton,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
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

class _EmergencyChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _EmergencyChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFCA5A5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFDC2626)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF991B1B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
