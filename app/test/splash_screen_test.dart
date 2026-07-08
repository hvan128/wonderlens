// Splash: chào thương hiệu rồi tự rẽ nhánh theo cờ onboarding; chạm để đi ngay.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:wonderlens/data/app_settings.dart';
import 'package:wonderlens/screens/splash_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('OB_STUB'))),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('HOME_STUB'))),
    ),
  ],
);

Future<void> _pumpSplash(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
  await tester.pump();
  expect(find.text('WonderLens'), findsOneWidget);
}

void main() {
  tearDown(() => AppSettings.debugOnboardingSeenOverride = null);

  testWidgets('Lần đầu (chưa xem onboarding) → dẫn vào /onboarding', (
    WidgetTester tester,
  ) async {
    AppSettings.debugOnboardingSeenOverride = false;
    await _pumpSplash(tester);

    await tester.pump(SplashScreen.hold + const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 700)); // chuyển trang

    expect(find.text('OB_STUB'), findsOneWidget);
  });

  testWidgets('Đã xem onboarding → vào thẳng /home', (
    WidgetTester tester,
  ) async {
    AppSettings.debugOnboardingSeenOverride = true;
    await _pumpSplash(tester);

    await tester.pump(SplashScreen.hold + const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('HOME_STUB'), findsOneWidget);
  });

  testWidgets('Chạm màn splash → đi ngay, không đợi hết nhịp chào', (
    WidgetTester tester,
  ) async {
    AppSettings.debugOnboardingSeenOverride = true;
    await _pumpSplash(tester);

    await tester.tap(find.text('WonderLens'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('HOME_STUB'), findsOneWidget);
  });
}
