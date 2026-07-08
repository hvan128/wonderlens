import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderlens/ui/wonder_logo.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('nhịp gợi ý tự chạy sau 6s rồi khép lại, không ném lỗi', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(ApertureCaptureButton(size: 120, onCapture: () {})),
    );

    // Trước mốc 6s: chưa có gì đặc biệt, chỉ xoay nghỉ.
    await tester.pump(const Duration(seconds: 5));
    // Qua mốc hẹn giờ: nhịp gợi ý chạy trọn 3s rồi tự reset.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);

    // Gỡ widget để huỷ timer hẹn nhịp kế tiếp.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('chạm giữa nhịp gợi ý vẫn chạy hiệu ứng chụp và gọi onCapture', (
    tester,
  ) async {
    var captured = 0;
    await tester.pumpWidget(
      _wrap(ApertureCaptureButton(size: 120, onCapture: () => captured++)),
    );

    // Vào giữa nhịp gợi ý rồi chạm.
    await tester.pump(const Duration(milliseconds: 6500));
    await tester.tap(find.byType(ApertureCaptureButton));
    // Frame đầu là mốc t=0 của hiệu ứng chụp (dài 1300ms) — chạy hết rồi mới
    // gọi onCapture.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(captured, 0);
    await tester.pump(const Duration(milliseconds: 800));
    expect(captured, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('animateOnTap=false: không hẹn nhịp gợi ý, chạm gọi ngay', (
    tester,
  ) async {
    var captured = 0;
    await tester.pumpWidget(
      _wrap(
        ApertureCaptureButton(
          size: 120,
          animateOnTap: false,
          onCapture: () => captured++,
        ),
      ),
    );

    await tester.tap(find.byType(ApertureCaptureButton));
    await tester.pump();
    expect(captured, 1);

    // Không có timer nào chờ — pumpWidget kế tiếp không phàn nàn.
    await tester.pumpWidget(const SizedBox());
  });
}
