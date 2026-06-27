// Kiểm ObjectAvatar rớt về emoji khi chưa có ảnh sản phẩm (CaptureStore trống).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/widgets/object_avatar.dart';

void main() {
  testWidgets('chưa có cutout → hiện emoji', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ObjectAvatar(objectId: 'paper_cup', emoji: '🥤'),
          ),
        ),
      ),
    );

    expect(find.text('🥤'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
