import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/data/capture_store.dart';
import 'package:wonderlens/models/object_content.dart';
import 'package:wonderlens/screens/discovery_reveal_screen.dart';

Widget _host(ObjectContent content) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: DiscoveryRevealScreen(content: content),
    ),
  ),
);

void main() {
  setUp(() => CaptureStore.debugSetStore(null, const <String>[]));

  testWidgets('result route gắn nhãn cho content live', (tester) async {
    const content = ObjectContent(
      id: 'live_cup',
      name: 'Cốc giấy',
      emoji: '🥤',
      materialBadge: 'Giấy',
      stages: <Stage>[],
      source: 'live',
    );

    await tester.pumpWidget(_host(content));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('AI hỗ trợ'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('result route không gắn nhãn cho content curated', (tester) async {
    const content = ObjectContent(
      id: 'paper_cup',
      name: 'Cốc giấy',
      emoji: '🥤',
      materialBadge: 'Giấy',
      stages: <Stage>[],
    );

    await tester.pumpWidget(_host(content));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('AI hỗ trợ'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
