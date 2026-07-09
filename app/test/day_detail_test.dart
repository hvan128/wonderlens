// Màn chi tiết một ngày (mở bằng morph từ thẻ ngày ở trang chủ): dựng đúng tiêu
// đề ngày + số vật + nhãn tên từng vật, không ném lỗi/tràn layout.
//
// Pump một frame với entry dựng sẵn (round-trip Hive đã có journal_test lo). KHÔNG
// dùng pump(Duration) vì nút vòng khẩu độ có animation xoay vô hạn — tiến thời
// gian sẽ treo; một pump() dựng xong frame đầu là đủ để kiểm layout + nội dung.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/data/collection_repository.dart';
import 'package:wonderlens/screens/day_detail_screen.dart';

JournalEntry _entry(String id, String name) => JournalEntry(
      id: id,
      name: name,
      emoji: '🥄',
      discoveredAt: DateTime(2026, 7, 8),
      content: const {},
    );

void main() {
  testWidgets('màn chi tiết ngày dựng đủ tiêu đề, số vật và nhãn tên vật', (
    tester,
  ) async {
    final entries = <JournalEntry>[
      _entry('wooden_spoon', 'Thìa gỗ'),
      _entry('clay_pot', 'Nồi đất'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: DayDetailView(
          entries: entries,
          color: const Color(0xFFA9B79D),
          onClose: () {},
          onCapture: () {},
          onOpenEntry: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('8 tháng 7'), findsOneWidget); // tiêu đề ngày
    expect(find.text('2 vật'), findsOneWidget);
    // Nhãn tem vẽ chữ 2 lớp (nét trắng ôm viền + chữ đặc) → mỗi tên 2 widget.
    expect(find.text('Thìa gỗ'), findsNWidgets(2));
    expect(find.text('Nồi đất'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 25)));
}
