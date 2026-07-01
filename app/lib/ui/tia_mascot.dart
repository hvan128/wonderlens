import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wonder_tokens.dart';

/// Tông màu cho mascot Tia (kính lúp biết cười) — chữ ký thị giác của app.
enum TiaTone {
  /// Tím thương hiệu (đặt trên nền sáng / bong bóng kính).
  brand,

  /// Thấu kính trắng (đặt trên nền tím tối, vd màn Chào mừng).
  light,

  /// Vàng tia sáng ("đang dựng phim" — màn Generating).
  sunny,
}

/// Mascot **Tia**: một chiếc kính lúp có mắt + miệng cười + tay cầm, vầng sáng
/// thấu kính là chữ ký thị giác xuyên suốt WonderLens. Vẽ bằng [CustomPaint] theo
/// đúng tỉ lệ SVG trong `wonderlens-mockup.html` (viewBox 100×110) nên sắc nét ở
/// mọi kích thước, không cần asset.
class TiaMascot extends StatelessWidget {
  /// Chiều cao mong muốn (px). Bề rộng suy ra theo tỉ lệ 100:110.
  final double size;
  final TiaTone tone;

  /// Hiện hai má hồng (mặc định bật — dễ thương cho trẻ).
  final bool cheeks;

  const TiaMascot({
    super.key,
    this.size = 128,
    this.tone = TiaTone.brand,
    this.cheeks = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = size * (100 / 110);
    return SizedBox(
      width: width,
      height: size,
      child: CustomPaint(painter: _TiaPainter(tone: tone, cheeks: cheeks)),
    );
  }
}

class _TiaPainter extends CustomPainter {
  final TiaTone tone;
  final bool cheeks;

  _TiaPainter({required this.tone, required this.cheeks});

  static const Color _eye = WonderColors.textStrong; // #2A2150
  static const Color _cheek = Color(0xFFFF9DAA);

  Color get _lens => switch (tone) {
        TiaTone.brand => WonderColors.wonder,
        TiaTone.light => Colors.white,
        TiaTone.sunny => WonderColors.spark,
      };

  /// Mặt kính bóng (radial) — vầng sáng thấu kính là chữ ký thị giác của app.
  List<Color> get _glass => switch (tone) {
        TiaTone.sunny => const <Color>[Color(0xFFFFFDF4), Color(0xFFFFF6DD), Color(0xFFFFE6A6)],
        _ => const <Color>[Colors.white, Color(0xFFE8F6FF), Color(0xFFC9E8FF)],
      };

  Color get _handle => switch (tone) {
        TiaTone.brand => WonderColors.indigoDeep,
        TiaTone.light => const Color(0xFF4226A6),
        TiaTone.sunny => WonderColors.spark,
      };

  @override
  void paint(Canvas canvas, Size size) {
    // Map thẳng hệ toạ độ viewBox 100×110 → widget.
    canvas.scale(size.width / 100, size.height / 110);

    // —— Tay cầm (sau thấu kính), xoay -42° quanh điểm (66,84) ——
    canvas.save();
    canvas.translate(66, 84);
    canvas.rotate(-42 * math.pi / 180);
    canvas.translate(-66, -84);
    final handleRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(58, 64, 15, 40),
      const Radius.circular(8),
    );
    canvas.drawRRect(handleRect, Paint()..color = _handle);
    canvas.restore();

    // —— Thấu kính: vành ngoài + mặt kính trong (bóng, radial) ——
    canvas.drawCircle(const Offset(46, 44), 38, Paint()..color = _lens);
    final glassRect = Rect.fromCircle(center: const Offset(46, 44), radius: 30);
    final glassPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 0.95,
        colors: _glass,
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(glassRect);
    canvas.drawCircle(const Offset(46, 44), 30, glassPaint);

    // —— Hai má hồng (tuỳ chọn) ——
    if (cheeks) {
      final cheekPaint = Paint()..color = _cheek.withValues(alpha: 0.7);
      canvas.drawCircle(const Offset(30, 54), 4, cheekPaint);
      canvas.drawCircle(const Offset(62, 54), 4, cheekPaint);
    }

    // —— Mắt + đốm sáng ——
    final eyePaint = Paint()..color = _eye;
    canvas.drawCircle(const Offset(37, 42), 5.4, eyePaint);
    canvas.drawCircle(const Offset(57, 42), 5.4, eyePaint);
    final glint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(35.4, 40), 1.7, glint);
    canvas.drawCircle(const Offset(55.4, 40), 1.7, glint);

    // —— Miệng cười: M37 55 Q46 64 56 55 ——
    final smile = Path()
      ..moveTo(37, 55)
      ..quadraticBezierTo(46, 64, 56, 55);
    canvas.drawPath(
      smile,
      Paint()
        ..color = _eye
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TiaPainter old) =>
      old.tone != tone || old.cheeks != cheeks;
}
