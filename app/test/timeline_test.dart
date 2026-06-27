// Kiểm TimelineScreen render đủ các chặng + nút nghe kể chuyện.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/models/object_content.dart';
import 'package:wonderlens/screens/timeline_screen.dart';

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

  testWidgets('Timeline hiển thị tên vật, các chặng và nút nghe',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TimelineScreen(content: content)),
    );
    await tester.pump();
    // Cho các Timer delay (reveal so le + blob nền) kích hoạt hết trước teardown.
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Cốc giấy'), findsWidgets);
    expect(find.text('Bắt đầu từ cái cây'), findsOneWidget);
    expect(find.text('Nấu thành bột giấy'), findsOneWidget);
    // Auto-play tự đọc khi mở trang → nút điều khiển giọng đọc có thể đang ở
    // trạng thái "Dừng đọc" (đang đọc) hoặc "Nghe kể chuyện" (đã đọc xong).
    final hasNarrationControl =
        find.text('Nghe kể chuyện').evaluate().isNotEmpty ||
            find.text('Dừng đọc').evaluate().isNotEmpty;
    expect(hasNarrationControl, isTrue);
  });
}
