import 'package:go_router/go_router.dart';

import 'models/object_content.dart';
import 'screens/camera_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/timeline_screen.dart';
import 'ui/ui.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
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
  ],
);
