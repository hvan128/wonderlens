import 'package:go_router/go_router.dart';

import 'app_route_observer.dart';
import 'models/object_content.dart';
import 'screens/camera_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/discovery_reveal_screen.dart';
import 'screens/home_screen.dart';
import 'screens/timeline_screen.dart';
import 'ui/ui.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  observers: [appRouteObserver],
  routes: <RouteBase>[
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) =>
          wonderPage(key: state.pageKey, child: const HomeScreen()),
    ),
    GoRoute(
      path: '/camera',
      pageBuilder: (context, state) =>
          wonderPage(key: state.pageKey, child: const CameraScreen()),
    ),
    GoRoute(
      path: '/reveal',
      pageBuilder: (context, state) => wonderPage(
        key: state.pageKey,
        child: DiscoveryRevealScreen(content: state.extra as ObjectContent),
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
