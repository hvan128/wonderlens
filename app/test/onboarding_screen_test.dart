// Onboarding "chụp thử": ngắm → chạm nút khẩu độ → thẻ khen → vào app thật.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import 'package:wonderlens/data/app_settings.dart';
import 'package:wonderlens/screens/onboarding_screen.dart';
import 'package:wonderlens/ui/ui.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/onboarding',
  routes: <RouteBase>[
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('HOME_STUB'))),
    ),
  ],
);

Future<void> _pumpOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
  await tester.pump();
  expect(find.text('Đố bé biết chiếc cốc này từ đâu tới?'), findsOneWidget);
}

/// Chạm nút khẩu độ và pump qua hiệu ứng chụp (1300ms) + thẻ khen vào.
Future<void> _captureAndReveal(WidgetTester tester) async {
  await tester.tap(find.byType(ApertureCaptureButton), warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1400));
  await tester.pump(const Duration(milliseconds: 500));
  expect(_praiseOpacity(tester), 1);
}

/// Thẻ khen luôn nằm trong cây (IgnorePointer + AnimatedOpacity) nên
/// find.text không phân biệt được trạng thái — đọc opacity đích của lớp phủ.
double _praiseOpacity(WidgetTester tester) {
  final fade = tester.widget<AnimatedOpacity>(
    find
        .ancestor(
          of: find.text('Giỏi quá, bé chụp được rồi!'),
          matching: find.byType(AnimatedOpacity),
        )
        .first,
  );
  return fade.opacity;
}

void main() {
  // Box in-memory để khoá hợp đồng persist cờ onboarding. KHÔNG dùng box Hive
  // file thật: put chạy trong zone FakeAsync của testWidgets → I/O đĩa không
  // bao giờ hoàn thành → test treo tới timeout.
  late _MemBox box;
  setUp(() {
    box = _MemBox();
    AppSettings.debugSetBox(box);
  });
  tearDown(() {
    AppSettings.debugOnboardingSeenOverride = null;
    AppSettings.debugSetBox(null);
  });

  testWidgets('Chụp thử → thẻ khen, "Bắt đầu khám phá" về home + persist cờ', (
    WidgetTester tester,
  ) async {
    await _pumpOnboarding(tester);
    expect(_praiseOpacity(tester), 0);
    await _captureAndReveal(tester);

    await tester.tap(find.text('Bắt đầu khám phá'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('HOME_STUB'), findsOneWidget);
    // Hợp đồng "chỉ hiện đúng một lần": cờ phải được ghi bền vào Hive.
    expect(box.get('onboarding_seen'), isTrue);
    expect(AppSettings.onboardingSeen, isTrue);

    // Gỡ cây widget để huỷ animation/timer còn chạy (twinkle, hint…).
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"Chụp thử lại" quay về nhịp ngắm (thẻ khen ẩn + chặn tap)', (
    WidgetTester tester,
  ) async {
    await _pumpOnboarding(tester);
    await _captureAndReveal(tester);

    await tester.tap(find.text('Chụp thử lại'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(_praiseOpacity(tester), 0);
    expect(find.text('Đố bé biết chiếc cốc này từ đâu tới?'), findsOneWidget);

    // Chụp lại được lần nữa sau khi replay.
    await _captureAndReveal(tester);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"Bỏ qua" đi thẳng về trang chủ + persist cờ', (
    WidgetTester tester,
  ) async {
    await _pumpOnboarding(tester);

    await tester.tap(find.text('Bỏ qua'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('HOME_STUB'), findsOneWidget);
    expect(box.get('onboarding_seen'), isTrue);

    await tester.pumpWidget(const SizedBox());
  });
}

/// Box Hive giả in-memory — chỉ get/put mà AppSettings dùng.
class _MemBox extends Fake implements Box {
  final Map<dynamic, dynamic> _data = <dynamic, dynamic>{};

  @override
  Future<void> put(dynamic key, dynamic value) async {
    _data[key] = value;
  }

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _data[key] ?? defaultValue;
}
