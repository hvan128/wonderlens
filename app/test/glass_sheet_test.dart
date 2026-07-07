// GlassSheet v2 (ADR-009): mở qua showGlassSheet, kéo xuống mạnh/fling → đóng,
// kéo nhẹ → nảy về chỗ, tap nền phía trên → đóng có animation. Spring không có
// duration cố định nên chờ theo điều kiện (pump từng bước) thay vì thời gian
// cứng; cuối mỗi test xả hết frame để không để ticker treo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/ui/glass_sheet.dart';

void main() {
  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showGlassSheet<void>(
                  context: context,
                  title: 'Sheet kính',
                  // SizedBox cho thân sheet cao ổn định — drag nhẹ 40px chắc
                  // chắn dưới ngưỡng đóng 1/3 chiều cao.
                  builder: (_) => const SizedBox(
                    height: 200,
                    child: Center(child: Text('Nội dung')),
                  ),
                ),
                child: const Text('Mở sheet'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Mở sheet'));
    await tester.pump();
    // Fade của route (160ms) + spring trượt vào — 400ms là ổn định.
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Pump từng 100ms (tối đa [max]) đến khi route sheet pop xong.
  Future<void> pumpUntilClosed(
    WidgetTester tester, {
    Duration max = const Duration(seconds: 2),
  }) async {
    var elapsed = Duration.zero;
    while (elapsed < max && find.byType(GlassSheet).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
      elapsed += const Duration(milliseconds: 100);
    }
    // Xả nốt frame fade-out của route trước khi test kết thúc.
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  }

  testWidgets('mở sheet → thấy tiêu đề và nội dung',
      (WidgetTester tester) async {
    await pumpHost(tester);
    await openSheet(tester);

    expect(find.byType(GlassSheet), findsOneWidget);
    expect(find.text('Sheet kính'), findsOneWidget);
    expect(find.text('Nội dung'), findsOneWidget);

    // Chờ spring trượt vào KẾT THÚC hẳn — không để ticker treo qua teardown.
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  });

  testWidgets('fling xuống mạnh → sheet đóng', (WidgetTester tester) async {
    await pumpHost(tester);
    await openSheet(tester);

    await tester.fling(find.text('Nội dung'), const Offset(0, 400), 2000);
    await pumpUntilClosed(tester);

    expect(find.byType(GlassSheet), findsNothing);
    expect(find.text('Nội dung'), findsNothing);
  });

  testWidgets('kéo nhẹ, velocity thấp → sheet nảy về, vẫn mở',
      (WidgetTester tester) async {
    await pumpHost(tester);
    await openSheet(tester);

    await tester.drag(find.text('Nội dung'), const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.byType(GlassSheet), findsOneWidget);
    expect(find.text('Nội dung'), findsOneWidget);
  });

  testWidgets('tap vùng nền phía trên sheet → sheet đóng',
      (WidgetTester tester) async {
    await pumpHost(tester);
    await openSheet(tester);

    // Sheet nằm đáy màn hình — điểm (400, 50) chắc chắn thuộc vùng nền.
    await tester.tapAt(const Offset(400, 50));
    await pumpUntilClosed(tester);

    expect(find.byType(GlassSheet), findsNothing);
  });
}
