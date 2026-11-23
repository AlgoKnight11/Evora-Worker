import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../core/widgets/evora_state_view.dart';
import '../../../domain/enums/worker_enums.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../routes/app_router.dart';
import '../providers/notification_providers.dart';

/// Notifications (`/notifications`): System permission controls, real-time citizen
/// dispatch alerts, condition analysis previews, and emergency SLA reminders.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPermissionGranted = ref.watch(notificationPermissionProvider);
    final notifications = ref.watch(dispatchNotificationProvider);

    return Scaffold(
      backgroundColor: EvoraColors.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.notificationsSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: EvoraColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  // System Permission Status Card
                  _buildPermissionCard(context, ref, l10n, isPermissionGranted),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.notifRecentDispatches,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: EvoraColors.onSurface,
                              ),
                        ),
                      ),
                      if (notifications.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            ref
                                .read(dispatchNotificationProvider.notifier)
                                .clearAll();
                          },
                          child: Text(
                            l10n.authCancel,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (notifications.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EvoraStateView(
                kind: EvoraScreenStateKind.empty,
                icon: Icons.notifications_none_rounded,
                title: l10n.notificationsEmptyTitle,
                subtitle: l10n.notificationsEmptySubtitle,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = notifications[index];
                    return _buildNotificationCard(context, ref, item);
                  },
                  childCount: notifications.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool isGranted,
  ) {
    if (isGranted) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: EvoraColors.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        color: EvoraColors.primaryContainer.withValues(alpha: 0.25),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    color: EvoraColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.notifPermissionActive,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: EvoraColors.primary,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: EvoraColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ON',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.notifPermissionActiveDesc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EvoraColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('notif_test_button'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: EvoraColors.primary,
                  side: const BorderSide(color: EvoraColors.primary),
                ),
                onPressed: () async {
                  await ref
                      .read(notificationPermissionProvider.notifier)
                      .sendTestNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.notifTestSuccess),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(l10n.notifTestButton),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: EvoraColors.amberAlert.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        color: EvoraColors.warningContainer.withValues(alpha: 0.25),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notification_important_rounded,
                    color: EvoraColors.amberAlert,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.notifPermissionDisabled,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: EvoraColors.amberAlert,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.notifPermissionDisabledDesc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EvoraColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('notif_enable_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: EvoraColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  final granted = await ref
                      .read(notificationPermissionProvider.notifier)
                      .requestPermission();
                  if (context.mounted && granted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.notifPermissionActive),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notifications_active_rounded, size: 16),
                label: Text(l10n.notifEnableButton),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    WorkerNotificationItem item,
  ) {
    final priorityColor = switch (item.priority) {
      TaskPriority.p1 => EvoraColors.error,
      TaskPriority.p2 => const Color(0xFFE65100),
      TaskPriority.p3 => EvoraColors.primary,
      TaskPriority.p4 => EvoraColors.outline,
    };

    final timeStr =
        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: EvoraColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(dispatchNotificationProvider.notifier).markAsRead(item.id);
          context.go(WorkerRoutes.taskDetail(item.taskId));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: priorityColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${item.priority.value} PRIORITY',
                      style: TextStyle(
                        color: priorityColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EvoraColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                item.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EvoraColors.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: EvoraColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'View & Accept Task',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EvoraColors.primary,
                          fontWeight: FontWeight.w700,
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
