import 'package:go_router/go_router.dart';
import 'package:wolf_lab/features/go/ui/go_screen.dart';
import 'package:wolf_lab/features/healthy/ui/healthy_screen.dart';
import 'package:wolf_lab/features/journey/ui/journey_screen.dart';
import 'package:wolf_lab/features/journey/ui/location_detail_screen.dart';
import 'package:wolf_lab/features/reports/ui/reports_screen.dart';
import 'package:wolf_lab/features/settings/ui/ui.dart';
import 'package:wolf_lab/features/shell/ui/waje_shell.dart';
import 'package:wolf_lab/features/training/ui/ui.dart';
import 'package:wolf_lab/features/trips/ui/ui.dart';

/// Route path constants — use these instead of raw strings.
abstract final class AppRoutes {
  static const String go = '/go';
  static const String healthy = '/healthy';
  static const String journey = '/journey';
  static const String training = '/training';
  static const String trips = '/trips';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String settingsProfile = '/settings/profile';

  // Legacy aliases
  static const String home = '/go';
  static const String nutrition = '/healthy';

  static String trainingDetail(String sessionId) => '/training/$sessionId';
  static String tripDetail(String tripId) => '/trips/$tripId';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.go,
  routes: [
    // ── Main shell with bottom nav ────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          WajeShell(navigationShell: navigationShell),
      branches: [
        // Branch 0 — GO
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.go,
              builder: (context, state) => const GoScreen(),
            ),
          ],
        ),

        // Branch 1 — HEALTHY
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.healthy,
              builder: (context, state) => const HealthyScreen(),
            ),
          ],
        ),

        // Branch 2 — JOURNEY
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.journey,
              builder: (context, state) => const JourneyScreen(),
              routes: [
                GoRoute(
                  path: 'location/:id',
                  builder: (context, state) => LocationDetailScreen(
                    locationId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── Screens pushed over the shell (full-screen) ───────────────────────────

    GoRoute(
      path: AppRoutes.training,
      builder: (context, state) => const TrainingScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => TrainingSessionDetailScreen(
            sessionId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),

    GoRoute(
      path: AppRoutes.trips,
      builder: (context, state) => const TripsScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => TripDetailScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),

    GoRoute(
      path: AppRoutes.reports,
      builder: (context, state) => const ReportsScreen(),
    ),

    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'profile',
          builder: (context, state) => const AthleteProfileScreen(),
        ),
      ],
    ),
  ],
);
