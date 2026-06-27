import 'package:go_router/go_router.dart';

import 'models/object_content.dart';
import 'screens/camera_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/timeline_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/camera',
      builder: (context, state) => const CameraScreen(),
    ),
    GoRoute(
      path: '/timeline',
      builder: (context, state) =>
          TimelineScreen(content: state.extra as ObjectContent?),
    ),
    GoRoute(
      path: '/collection',
      builder: (context, state) => const CollectionScreen(),
    ),
  ],
);
