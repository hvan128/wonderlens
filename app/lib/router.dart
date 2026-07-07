import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_route_observer.dart';
import 'models/object_content.dart';
import 'screens/camera_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/discovery_reveal_screen.dart';
import 'screens/main_shell.dart';
import 'screens/timeline_screen.dart';
import 'ui/ui.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  observers: [appRouteObserver],
  routes: <RouteBase>[
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) =>
          wonderPage(key: state.pageKey, child: const MainShell()),
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
        fade: true, // nối liền mạch với màn tách-nền (không trượt sang màn khác)
        child: TimelineScreen(content: state.extra as ObjectContent?),
      ),
    ),
    GoRoute(
      // Trượt lên từ đáy → nối liền mạch với động tác kéo modal vật lên.
      path: '/collection',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const CollectionScreen(),
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondary, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    ),
  ],
);
