// Kiểm thẻ chia sẻ render đủ nội dung + nút chia sẻ mở được bảng xem trước.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/models/object_content.dart';
import 'package:wonderlens/screens/timeline_screen.dart';
import 'package:wonderlens/services/share_service.dart';
import 'package:wonderlens/widgets/share_card.dart';

void main() {
  const content = ObjectContent(
    id: 'paper_cup',
    name: 'Cốc giấy',
    emoji: '🥤',
    materialBadge: 'Giấy',
    stages: [
      Stage(title: 'Bắt đầu từ cái cây', kidText: 'Cốc giấy làm từ gỗ.'),
      Stage(title: 'Nấu thành bột giấy', kidText: 'Gỗ nấu thành bột giấy.'),
    ],
  );

  testWidgets('ShareCard hiện tên vật, các chặng và thương hiệu',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(child: ShareCard(content: content)),
          ),
        ),
      ),
    );

    expect(find.text('Cốc giấy'), findsOneWidget);
    expect(find.text('WonderLens'), findsOneWidget);
    expect(find.text('Bắt đầu từ cái cây'), findsOneWidget);
    expect(find.text('Nấu thành bột giấy'), findsOneWidget);
    expect(find.textContaining('Giấy'), findsWidgets);
  });

  test('caption gồm tên vật và mọi chặng', () {
    final text = ShareService.caption(content);
    expect(text, contains('Cốc giấy'));
    expect(text, contains('Bắt đầu từ cái cây'));
    expect(text, contains('Nấu thành bột giấy'));
    expect(text, contains('WonderLens'));
  });

  testWidgets('Nút chia sẻ trên timeline mở bảng xem trước',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TimelineScreen(content: content)),
    );
    await tester.pump();

    // Dùng nút chia sẻ trên header (luôn hiển thị, không bị cuộn khuất).
    // Nền có animation lặp vô hạn nên dùng pump(duration) thay pumpAndSettle.
    await tester.tap(find.byTooltip('Chia sẻ'));
    await tester.pump(); // mở modal
    await tester.pump(const Duration(milliseconds: 400)); // sheet trượt vào

    expect(find.text('Chia sẻ ngay'), findsOneWidget);
    expect(find.byType(ShareCard), findsOneWidget);
  });

  testWidgets('CollectionShareCard hiện cấp độ, tiến độ và huy hiệu',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: CollectionShareCard(
                levelTitle: 'Nhà khám phá 🧭',
                discoveredCount: 3,
                totalCount: 8,
                earnedMaterials: ['Giấy', 'Nhựa'],
                discoveredEmojis: ['🥤', '🖊️', '📄'],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nhà khám phá 🧭'), findsOneWidget);
    expect(find.text('Đã khám phá 3/8 đồ vật'), findsOneWidget);
    expect(find.text('WonderLens'), findsOneWidget);
    // Huy hiệu vật liệu render dạng pill (icon medal + tên), không phải emoji
    // "🏅". Khớp với `_Pill` trong share_card.dart (nguồn sự thật trên main).
    expect(find.text('Giấy'), findsOneWidget);
  });

  test('collectionCaption gồm cấp độ và tiến độ', () {
    final text = ShareService.collectionCaption(
      levelTitle: 'Nhà khoa học nhí 🔬',
      discoveredCount: 5,
      totalCount: 8,
      earnedCount: 3,
    );
    expect(text, contains('Nhà khoa học nhí'));
    expect(text, contains('5/8'));
    expect(text, contains('3 huy hiệu'));
    expect(text, contains('WonderLens'));
  });
}
