import 'package:go_router/go_router.dart';

import '../features/bookmarks/presentation/bookmarks_page.dart';
import '../features/exam/presentation/pages/exam_page.dart';
import '../features/exam/presentation/pages/exam_history_page.dart';
import '../features/exam/presentation/pages/exam_result_detail_page.dart';
import '../features/exam/domain/exam_result.dart';
import '../features/feed/presentation/pages/feed_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/study/presentation/controllers/study_controller.dart';
import '../features/study/presentation/pages/study_page.dart';
import 'shell_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellScaffold(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const FeedPage()),
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

                final mode = modeParam == 'speed'
                    ? StudyMode.speed
                    : StudyMode.srs;

                final fromQuery =
                    (category != null ||
                        topic != null ||
                        modeParam != null ||
                        source != null ||
                        autostart)
                    ? StudyExternalSessionRequest(
                        category: category,
                        topic: topic,
                        mode: mode,
                        source: source,
                        autostart: autostart,
                        sessionLength: sessionLength,
                        lastExamAttemptId: lastExamAttemptId,
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
            ),
          ],
        ),
      ],
    ),
  ],
);
