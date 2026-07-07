import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Logo thương hiệu WonderLens — "Lens Badge": vành kính lúp gradient (teal→sky→
/// grape) + chữ W hình học ở giữa + một tia sparkle nắng. Vẽ hoàn toàn bằng
/// CustomPainter (không asset, không dependency SVG) nên offline & scale nét ở
/// mọi cỡ — đọc rõ từ 36px (header) tới splash lớn. [monochrome] cho bản một
/// màu (đóng dấu/watermark).
class WonderLogo extends StatelessWidget {
  const WonderLogo({
    super.key,
    this.size = 36,
    this.monochrome = false,
    this.inkColor = const Color(0xFF15233B),
  });

  final double size;
  final bool monochrome;
  final Color inkColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _WonderLogoPainter(
          monochrome: monochrome,
          inkColor: inkColor,
        ),
      ),
    );
  }
}

class _WonderLogoPainter extends CustomPainter {
  const _WonderLogoPainter({
    required this.monochrome,
    required this.inkColor,
  });

  final bool monochrome;
  final Color inkColor;

  static const Color _tealDeep = Color(0xFF0E97AC);
  static const Color _teal = Color(0xFF26C6DA);
  static const Color _sky = Color(0xFF38BDF8);
  static const Color _indigo = Color(0xFF7C8CF8);
  static const Color _grape = Color(0xFFB794F4);
  static const Color _sunny = Color(0xFFFFC857);

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    final double scale = side / 48;
    final Offset origin = Offset(
      (size.width - side) / 2,
      (size.height - side) / 2,
    );

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);

    _paintHandle(canvas);
    _paintLens(canvas);
    _paintWonderW(canvas);
    _paintSparkle(canvas);

    canvas.restore();
  }

  void _paintHandle(Canvas canvas) {
    final Paint handlePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = inkColor;

    if (!monochrome) {
      handlePaint.shader = ui.Gradient.linear(
        const Offset(30, 30),
        const Offset(43, 43),
        const <Color>[_tealDeep, _indigo],
      );
    }

    canvas.drawLine(
      const Offset(31.4, 31.0),
      const Offset(40.8, 40.4),
      handlePaint,
    );
  }

  void _paintLens(Canvas canvas) {
    final Paint rimPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round
      ..color = inkColor;

    if (!monochrome) {
      // ui.Gradient.linear bắt buộc số màu == số stops (và == 2 nếu bỏ stops).
      // Vành 3 màu → phải kèm stops, nếu không sẽ ném ArgumentError khi paint.
      rimPaint.shader = ui.Gradient.linear(
        const Offset(8, 6),
        const Offset(37, 35),
        const <Color>[_teal, _sky, _grape],
        const <double>[0.0, 0.55, 1.0],
      );
    }

    canvas.drawCircle(const Offset(22, 21), 14.4, rimPaint);
  }

  void _paintWonderW(Canvas canvas) {
    final Path wPath = Path()
      ..moveTo(14.5, 17.2)
      ..lineTo(17.7, 27.2)
      ..lineTo(21.7, 19.3)
      ..lineTo(25.0, 27.2)
      ..lineTo(29.5, 17.2);

    final Paint wPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = inkColor;

    canvas.drawPath(wPath, wPaint);
  }

  void _paintSparkle(Canvas canvas) {
    final Path sparkle = Path()
      ..moveTo(35.8, 5.2)
      ..lineTo(37.2, 9.3)
      ..lineTo(41.4, 10.8)
      ..lineTo(37.2, 12.3)
      ..lineTo(35.8, 16.6)
      ..lineTo(34.4, 12.3)
      ..lineTo(30.2, 10.8)
      ..lineTo(34.4, 9.3)
      ..close();

    final Paint sparklePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = monochrome ? inkColor : _sunny;

    canvas.drawPath(sparkle, sparklePaint);
  }

  @override
  bool shouldRepaint(covariant _WonderLogoPainter oldDelegate) {
    return monochrome != oldDelegate.monochrome ||
        inkColor != oldDelegate.inkColor;
  }
}
