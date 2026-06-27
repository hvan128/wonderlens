// Kiểm hàm cắt sát chủ thể (tách nền): từ PNG có vùng đặc trên nền trong suốt,
// trả về khung vuông canh giữa, nền vẫn trong suốt.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/services/image_cutout.dart';

/// Tạo PNG 100x100 trong suốt với một ô đặc [w]x[h] tại ([left],[top]).
Future<Uint8List> _pngWithOpaqueRect(
    int left, int top, int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(left.toDouble(), top.toDouble(), w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFFFF0000),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(100, 100);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<ui.Image> _decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  return frame.image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cắt sát chủ thể thành khung vuông canh giữa, giữ nền trong suốt',
      () async {
    final png = await _pngWithOpaqueRect(40, 30, 20, 26); // chủ thể 20x26
    final cropped = await tightCropTransparentPng(png, padding: 0);
    expect(cropped, isNotNull);

    final out = await _decode(cropped!);
    addTearDown(out.dispose);

    // Khung vuông = cạnh dài nhất của chủ thể.
    expect(out.width, out.height);
    expect(out.width, 26);

    final raw = (await out.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    int alphaAt(int x, int y) => raw[(y * out.width + x) * 4 + 3];

    // Giữa khung = chủ thể đặc; góc = nền trong suốt (chủ thể hẹp hơn khung).
    expect(alphaAt(out.width ~/ 2, out.height ~/ 2), greaterThan(200));
    expect(alphaAt(0, 0), lessThan(20));
  });

  test('ảnh toàn trong suốt → trả null (không tách được chủ thể)', () async {
    final blank = await _pngWithOpaqueRect(0, 0, 0, 0);
    expect(await tightCropTransparentPng(blank), isNull);
  });
}
