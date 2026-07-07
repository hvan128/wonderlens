// GlassPanel v2 (ADR-009): logic hình học nằm trọn trong GlassPanelController
// (test thuần Dart, không render) + hành vi kéo/thả, spring về biên, z-order
// và resize qua widget test. Cửa sổ test mặc định 800×600.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/theme/wonder_tokens.dart';
import 'package:wonderlens/ui/glass_panel.dart';

void main() {
  // Margin mặc định của controller = WonderTokens.panelSnapMargin (12).
  const margin = WonderTokens.panelSnapMargin;

  group('GlassPanelController — hình học thuần (không render)', () {
    GlassPanelController makeController({
      Offset position = const Offset(100, 100),
    }) =>
        GlassPanelController(position: position, size: const Size(300, 240))
          ..area = const Size(800, 600);

    test('clampToLegal kẹp vị trí vào legalRect sau khi set area', () {
      final c = makeController();
      // Panel 300×240 trong vùng 800×600: x ∈ [12, 488], y ∈ [12, 348].
      expect(c.legalRect, const Rect.fromLTRB(margin, margin, 488, 348));
      expect(c.clampToLegal(const Offset(-50, 700)), const Offset(margin, 348));
      expect(c.clampToLegal(const Offset(700, -50)), const Offset(488, margin));
      // Vị trí đã hợp lệ thì giữ nguyên.
      expect(c.clampToLegal(const Offset(100, 100)), const Offset(100, 100));
    });

    test('dragBy vượt biên bị rubber-band cản nửa phần dư', () {
      final c = makeController();
      c.dragBy(const Offset(-200, 0));
      // raw.dx = -100 vượt biên trái 12 → chỉ đi nửa phần dư:
      // 12 + (-100 - 12) / 2 = -44.
      expect(c.position.dx, closeTo(-44, 1e-9));
      expect(c.position.dx, lessThan(margin)); // đã vượt ra ngoài biên
      expect(c.position.dx, greaterThan(-100)); // nhưng ít hơn delta thật
      expect(c.position.dy, 100); // trục còn trong biên không bị cản
    });

    test('resizeBy góc dưới-phải kẹp ở minSize, không âm, không throw', () {
      final c = makeController(position: const Offset(40, 40));
      c.resizeBy(const Offset(-500, -500), PanelEdge.bottomRight);
      expect(c.size, c.minSize);
      expect(c.size.width, greaterThan(0));
      expect(c.size.height, greaterThan(0));
      // Góc trên-trái (neo của bottomRight) đứng yên.
      expect(c.position, const Offset(40, 40));
    });

    test('resizeBy góc trên-trái neo góc dưới-phải đứng yên', () {
      final c = makeController();
      final anchor = c.rect.bottomRight; // (400, 340)
      c.resizeBy(const Offset(40, 30), PanelEdge.topLeft);
      expect(c.rect.bottomRight, anchor);
      expect(c.position, const Offset(140, 130));
      expect(c.size, const Size(260, 210));
    });

    test('area co nhỏ lại → position tự kẹp về vùng hợp lệ', () {
      final c = makeController(position: const Offset(400, 300));
      expect(c.position, const Offset(400, 300)); // hợp lệ trong 800×600
      c.area = const Size(500, 420); // legal mới: x ≤ 188, y ≤ 168
      expect(c.position, const Offset(188, 168));
    });
  });

  group('GlassPanel — widget', () {
    Future<void> pumpArea(WidgetTester tester, List<GlassPanel> panels) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GlassPanelArea(panels: panels)),
        ),
      );
      await tester.pump();
    }

    /// Cặp controller cố định nằm gọn trong 800×600, tự dispose sau test.
    (GlassPanelController, GlassPanelController) makeControllers({
      Offset positionA = const Offset(40, 40),
      Offset positionB = const Offset(420, 320),
    }) {
      final a = GlassPanelController(
        position: positionA,
        size: const Size(300, 240),
      );
      final b = GlassPanelController(
        position: positionB,
        size: const Size(300, 240),
      );
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      return (a, b);
    }

    testWidgets('kéo thanh tiêu đề → panel dời theo đúng hướng',
        (WidgetTester tester) async {
      final (a, b) = makeControllers();
      await pumpArea(tester, <GlassPanel>[
        GlassPanel(controller: a, title: 'Một', child: const SizedBox.expand()),
        GlassPanel(controller: b, title: 'Hai', child: const SizedBox.expand()),
      ]);

      final before = a.position;
      await tester.drag(find.text('Một'), const Offset(80, 60));
      // Spring settle sau khi thả — pump từng bước rồi chờ hết frame (spring
      // KẾT THÚC nhờ tolerance nên pumpAndSettle không treo).
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      // Gesture arena ăn mất ~touch slop nên delta thực nhỏ hơn 80/60 chút,
      // nhưng hướng và độ lớn phải đúng.
      expect(a.position.dx, greaterThan(before.dx + 40));
      expect(a.position.dx, lessThanOrEqualTo(before.dx + 80.5));
      expect(a.position.dy, greaterThan(before.dy + 30));
      expect(a.position.dy, lessThanOrEqualTo(before.dy + 60.5));
      // Panel kia đứng yên.
      expect(b.position, const Offset(420, 320));
    });

    testWidgets('kéo vượt biên trái mạnh rồi thả → spring kéo về trong',
        (WidgetTester tester) async {
      final (a, b) = makeControllers();
      await pumpArea(tester, <GlassPanel>[
        GlassPanel(controller: a, title: 'Một', child: const SizedBox.expand()),
        GlassPanel(controller: b, title: 'Hai', child: const SizedBox.expand()),
      ]);

      await tester.drag(find.text('Một'), const Offset(-300, 0));
      // Ngay lúc thả (spring chưa chạy): rubber-band đã cho vượt biên trái.
      expect(a.position.dx, lessThan(margin));

      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      // Spring đưa panel về vùng hợp lệ, dừng sát mép trong tolerance (0.1px).
      expect(a.position.dx, greaterThanOrEqualTo(margin - 0.2));
      expect(a.position.dx, lessThan(margin + 1));
      expect(a.position.dy, closeTo(40, 1));
    });

    testWidgets('chạm panel → nổi lên trên cùng, nhận tap ở vùng chồng lấn',
        (WidgetTester tester) async {
      // Hai panel CHỒNG LÊN NHAU — z-order xác minh qua hành vi: panel trên
      // cùng là panel nhận tap trong vùng chồng lấn.
      final (a, b) = makeControllers(
        positionA: const Offset(40, 60),
        positionB: const Offset(200, 180),
      );
      final taps = <String>[];
      Widget tapChild(String name) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps.add(name),
            child: const SizedBox.expand(),
          );
      await pumpArea(tester, <GlassPanel>[
        GlassPanel(controller: a, title: 'Một', child: tapChild('Một')),
        GlassPanel(controller: b, title: 'Hai', child: tapChild('Hai')),
      ]);

      // Điểm nằm trong vùng NỘI DUNG của cả hai panel.
      const overlap = Offset(280, 260);

      // Ban đầu 'Hai' (khai báo sau) ở trên cùng → nhận tap.
      await tester.tapAt(overlap);
      await tester.pump();
      expect(taps, <String>['Hai']);

      // Chạm panel 'Một' (thanh tiêu đề còn lộ) → nổi lên trên cùng.
      await tester.tap(find.text('Một'));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      // Giờ 'Một' nhận tap ở vùng chồng lấn — z-order đã đổi.
      await tester.tapAt(overlap);
      await tester.pump();
      expect(taps, <String>['Hai', 'Một']);
    });

    testWidgets('kéo góc dưới-phải sâu vào trong → size kẹp ở minSize',
        (WidgetTester tester) async {
      final (a, b) = makeControllers();
      await pumpArea(tester, <GlassPanel>[
        GlassPanel(controller: a, title: 'Một', child: const SizedBox.expand()),
        GlassPanel(controller: b, title: 'Hai', child: const SizedBox.expand()),
      ]);

      // Góc dưới-phải của panel 'Một' (340, 280), lùi vào 5px cho chắc trúng
      // vùng hit resize (28×28 ở góc).
      final corner = a.rect.bottomRight - const Offset(5, 5);
      await tester.dragFrom(corner, const Offset(-500, -500));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(a.size, a.minSize);
      expect(a.size.width, greaterThan(0));
      expect(a.size.height, greaterThan(0));
      // Góc trên-trái (neo) không dời.
      expect(a.position, const Offset(40, 40));
    });
  });
}
