// Onboarding "chụp thử" đi ĐÚNG luồng thật: ngắm → chụp → CaptureDissolve
// (tan biến + "đang dựng") → tên vật + nút → ✓ mở TimelineScreen thật → thoát
// hành trình = xong onboarding. Giọng kể tiêm fake như timeline_test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import 'package:wonderlens/data/app_settings.dart';
import 'package:wonderlens/screens/onboarding_screen.dart';
import 'package:wonderlens/screens/timeline_screen.dart';
import 'package:wonderlens/services/narration_service.dart';
import 'package:wonderlens/ui/ui.dart';

/// Giọng kể giả: "đọc xong" tức thì để timeline auto-advance tất định.
class _FakeNarration implements NarrationService {
  final List<String> spoken = <String>[];

  @override
  Future<void> speak(String text) {
    spoken.add(text);
    return Future<void>.value();
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

GoRouter _router(NarrationService narration) => GoRouter(
  initialLocation: '/onboarding',
  routes: <RouteBase>[
    GoRoute(
      path: '/onboarding',
      // buildBeat zero: nhịp "đang dựng" chạy trong runAsync (event loop
      // thật) nên phải kết thúc ngay trong cửa sổ đó, không đợi fake pump.
      builder: (context, state) =>
          OnboardingScreen(narration: narration, buildBeat: Duration.zero),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('HOME_STUB'))),
    ),
  ],
);

/// disableAnimations như timeline_test: _StoryScrim bỏ flutter_animate delay
/// (Timer không huỷ được) → teardown không treo; CaptureDissolve rút intro.
Widget _host(NarrationService narration) => MaterialApp.router(
  routerConfig: _router(narration),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
);

Future<void> _pumpOnboarding(WidgetTester tester, NarrationService n) async {
  await tester.pumpWidget(_host(n));
  await tester.pump();
  expect(find.text('Đố bé biết chiếc cốc này từ đâu tới?'), findsOneWidget);
}

/// Chạm nút khẩu độ (chụp tức thì như camera) và pump tới khi có kết quả.
/// Tap phải nằm TRONG runAsync: chuỗi _capture (rootBundle + decode ảnh) là
/// I/O engine thật, kẹt vĩnh viễn dưới fake zone của testWidgets.
Future<void> _captureToResult(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.byType(ApertureCaptureButton), warnIfMissed: false);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  });
  await tester.pump();
  expect(find.byType(CaptureDissolve), findsOneWidget);

  // Panel kết quả trượt vào (buildBeat zero → title có ngay từ frame đầu).
  await tester.pump(const Duration(milliseconds: 700));
  // Tên vật kiểu sticker chữ = 2 lớp Text (stroke + fill).
  expect(find.text('Cốc giấy'), findsNWidgets(2));
}

void main() {
  late _MemBox box;
  setUp(() {
    box = _MemBox();
    AppSettings.debugSetBox(box);
  });
  tearDown(() {
    AppSettings.debugOnboardingSeenOverride = null;
    AppSettings.debugSetBox(null);
  });

  testWidgets('Chụp thử → tan biến → tên vật, ✓ mở hành trình thật', (
    WidgetTester tester,
  ) async {
    final n = _FakeNarration();
    await _pumpOnboarding(tester, n);
    await _captureToResult(tester);

    // ✓ (Mở hành trình) → TimelineScreen thật nhúng same-screen như camera.
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(TimelineScreen), findsOneWidget);
    // Chưa xem xong hành trình → CHƯA đánh dấu đã xem onboarding.
    expect(box.get('onboarding_seen'), isNot(isTrue));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Nút soi lại trên kết quả → quay về nhịp ngắm', (
    WidgetTester tester,
  ) async {
    final n = _FakeNarration();
    await _pumpOnboarding(tester, n);
    await _captureToResult(tester);

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // Overlay tan biến đã rời cây → lại thấy nhịp ngắm, chụp lại được.
    expect(find.byType(CaptureDissolve), findsNothing);
    expect(find.text('Đố bé biết chiếc cốc này từ đâu tới?'), findsOneWidget);

    await _captureToResult(tester);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"Bỏ qua" đi thẳng về trang chủ + persist cờ', (
    WidgetTester tester,
  ) async {
    final n = _FakeNarration();
    await _pumpOnboarding(tester, n);

    await tester.tap(find.text('Bỏ qua'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('HOME_STUB'), findsOneWidget);
    // Hợp đồng "chỉ hiện đúng một lần": cờ phải được ghi bền vào box.
    expect(box.get('onboarding_seen'), isTrue);

    await tester.pumpWidget(const SizedBox());
  });
}

/// Box Hive giả in-memory — chỉ get/put mà AppSettings dùng (Hive file thật
/// treo dưới FakeAsync của testWidgets).
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
