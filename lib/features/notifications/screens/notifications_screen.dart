import 'package:flutter/material.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../core/widgets/evora_state_view.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Notifications (`/notifications`): Assignments, SLA reminders, supervisor review alerts.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            l10n.notificationsSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: EvoraColors.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: EvoraStateView(
            kind: EvoraScreenStateKind.empty,
            icon: Icons.notifications_none_rounded,
            title: l10n.notificationsEmptyTitle,
            subtitle: l10n.notificationsEmptySubtitle,
          ),
        ),
      ],
    );
  }
}
