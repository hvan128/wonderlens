import 'package:go_router/go_router.dart';

import 'app_route_observer.dart';
import 'models/object_content.dart';
import 'screens/assembly_game_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/home_shell.dart';
import 'screens/material_cards_screen.dart';
import 'screens/missions_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/playground_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/timeline_screen.dart';
import 'ui/ui.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  observers: [appRouteObserver],
  routes: <RouteBase>[
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) =>
          wonderPage(key: state.pageKey, child: const OnboardingScreen()),
    ),
    // A1 — khung "nhà" bottom-nav: 2 tab Sân chơi + Bộ sưu tập. Camera & các màn
    // game/timeline là route toàn màn hình push TRÊN shell (root navigator) → phủ
    // cả bottom-nav và giữ nguyên vòng đời camera (RouteObserver).
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/playground',
              pageBuilder: (context, state) => wonderPage(
                key: state.pageKey,
                child: const PlaygroundScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/collection',
              pageBuilder: (context, state) => wonderPage(
                key: state.pageKey,
                child: const CollectionScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/camera',
      pageBuilder: (context, state) =>
          wonderPage(key: state.pageKey, child: const CameraScreen()),
    ),
    GoRoute(
      path: '/timeline',
      pageBuilder: (context, state) => wonderPage(
        key: state.pageKey,
        child: TimelineScreen(content: state.extra as ObjectContent?),
      ),
    ),
    // Mini-game gắn 1 vật vừa khám phá (TASK-018 / B) — nhận ObjectContent qua extra.
    GoRoute(
      path: '/quiz',
      pageBuilder: (context, state) => wonderPage(
        key: state.pageKey,
        child: QuizScreen(content: state.extra as ObjectContent?),
      ),
    ),
    GoRoute(
      path: '/assembly',
      pageBuilder: (context, state) => wonderPage(
        key: state.pageKey,
        child: AssemblyGameScreen(content: state.extra as ObjectContent?),
      ),
    ),
    // Nhiệm vụ khám phá (TASK-019 / D1) + Thẻ vật liệu (nền mạng lưới ADR-012).
    GoRoute(
      path: '/missions',
      pageBuilder: (context, state) =>
          wonderPage(key: state.pageKey, child: const MissionsScreen()),
    ),
    GoRoute(
      path: '/material-cards',
      pageBuilder: (context, state) =>
          wonderPage(key: state.pageKey, child: const MaterialCardsScreen()),
    ),
  ],
);
