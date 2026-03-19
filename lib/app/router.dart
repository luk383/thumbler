import 'package:go_router/go_router.dart';

import '../features/analytics/presentation/pages/progress_analytics_page.dart';
import '../features/bookmarks/presentation/bookmarks_page.dart';
import '../features/feed/presentation/pages/feed_page.dart';
import '../features/goals/ui/goals_page.dart';
import '../features/habits/ui/habits_page.dart';
import '../features/journal/ui/journal_page.dart';
import '../features/reading/ui/reading_page.dart';
import '../features/reflection/ui/reflection_page.dart';
import '../features/today/ui/today_hub_page.dart';
import '../features/exam/presentation/pages/exam_page.dart';
import '../features/exam/presentation/pages/exam_history_page.dart';
import '../features/exam/presentation/pages/exam_result_detail_page.dart';
import '../features/exam/domain/exam_result.dart';
import '../features/achievements/ui/achievements_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/pomodoro/ui/pomodoro_page.dart';
import '../features/paywall/presentation/paywall_page.dart';
import '../features/notifications/ui/notification_settings_page.dart';
import '../features/profile/presentation/privacy_policy_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/profile/presentation/progress_share_page.dart';
import '../features/search/ui/search_page.dart';
import '../features/study/data/deck_library_storage.dart';
import '../features/study/presentation/controllers/study_controller.dart';
import '../features/study/presentation/pages/card_editor_page.dart';
import '../features/study/presentation/pages/deck_management_page.dart';
import '../features/study/presentation/pages/session_history_page.dart';
import '../features/study/presentation/pages/study_page.dart';
import 'shell_scaffold.dart';

final _deckLibraryStorage = const DeckLibraryStorage();

final appRouter = GoRouter(
  initialLocation: _deckLibraryStorage.isOnboardingComplete()
      ? '/'
      : '/onboarding',
  redirect: (context, state) {
    final completed = _deckLibraryStorage.isOnboardingComplete();
    final onOnboarding = state.matchedLocation == '/onboarding';
    if (!completed && !onOnboarding) return '/onboarding';
    if (completed && onOnboarding) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/pro',
      builder: (context, state) =>
          PaywallPage(featureName: state.uri.queryParameters['feature']),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
    GoRoute(
      path: '/share',
      builder: (context, state) => const ProgressSharePage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationSettingsPage(),
    ),
    GoRoute(
      path: '/card-editor',
      builder: (context, state) => CardEditorPage(
        existingItem: state.extra as dynamic,
      ),
    ),
    GoRoute(
      path: '/deck-management',
      builder: (context, state) => const DeckManagementPage(),
    ),
    GoRoute(
      path: '/study/history',
      builder: (context, state) => const SessionHistoryPage(),
    ),
    GoRoute(
      path: '/pomodoro',
      builder: (context, state) => const PomodoroPage(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsPage(),
    ),
    GoRoute(
      path: '/feed',
      builder: (context, state) => const FeedPage(),
    ),
    GoRoute(
      path: '/habits',
      builder: (context, state) => const HabitsPage(),
    ),
    GoRoute(
      path: '/goals',
      builder: (context, state) => const GoalsPage(),
    ),
    GoRoute(
      path: '/reflection',
      builder: (context, state) => const ReflectionPage(),
    ),
    GoRoute(
      path: '/journal',
      builder: (context, state) => const JournalPage(),
    ),
    GoRoute(
      path: '/reading',
      builder: (context, state) => const ReadingPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellScaffold(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const TodayHubPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/study',
              builder: (context, state) {
                final extra = state.extra;
                final fromExtra = extra is StudyExternalSessionRequest
                    ? extra
                    : null;

                final category = state.uri.queryParameters['category'];
                final topic = state.uri.queryParameters['topic'];
                final modeParam = state.uri.queryParameters['mode'];
                final source = state.uri.queryParameters['source'];
                final lastExamAttemptId =
                    state.uri.queryParameters['lastExamAttemptId'];
                final autostart =
                    state.uri.queryParameters['autostart'] == 'true';
                final sessionLength =
                    int.tryParse(
                      state.uri.queryParameters['sessionLength'] ?? '',
                    ) ??
                    10;
                final queueTypeParam =
                    state.uri.queryParameters['queueType'];

                final mode = modeParam == 'speed'
                    ? StudyMode.speed
                    : StudyMode.srs;

                final queueType = switch (queueTypeParam) {
                  'weak' => SessionQueueType.weak,
                  'new' => SessionQueueType.newCards,
                  'random' => SessionQueueType.random,
                  'due' => SessionQueueType.due,
                  _ => null,
                };

                final fromQuery =
                    (category != null ||
                        topic != null ||
                        modeParam != null ||
                        source != null ||
                        autostart ||
                        queueTypeParam != null)
                    ? StudyExternalSessionRequest(
                        category: category,
                        topic: topic,
                        mode: mode,
                        source: source,
                        autostart: autostart,
                        sessionLength: sessionLength,
                        lastExamAttemptId: lastExamAttemptId,
                        queueType: queueType,
                      )
                    : null;

                return StudyPage(launchRequest: fromExtra ?? fromQuery);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/exam',
              builder: (context, state) => const ExamPage(),
              routes: [
                GoRoute(
                  path: 'history',
                  builder: (context, state) => const ExamHistoryPage(),
                  routes: [
                    GoRoute(
                      path: 'detail',
                      builder: (context, state) {
                        final extra = state.extra;
                        if (extra is! ExamResult) {
                          return const ExamHistoryPage();
                        }
                        return ExamResultDetailPage(result: extra);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bookmarks',
              builder: (context, state) => const BookmarksPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: 'analytics',
                  builder: (context, state) => const ProgressAnalyticsPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
