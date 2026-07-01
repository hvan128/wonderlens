import 'package:go_router/go_router.dart';

import 'app_route_observer.dart';
import 'models/object_content.dart';
import 'screens/assembly_game_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/onboarding_screen.dart';
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
    GoRoute(
      path: '/collection',
      pageBuilder: (context, state) =>
          wonderPage(key: state.pageKey, child: const CollectionScreen()),
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
  ],
);
