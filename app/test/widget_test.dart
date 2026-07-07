// Smoke test cho WonderLens: app dựng được và hiện trang chủ mới.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wonderlens/main.dart';

void main() {
  testWidgets('Trang chủ hiện thương hiệu và nút vòng mở màn chụp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: WonderLensApp()));
    await tester.pump();
    // Cho các Timer delay (animation vào màn + blob nền) kích hoạt hết.
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('WonderLens'), findsOneWidget);
    expect(find.text('Chạm vòng tròn để soi đồ vật'), findsOneWidget);
    expect(find.text('Xem rương'), findsOneWidget);
  });
}
