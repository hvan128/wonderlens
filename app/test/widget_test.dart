// Smoke test cho WonderLens: app dựng được và hiện màn onboarding.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wonderlens/main.dart';

void main() {
  testWidgets('Onboarding hiển thị tiêu đề và nút bắt đầu',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WonderLensApp()));
    await tester.pump();
    // Cho các Timer delay (animation vào màn + blob nền) kích hoạt hết.
    await tester.pump(const Duration(seconds: 2));

    // Wordmark hai tông (Text.rich) → khớp theo nội dung gộp "WonderLens".
    expect(find.textContaining('WonderLens'), findsWidgets);
    expect(find.text('Bắt đầu khám phá'), findsOneWidget);
  });
}
