import 'package:animations/animations.dart';
import 'package:go_router/go_router.dart';

import 'app_route_observer.dart';
import 'models/journey_args.dart';
import 'models/object_content.dart';
import 'screens/badge_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/generating_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/share_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/video_player_screen.dart';
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
      path: '/generating',
      pageBuilder: (context, state) => wonderPage(
        key: state.pageKey,
        type: SharedAxisTransitionType.scaled,
        child: GeneratingScreen(args: state.extra as JourneyArgs?),
      ),
    ),
    GoRoute(
      path: '/video',
      pageBuilder: (context, state) => wonderPage(
        key: state.pageKey,
        type: SharedAxisTransitionType.scaled,
        child: VideoPlayerScreen(args: state.extra as JourneyArgs?),
      ),
    ),
    GoRoute(
      path: '/share',
      pageBuilder: (context, state) => wonderPage(
        key: state.pageKey,
        type: SharedAxisTransitionType.vertical,
        child: ShareScreen(args: state.extra as JourneyArgs?),
      ),
    ),
    GoRoute(
      path: '/badge',
      pageBuilder: (context, state) => wonderPage(
        key: state.pageKey,
        type: SharedAxisTransitionType.scaled,
        child: BadgeScreen(args: state.extra as JourneyArgs?),
      ),
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
  ],
);
