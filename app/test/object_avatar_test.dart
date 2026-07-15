// Kiểm ObjectAvatar ưu tiên cutout thật/bundled cho object visual.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/widgets/object_sticker_grid.dart';
import 'package:wonderlens/widgets/object_avatar.dart';

void main() {
  test('hero sticker scale lấy paper_cup làm chuẩn thị giác', () {
    expect(objectStickerVisualScale('paper_cup'), 1);
    expect(objectStickerVisualOffset('paper_cup'), Offset.zero);
    expect(objectStickerVisualScale('paper_a4'), closeTo(1.88, 0.001));
    expect(objectStickerVisualOffset('paper_a4').dy, closeTo(-0.030, 0.001));
    expect(objectStickerVisualScale('sticky_note'), closeTo(3.00, 0.001));
  });

  test('home preview dùng target nhỏ hơn nhưng vẫn cân paper_cup và A4', () {
    expect(kHomePreviewStickerDiameter, 82);
    expect(objectHomePreviewVisualScale('paper_cup'), closeTo(0.76, 0.001));
    expect(objectHomePreviewVisualScale('paper_a4'), closeTo(1.25, 0.001));
    expect(objectHomePreviewVisualScale('sticky_note'), closeTo(2.00, 0.001));
  });

  test('hero thu về home kết thúc đúng size và scale preview', () {
    expect(objectHomeFlightDiameter(132, 0), kHomePreviewStickerDiameter);
    expect(objectHomeFlightDiameter(132, 1), 132);
    expect(
      objectHomeFlightVisualScale('paper_cup', 0),
      objectHomePreviewVisualScale('paper_cup'),
    );
    expect(
      objectHomeFlightVisualScale('paper_cup', 1),
      objectStickerVisualScale('paper_cup'),
    );
  });

  testWidgets('hero object dùng cutout bundled thay emoji khi chưa có file', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ObjectAvatar(objectId: 'pencil', emoji: '✏️'),
          ),
        ),
      ),
    );

    expect(find.text('✏️'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/mission_pencil_cutout.png',
      ),
      findsWidgets,
    );
  });

  testWidgets('paper_cup dùng cutout bundled thay emoji khi chưa có file', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ObjectAvatar(objectId: 'paper_cup', emoji: '🥤'),
          ),
        ),
      ),
    );

    expect(find.text('🥤'), findsNothing);
    expect(find.byType(Image), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/paper_cup_cutout.png',
      ),
      findsWidgets,
    );
  });

  testWidgets('unknown object chưa có cutout mới rớt về emoji legacy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ObjectAvatar(objectId: 'unknown_live_object', emoji: '✨'),
          ),
        ),
      ),
    );

    expect(find.text('✨'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
