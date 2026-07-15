// Kiểm thẻ chia sẻ render đủ nội dung + nút chia sẻ mở được bảng xem trước.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/models/object_content.dart';
import 'package:wonderlens/screens/timeline_screen.dart';
import 'package:wonderlens/services/share_service.dart';
import 'package:wonderlens/widgets/share_card.dart';
import 'package:wonderlens/services/narration_service.dart';

/// Giọng kể giả: đọc xong tức thì — nhịp giữ chặng do _minDwell của
/// TimelineScreen lo (timer huỷ được) nên test không treo.
class _FakeNarration implements NarrationService {
  @override
  Future<void> speak(String text) => Future<void>.value();
  @override
  Future<void> speakAsset(String assetPath, String fallbackText) =>
      Future<void>.value();
  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}

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

  testWidgets('ShareCard hiện tên vật, các chặng và thương hiệu', (
    WidgetTester tester,
  ) async {
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

  testWidgets('Nút chia sẻ ở cuối hành trình mở bảng xem trước', (
    WidgetTester tester,
  ) async {
    // Timeline giờ chiếu từng chặng full màn; "Khoe khám phá" nằm ở màn kết
    // (outro) — đi hết hành trình rồi mới hiện. disableAnimations để reduce-motion
    // bỏ flutter_animate (delay dùng Timer) → không treo.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: TimelineScreen(
              content: content,
              narration: _FakeNarration(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(); // -> chặng 1
    await tester.pump(const Duration(milliseconds: 2600)); // -> chặng 2
    await tester.pump(const Duration(milliseconds: 2600)); // -> outro
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Khoe khám phá'), findsOneWidget);
    await tester.tap(find.text('Khoe khám phá'));
    await tester.pump(); // mở modal
    await tester.pump(const Duration(milliseconds: 400)); // sheet trượt vào

    expect(find.text('Khoe ngay'), findsOneWidget);
    expect(find.byType(ShareCard), findsOneWidget);
  });

  testWidgets('CollectionShareCard hiện cấp độ, tiến độ và huy hiệu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: CollectionShareCard(
                levelTitle: 'Thám tử manh mối 🧭',
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

    expect(find.text('Thám tử manh mối 🧭'), findsOneWidget);
    expect(find.text('Đã mở khóa 3/8 đồ vật'), findsOneWidget);
    expect(find.text('WonderLens'), findsOneWidget);
    // Thẻ redesign hiện pill "Giấy" (icon huy hiệu riêng, không còn prefix 🏅).
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
