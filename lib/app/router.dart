import 'package:go_router/go_router.dart';

import '../features/bookmarks/presentation/bookmarks_page.dart';
import '../features/feed/presentation/feed_page.dart';
import '../features/profile/presentation/profile_page.dart';
import 'shell_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellScaffold(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (context, state) => const FeedPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/bookmarks',
            builder: (context, state) => const BookmarksPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ]),
      ],
    ),
  ],
);
