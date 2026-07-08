// Smoke test cho WonderLens: app dựng được, splash rẽ nhánh đúng trên
// appRouter THẬT (không stub) cho cả hai chiều của cờ onboarding.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wonderlens/data/app_settings.dart';
import 'package:wonderlens/main.dart';
import 'package:wonderlens/router.dart';

/// appRouter là global final — giữ vị trí giữa các test, phải đưa về /splash
/// trước mỗi lần kiểm tra luồng khởi động.
Future<void> _bootAtSplash(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: WonderLensApp()));
  await tester.pump();
  appRouter.go('/splash');
  await tester.pump();
  // Nhịp chào thương hiệu hiện trước.
  expect(find.text('WonderLens'), findsOneWidget);
}

void main() {
  tearDown(() => AppSettings.debugOnboardingSeenOverride = null);

  testWidgets('Lần đầu mở app: splash dẫn vào onboarding trên appRouter thật', (
    WidgetTester tester,
  ) async {
    AppSettings.debugOnboardingSeenOverride = false;
    await _bootAtSplash(tester);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Đố bé biết chiếc cốc này từ đâu tới?'), findsOneWidget);

    // Gỡ cây widget để huỷ timer/animation của onboarding.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Đã xem onboarding: splash vào thẳng trang chủ', (
    WidgetTester tester,
  ) async {
    AppSettings.debugOnboardingSeenOverride = true;
    await _bootAtSplash(tester);

    // Qua nhịp chờ splash + chuyển trang + animation vào trang chủ.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    // Thanh tab là UITabBar native (không phải Flutter widget) → chỉ kiểm phần
    // Flutter của trang chủ.
    expect(find.text('Chạm vòng tròn để soi đồ vật'), findsOneWidget);
  });
}
