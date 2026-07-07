// TimelineScreen kiểu CapWords: mỗi chặng full màn, giọng đọc xong tự đẩy chặng
// tiếp. Test tiêm NarrationService giả để pump nhanh & tất định (không cần TTS).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/models/object_content.dart';
import 'package:wonderlens/screens/timeline_screen.dart';
import 'package:wonderlens/services/narration_service.dart';

/// Giọng kể giả: ghi lại lời đã đọc, "đọc xong" sau [delay] ngắn, stop() hoàn
/// tất ngay — để vòng auto-advance chạy nhanh và tất định trong test.
class _FakeNarration implements NarrationService {
  final List<String> spoken = <String>[];
  int stops = 0;

  // Đọc xong tức thì (không Timer) — nhịp giữ mỗi chặng do _minDwell trong
  // TimelineScreen lo (timer huỷ được), nên teardown không còn timer treo.
  @override
  Future<void> speak(String text) {
    spoken.add(text);
    return Future<void>.value();
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  void dispose() {}
}

void main() {
  const content = ObjectContent(
    id: 'paper_cup',
    name: 'Cốc giấy',
    emoji: '🥤',
    materialBadge: 'Giấy',
    history: 'Cốc giấy làm từ cây.',
    stages: <Stage>[
      Stage(title: 'Bắt đầu từ cái cây', kidText: 'Cốc giấy làm từ gỗ.'),
      Stage(title: 'Nấu thành bột giấy', kidText: 'Gỗ nấu thành bột giấy.'),
    ],
  );

  // disableAnimations phải nằm DƯỚI MediaQuery của MaterialApp mới có hiệu lực
  // (MaterialApp tự dựng MediaQuery từ view, ghi đè lớp ngoài). reduce-motion bật
  // → _StoryScrim bỏ flutter_animate (delay dùng Timer) → teardown không treo.
  Widget host(_FakeNarration n) => MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: TimelineScreen(content: content, narration: n),
          ),
        ),
      );

  // Vượt sàn dwell (2200ms) + đọc (40ms) + slack để sang bước kế.
  Future<void> settleStep(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 2600));

  testWidgets('hiện từng chặng một & tự đẩy theo thứ tự', (tester) async {
    final n = _FakeNarration();
    await tester.pumpWidget(host(n));
    await tester.pump(); // postframe -> _advanceTo(0) (cover)
    await tester.pump(const Duration(milliseconds: 100));

    // Cover: có tên vật, CHƯA có chặng nào.
    expect(find.text('Cốc giấy'), findsOneWidget);
    expect(find.text('Bắt đầu từ cái cây'), findsNothing);

    await settleStep(tester); // -> chặng 1
    expect(find.text('Bắt đầu từ cái cây'), findsOneWidget);
    // Chặng 2 CHƯA xuất hiện khi đang ở chặng 1 → chứng minh chỉ hiện 1 chặng
    // (khác timeline cũ hiện hết). (Không assert cover "đã rời" vì transition
    // giữ view cũ trong ~1 frame — mong manh về timing.)
    expect(find.text('Nấu thành bột giấy'), findsNothing);

    await settleStep(tester); // -> chặng 2
    expect(find.text('Nấu thành bột giấy'), findsOneWidget);

    // Thứ tự đọc: cover (history) -> chặng 1 -> chặng 2.
    expect(n.spoken[0], 'Cốc giấy làm từ cây.');
    expect(n.spoken[1], 'Cốc giấy làm từ gỗ.');
    expect(n.spoken[2], 'Gỗ nấu thành bột giấy.');

    await settleStep(tester); // -> outro (vòng dừng)
    expect(find.text('Bé đã xem hết hành trình!'), findsOneWidget);
  });

  testWidgets('chạm để bỏ qua sang chặng sau ngay', (tester) async {
    final n = _FakeNarration();
    await tester.pumpWidget(host(n));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100)); // đang ở cover
    expect(find.text('Cốc giấy'), findsOneWidget);

    await tester.tap(find.byType(TimelineScreen)); // chạm giữa màn = đi tiếp
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Bắt đầu từ cái cây'), findsOneWidget); // đã sang chặng 1
    expect(n.stops, greaterThan(0)); // đã dừng giọng cover khi bỏ qua

    await settleStep(tester);
    await settleStep(tester); // về outro để vòng dừng gọn
  });

  testWidgets('đi hết hành trình -> hiện phần thưởng, không ném lỗi',
      (tester) async {
    final n = _FakeNarration();
    await tester.pumpWidget(host(n));
    await tester.pump();
    await settleStep(tester);
    await settleStep(tester);
    await settleStep(tester); // outro
    expect(tester.takeException(), isNull);
    expect(find.text('Soi vật khác'), findsOneWidget);
    expect(find.text('Khoe khám phá'), findsOneWidget);
  });
}
