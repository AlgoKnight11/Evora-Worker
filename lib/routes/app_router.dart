import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/localization/locale_provider.dart';
import '../features/auth/models/auth_state.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
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
  static const String login = '/login';
  static const String otpVerify = '/otp-verify';
  static const String overview = '/overview';
  static const String tasks = '/tasks';
  static const String map = '/map';
  static const String notifications = '/notifications';
  static const String history = '/history';
  static const String profile = '/profile';
}

/// Bridges Riverpod state changes (locale & authentication) to GoRouter
/// without recreating the router instance.
class _RouterRefreshNotifier extends ChangeNotifier {
  void trigger() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  // Listen to language selection changes
  ref.listen<bool>(
    localeProvider.select((state) => state.hasSelectedLanguage),
    (_, _) => refreshNotifier.trigger(),
  );

  // Listen to auth status changes
  ref.listen<AuthStatus>(
    authNotifierProvider.select((state) => state.status),
    (_, _) => refreshNotifier.trigger(),
  );

  ref.onDispose(refreshNotifier.dispose);

  final initialHasSelectedLanguage =
      ref.read(localeProvider).hasSelectedLanguage;
  final initialIsAuthenticated =
      ref.read(authNotifierProvider).isAuthenticated;

  String determineInitialLocation() {
    if (!initialHasSelectedLanguage) return WorkerRoutes.languageSelect;
    if (!initialIsAuthenticated) return WorkerRoutes.login;
    return WorkerRoutes.overview;
  }

  return GoRouter(
    initialLocation: determineInitialLocation(),
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final hasSelectedLanguage =
          ref.read(localeProvider).hasSelectedLanguage;
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;

      final isOnLanguageSelect = location == WorkerRoutes.languageSelect;
      final isOnLogin = location == WorkerRoutes.login;
      final isOnOtpVerify = location == WorkerRoutes.otpVerify;
      final isAuthRoute = isOnLogin || isOnOtpVerify;

      // 1. Language must be selected first
      if (!hasSelectedLanguage && !isOnLanguageSelect) {
        return WorkerRoutes.languageSelect;
      }

      // 2. If language selected but user is not authenticated
      if (hasSelectedLanguage && !isAuthenticated) {
        // Allow user on login and OTP verify screens
        if (isAuthRoute) return null;
        return WorkerRoutes.login;
      }

      // 3. If authenticated, prevent staying on language-select or auth screens
      if (isAuthenticated && (isOnLanguageSelect || isAuthRoute)) {
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
      GoRoute(
        path: WorkerRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: WorkerRoutes.otpVerify,
        name: 'otp-verify',
        builder: (context, state) => const OtpVerificationScreen(),
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
