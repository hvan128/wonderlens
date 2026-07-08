import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderlens/theme/wonder_tokens.dart';
import 'package:wonderlens/ui/wonder_logo.dart';

/// Sinh logo + app icon từ CHÍNH [AperturePainter] của nút capture — màu và
/// hình học khớp 100% với nút trong app, không vẽ tay lại. Cách điệu: khẩu độ
/// làm sticker die-cut (viền trắng + bóng đổ) dán nghiêng [WonderTilt] trên
/// nền giấy kraft cũ như thẻ ở màn Hồ sơ.
///
/// Chạy: `flutter test tool/pregen_brand_icons.dart` (từ thư mục app/).
/// Xuất:
/// - assets/images/brand_logo.png — logo nền trong suốt (mark thẳng).
/// - ios/.../AppIcon.appiconset/Icon-App-1024x1024@1x.png — icon master
///   (nền kraft, mark nghiêng); các size còn lại resize bằng sips sau.
void main() {
  test('sinh logo + app icon master tu AperturePainter', () async {
    final kraft = await _loadImage('assets/images/kraft_paper.png');

    final icon = await _renderIcon(kraft, 1024);
    await _savePng(
      icon,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
    );

    final logo = await _renderLogo(1024);
    await _savePng(logo, 'assets/images/brand_logo.png');
  });

  test('sinh feature graphic Google Play 1024x500', () async {
    final kraft = await _loadImage('assets/images/kraft_paper.png');
    await _loadBrandFonts();
    final graphic = await _renderFeatureGraphic(kraft, 1024, 500);
    await _savePng(graphic, 'store-assets/play-feature-graphic-1024x500.png');
  });
}

/// Nạp font bundle cho TextPainter trong môi trường test. Mỗi family chỉ nạp
/// một weight nên style không cần chỉ định fontWeight.
Future<void> _loadBrandFonts() async {
  Future<ByteData> read(String p) async =>
      (await File(p).readAsBytes()).buffer.asByteData();
  await (FontLoader('Baloo 2')
        ..addFont(read('assets/fonts/Baloo2-ExtraBold.ttf')))
      .load();
  await (FontLoader('Nunito')..addFont(read('assets/fonts/Nunito-Bold.ttf')))
      .load();
}

/// Feature graphic Google Play: nền kraft + sticker khẩu độ bên trái, wordmark
/// WonderLens + tagline bên phải.
Future<ui.Image> _renderFeatureGraphic(ui.Image kraft, int w, int h) {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final wd = w.toDouble(), hd = h.toDouble();

  _drawKraftCover(
    canvas,
    kraft,
    Size(wd, hd),
    tint: const Color(0xFFF1E2C6),
  );
  canvas.drawRect(
    Rect.fromLTWH(0, 0, wd, hd),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(wd / 2, 0),
        Offset(wd / 2, hd),
        const <Color>[Color(0x26FFFFFF), Color(0x00FFFFFF), Color(0x1A000000)],
        const <double>[0, 0.5, 1],
      ),
  );

  final markCenter = Offset(hd * 0.46, hd * 0.5);
  final mark = hd * 0.66;
  _drawStickerMark(
    canvas,
    center: markCenter,
    mark: mark,
    tilt: WonderTilt.angles[2],
  );

  final textX = markCenter.dx + mark * 0.47 * 1.14 + 48;
  final maxW = wd - textX - 44;
  const ink = Color(0xFF4A3B28);
  final title = TextPainter(
    text: const TextSpan(
      text: 'WonderLens',
      style: TextStyle(fontFamily: 'Baloo 2', fontSize: 86, color: ink),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxW);
  final tagline = TextPainter(
    text: TextSpan(
      text: 'Soi đồ vật quanh bé,\nmở ra hành trình tạo nên nó',
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 36,
        height: 1.35,
        color: ink.withValues(alpha: 0.82),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxW);

  final blockH = title.height + 12 + tagline.height;
  title.paint(canvas, Offset(textX, (hd - blockH) / 2));
  tagline.paint(canvas, Offset(textX + 5, (hd - blockH) / 2 + title.height + 12));

  return rec.endRecording().toImage(w, h);
}

Future<ui.Image> _loadImage(String path) async {
  final codec = await ui.instantiateImageCodec(
    await File(path).readAsBytes(),
  );
  return (await codec.getNextFrame()).image;
}

Future<void> _savePng(ui.Image img, String path) async {
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  await File(path).writeAsBytes(bytes!.buffer.asUint8List());
}

/// Icon full-bleed: giấy kraft nhuộm ấm (multiply, như _KraftCard màn Hồ sơ)
/// + sheen sáng trên–tối dưới + sticker khẩu độ dán nghiêng.
Future<ui.Image> _renderIcon(ui.Image kraft, int px) {
  final s = px.toDouble();
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);

  _drawKraftCover(canvas, kraft, Size(s, s), tint: const Color(0xFFF1E2C6));
  canvas.drawRect(
    Rect.fromLTWH(0, 0, s, s),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(s / 2, 0),
        Offset(s / 2, s),
        const <Color>[Color(0x26FFFFFF), Color(0x00FFFFFF), Color(0x1A000000)],
        const <double>[0, 0.5, 1],
      ),
  );
  _drawStickerMark(
    canvas,
    center: Offset(s / 2, s / 2),
    mark: s * 0.70,
    tilt: WonderTilt.angles[2],
  );

  return rec.endRecording().toImage(px, px);
}

/// Logo nền trong suốt: chỉ sticker khẩu độ, để thẳng cho dễ ghép mọi bối
/// cảnh (nghiêng là gia vị của icon/thẻ, không thuộc bản thân mark).
Future<ui.Image> _renderLogo(int px) {
  final s = px.toDouble();
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  _drawStickerMark(canvas, center: Offset(s / 2, s / 2), mark: s * 0.84, tilt: 0);
  return rec.endRecording().toImage(px, px);
}

/// Nền kraft: crop giữa ảnh theo tỷ lệ khung đích, phủ kín + nhuộm màu
/// multiply (thiếu asset thì đã ném lỗi từ lúc load — tool chạy local nên
/// fail thẳng cho dễ thấy).
void _drawKraftCover(
  Canvas canvas,
  ui.Image img,
  Size size, {
  required Color tint,
}) {
  final iw = img.width.toDouble(), ih = img.height.toDouble();
  final scale = math.max(size.width / iw, size.height / ih);
  final srcW = size.width / scale, srcH = size.height / scale;
  final rect = Offset.zero & size;
  canvas.drawImageRect(
    img,
    Rect.fromCenter(center: Offset(iw / 2, ih / 2), width: srcW, height: srcH),
    rect,
    Paint()..filterQuality = FilterQuality.high,
  );
  canvas.drawRect(
    rect,
    Paint()
      ..color = tint
      ..blendMode = BlendMode.multiply,
  );
}

/// Sticker die-cut: bóng đổ mềm → đĩa trắng kem viền quanh cánh → khẩu độ
/// (dáng nghỉ mặc định của [AperturePainter]). [mark] = cạnh vuông chứa khẩu
/// độ; cánh chạm bán kính 0.47*mark (ro của painter), đĩa trắng nống thêm 14%
/// làm viền.
void _drawStickerMark(
  Canvas canvas, {
  required Offset center,
  required double mark,
  required double tilt,
}) {
  final discR = mark * 0.47 * 1.14;

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(tilt);
  canvas.drawCircle(
    Offset(0, mark * 0.035),
    discR,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, mark * 0.032),
  );
  canvas.drawCircle(Offset.zero, discR, Paint()..color = const Color(0xFFFFFDF4));
  canvas.translate(-mark / 2, -mark / 2);
  const AperturePainter().paint(canvas, Size.square(mark));
  canvas.restore();
}
