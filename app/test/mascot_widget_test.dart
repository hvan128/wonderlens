import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderlens/ui/ui.dart';

/// Kiểm tra [WonderMascot] dựng + chạy chuyển động cho mọi mood mà không ném lỗi
/// runtime (Ticker, Transform lồng, Fx painter, cross-fade khi đổi mood). Asset
/// ảnh không nạp trong môi trường test → widget rơi về fallback qua errorBuilder,
/// nên test chỉ khẳng định "không vỡ khi animate", không so pixel.
void main() {
  Widget host(MascotMood mood) => MaterialApp(
        home: Scaffold(
          body: Center(child: WonderMascot(mood: mood, size: 120)),
        ),
      );

  testWidgets('dựng + animate mọi mood không ném lỗi', (tester) async {
    for (final mood in MascotMood.values) {
      await tester.pumpWidget(host(mood));
      // Không dùng pumpAndSettle: mascot lặp ambient vô hạn nên sẽ timeout.
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 320));
      expect(find.byType(WonderMascot), findsOneWidget);
    }
  });

  testWidgets('đổi mood kích cross-fade, không vỡ', (tester) async {
    await tester.pumpWidget(host(MascotMood.idle));
    await tester.pump(const Duration(milliseconds: 200));
    // Đổi sang celebrate → didUpdateWidget chạy transition + hiện 2 pose.
    await tester.pumpWidget(host(MascotMood.celebrate));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(WonderMascot), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Giảm chuyển động: dựng tĩnh, không ném lỗi', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: host(MascotMood.sleepy),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(WonderMascot), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
