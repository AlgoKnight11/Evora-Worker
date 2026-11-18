import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/localization/locale_provider.dart';
import '../features/history/screens/task_history_screen.dart';
import '../features/map/screens/task_map_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/onboarding/screens/language_selection_screen.dart';
import '../features/overview/screens/overview_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/shell/worker_shell_screen.dart';
import '../features/tasks/screens/tasks_screen.dart';

/// Named route paths for Evora-Workers.
class WorkerRoutes {
  WorkerRoutes._();

  static const String languageSelect = '/language-select';
  static const String overview = '/overview';
  static const String tasks = '/tasks';
  static const String map = '/map';
  static const String notifications = '/notifications';
  static const String history = '/history';
  static const String profile = '/profile';
}

/// Bridges Riverpod's `hasSelectedLanguage` flag to GoRouter without recreating
/// the router instance when the user switches languages on `/profile`.
class _RouterRefreshNotifier extends ChangeNotifier {
  void trigger() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen<bool>(
    localeProvider.select((state) => state.hasSelectedLanguage),
    (_, _) => refreshNotifier.trigger(),
  );
  ref.onDispose(refreshNotifier.dispose);

  final initialSelected = ref.read(localeProvider).hasSelectedLanguage;

  return GoRouter(
    initialLocation:
        initialSelected ? WorkerRoutes.overview : WorkerRoutes.languageSelect,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final hasSelected = ref.read(localeProvider).hasSelectedLanguage;
      final isOnLanguageSelect =
          state.matchedLocation == WorkerRoutes.languageSelect;

      if (!hasSelected && !isOnLanguageSelect) {
        return WorkerRoutes.languageSelect;
      }
      if (hasSelected && isOnLanguageSelect) {
        return WorkerRoutes.overview;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: WorkerRoutes.languageSelect,
        name: 'language-select',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return WorkerShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: My Overview
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: WorkerRoutes.overview,
                name: 'overview',
                builder: (context, state) => const OverviewScreen(),
              ),
            ],
          ),
          // Branch 1: My Tasks
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: WorkerRoutes.tasks,
                name: 'tasks',
                builder: (context, state) => const TasksScreen(),
              ),
            ],
          ),
          // Branch 2: Task Map
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: WorkerRoutes.map,
                name: 'map',
                builder: (context, state) => const TaskMapScreen(),
              ),
            ],
          ),
          // Branch 3: Notifications
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: WorkerRoutes.notifications,
                name: 'notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          // Branch 4: Task History
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: WorkerRoutes.history,
                name: 'history',
                builder: (context, state) => const TaskHistoryScreen(),
              ),
            ],
          ),
          // Branch 5: Profile & Help
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: WorkerRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
