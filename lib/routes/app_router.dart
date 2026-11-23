import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/localization/locale_provider.dart';
import '../core/services/notification_service.dart';
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
import '../features/splash/screens/splash_screen.dart';
import '../features/tasks/screens/task_detail_screen.dart';
import '../features/tasks/screens/tasks_screen.dart';

/// Named route paths for Evora-Workers.
class WorkerRoutes {
  WorkerRoutes._();

  static const String splash = '/splash';
  static const String languageSelect = '/language-select';
  static const String login = '/login';
  static const String otpVerify = '/otp-verify';
  static const String overview = '/overview';
  static const String tasks = '/tasks';
  static String taskDetail(String taskId) => '/tasks/$taskId';
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

/// Provider for GoRouter's initial location (defaults to [WorkerRoutes.splash]).
/// Tests can override this provider to bypass splash when testing child screens directly.
final appRouterInitialLocationProvider = Provider<String>((ref) {
  return WorkerRoutes.splash;
});

/// Global navigator key for out-of-context router interactions like notification taps.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  // Wire notification tap navigation to task detail screen
  NotificationService.instance.onTaskSelected = (taskId) {
    rootNavigatorKey.currentContext?.go(WorkerRoutes.taskDetail(taskId));
  };

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

  final initialLocation = ref.watch(appRouterInitialLocationProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final hasSelectedLanguage =
          ref.read(localeProvider).hasSelectedLanguage;
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;

      final isOnSplash = location == WorkerRoutes.splash;
      final isOnLanguageSelect = location == WorkerRoutes.languageSelect;
      final isOnLogin = location == WorkerRoutes.login;
      final isOnOtpVerify = location == WorkerRoutes.otpVerify;
      final isAuthRoute = isOnLogin || isOnOtpVerify;

      // 0. Splash screen controls its own animation and timed transition
      if (isOnSplash) {
        return null;
      }

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
        path: WorkerRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
                routes: [
                  GoRoute(
                    path: ':taskId',
                    name: 'task-detail',
                    builder: (context, state) {
                      final taskId = state.pathParameters['taskId'] ?? '';
                      return TaskDetailScreen(taskId: taskId);
                    },
                  ),
                ],
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
