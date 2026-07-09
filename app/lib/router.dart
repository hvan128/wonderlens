import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_route_observer.dart';
import 'models/object_content.dart';
import 'screens/camera_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/day_detail_screen.dart';
import 'screens/discovery_reveal_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/timeline_screen.dart';
import 'services/camera_warmup.dart';
import 'ui/ui.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  observers: [appRouteObserver],
  routes: <RouteBase>[
    GoRoute(
      // Nhịp chào thương hiệu lúc mở app — tự dẫn vào '/onboarding' (lần đầu)
      // hoặc thẳng '/home'.
      path: '/splash',
      pageBuilder: (context, state) => wonderPage(
        key: state.pageKey,
        fade: true,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      // Onboarding "chụp thử" — chỉ hiện lần đầu (cờ trong AppSettings).
      path: '/onboarding',
      pageBuilder: (context, state) => wonderPage(
        key: state.pageKey,
        fade: true,
        duration: WonderTokens.durSlow,
        child: const OnboardingScreen(),
      ),
    ),
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
      // Chi tiết một ngày: nền + tiêu đề mờ dần hiện ra, còn từng vật **bay**
      // (Hero) từ thẻ ngày vào lưới. Thoát → các vật bay ngược về thẻ.
      path: '/day',
      pageBuilder: (context, state) {
        final group = state.extra as DayGroup;
        return CustomTransitionPage<void>(
          key: state.pageKey,
          // Nhẹ nhàng: chậm hơn chút + curve ease-in-out đối xứng, nền mờ vào êm.
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 440),
          // Giữ màn dưới sống (tab bar native) → hết nháy đen khi push/pop.
          opaque: false,
          child: DayDetailView(
            entries: group.entries,
            color: group.color,
            onClose: () => context.pop(),
            onCapture: () {
              // Hâm nóng khi đã cấp quyền; chưa cấp thì màn camera xin (in-context).
              CameraWarmup.instance.prewarmIfGranted();
              context.push('/camera');
            },
            onOpenEntry: (e) => context.push('/timeline', extra: e.toContent()),
          ),
          transitionsBuilder: (context, animation, secondary, child) {
            // Nội dung (tiêu đề + tem tên) mờ vào SỚM — xong trong ~nửa đầu morph
            // → chữ xuất hiện ngay từ khi bắt đầu, không đợi tới cuối. Khi thoát
            // (reverse), chữ giữ lâu rồi mới mờ ở đoạn cuối (đối xứng tự nhiên).
            final fade = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            );
            return FadeTransition(opacity: fade, child: child);
          },
        );
      },
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
        fade:
            true, // nối liền mạch với màn tách-nền (không trượt sang màn khác)
        // Nhịp chậm (durSlow) → morph Hero từ Rương bay êm, không "mạnh tay".
        duration: WonderTokens.durSlow,
        // Giữ màn dưới sống (tab bar native) → hết nháy đen khi push/pop.
        opaque: false,
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
