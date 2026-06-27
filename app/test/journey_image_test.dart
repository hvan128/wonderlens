// Kiểm thứ tự ưu tiên phân giải ảnh chặng: illustration (asset/URL) → ảnh
// AI-live (file) → null (không ảnh, giữ look cũ).
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/services/journey_image_service.dart';

void main() {
  test('illustration asset path → AssetImage', () {
    final p = resolveStageImage(illustration: 'assets/images/ball_pen_stage0.png');
    expect(p, isA<AssetImage>());
    expect((p! as AssetImage).assetName, 'assets/images/ball_pen_stage0.png');
  });

  test('illustration URL → NetworkImage', () {
    final p = resolveStageImage(illustration: 'https://x.test/a.png');
    expect(p, isA<NetworkImage>());
    expect((p! as NetworkImage).url, 'https://x.test/a.png');
  });

  test('không illustration nhưng có file AI-live → FileImage', () {
    final f = File('/tmp/wonderlens_test_stage.png');
    final p = resolveStageImage(illustration: null, liveFile: f);
    expect(p, isA<FileImage>());
    expect((p! as FileImage).file.path, f.path);
  });

  test('illustration rỗng + không file → null (giữ look cũ)', () {
    expect(resolveStageImage(illustration: '   '), isNull);
    expect(resolveStageImage(), isNull);
  });

  test('illustration ưu tiên hơn file AI-live', () {
    final p = resolveStageImage(
      illustration: 'assets/images/x.png',
      liveFile: File('/tmp/y.png'),
    );
    expect(p, isA<AssetImage>());
  });
}
