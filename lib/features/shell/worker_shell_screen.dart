import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/evora_colors.dart';
import '../../../core/widgets/sync_status_pill.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Adaptive shell hosting all 6 Field Worker Portal destinations:
/// Branch 0: My Overview (/overview)
/// Branch 1: My Tasks (/tasks)
/// Branch 2: Task Map (/map)
/// Branch 3: Notifications (/notifications)
/// Branch 4: Task History (/history)
/// Branch 5: Profile & Help (/profile)
class WorkerShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const WorkerShellScreen({
    super.key,
    required this.navigationShell,
  });

  // Maps the 5 mobile bottom-bar slots to StatefulNavigationShell branch indices.
  // Branch 3 (Notifications) is accessible via the persistent top AppBar bell on mobile,
  // and directly in the NavigationRail on tablet/desktop screens.
  static const List<int> _mobileBarBranchIndices = [0, 1, 2, 4, 5];

  void _goBranch(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  String _currentScreenTitle(AppLocalizations l10n, int index) {
    return switch (index) {
      0 => l10n.navOverviewFull,
      1 => l10n.navTasksFull,
      2 => l10n.navMapFull,
      3 => l10n.navNotificationsFull,
      4 => l10n.navHistoryFull,
      5 => l10n.navProfileFull,
      _ => AppConstants.appName,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = navigationShell.currentIndex;
    final isWide = MediaQuery.sizeOf(context).width >= 680;

    final mobileSelectedIndex = _mobileBarBranchIndices.indexOf(currentIndex);
    final isNotificationsActive = currentIndex == 3;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              AppConstants.leafBadgeAsset,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.eco_rounded,
                size: 24,
                color: EvoraColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentScreenTitle(l10n, currentIndex),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EvoraColors.primary,
                          letterSpacing: 0.3,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const SyncStatusPill(),
          const SizedBox(width: 6),
          if (!isWide)
            IconButton(
              key: const Key('nav_notifications_button'),
              tooltip: l10n.navNotificationsFull,
              onPressed: () => _goBranch(3),
              icon: Icon(
                isNotificationsActive
                    ? Icons.notifications_rounded
                    : Icons.notifications_outlined,
                color: isNotificationsActive
                    ? EvoraColors.primary
                    : EvoraColors.onSurface,
              ),
            ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: EvoraColors.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: _goBranch,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: EvoraColors.surfaceContainerLowest,
                  indicatorColor:
                      EvoraColors.secondaryContainer.withValues(alpha: 0.45),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: const Icon(Icons.dashboard_rounded),
                      label: Text(l10n.navOverview),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.assignment_outlined),
                      selectedIcon: const Icon(Icons.assignment_rounded),
                      label: Text(l10n.navTasks),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.map_outlined),
                      selectedIcon: const Icon(Icons.map_rounded),
                      label: Text(l10n.navMap),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.notifications_outlined),
                      selectedIcon: const Icon(Icons.notifications_rounded),
                      label: Text(l10n.navNotifications),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.history_outlined),
                      selectedIcon: const Icon(Icons.history_rounded),
                      label: Text(l10n.navHistory),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_outline_rounded),
                      selectedIcon: const Icon(Icons.person_rounded),
                      label: Text(l10n.navProfile),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: navigationShell),
              ],
            )
          : navigationShell,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: mobileSelectedIndex >= 0 ? mobileSelectedIndex : 0,
              onDestinationSelected: (slotIndex) {
                _goBranch(_mobileBarBranchIndices[slotIndex]);
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard_rounded),
                  label: l10n.navOverview,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.assignment_outlined),
                  selectedIcon: const Icon(Icons.assignment_rounded),
                  label: l10n.navTasks,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.map_outlined),
                  selectedIcon: const Icon(Icons.map_rounded),
                  label: l10n.navMap,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history_outlined),
                  selectedIcon: const Icon(Icons.history_rounded),
                  label: l10n.navHistory,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: l10n.navProfile,
                ),
              ],
            ),
    );
  }
}
