import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/ui/capture_dissolve.dart';

Future<ui.Image> _image(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 20, 20), Paint()..color = color);
  return recorder.endRecording().toImage(20, 20);
}

void main() {
  testWidgets('kết quả AI-live có nhãn AI hỗ trợ', (tester) async {
    final frame = await _image(Colors.teal);
    final mask = await _image(Colors.white);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: CaptureDissolve(
              frame: frame,
              mask: mask,
              title: 'Cốc giấy',
              aiAssisted: true,
              onOpen: () {},
              onRetake: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('AI hỗ trợ'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('kết quả curated không gắn nhãn AI', (tester) async {
    final frame = await _image(Colors.teal);
    final mask = await _image(Colors.white);

    await tester.pumpWidget(
      MaterialApp(
        home: CaptureDissolve(
          frame: frame,
          mask: mask,
          title: 'Cốc giấy',
          onOpen: () {},
          onRetake: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('AI hỗ trợ'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
