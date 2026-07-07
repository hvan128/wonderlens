import 'package:flutter/material.dart';

import '../theme/wonder_tokens.dart';

/// Nền dùng chung cho các màn nội dung: **lưới chấm bi** (dot grid) trên nền
/// sáng dịu — sạch, "giấy kẻ chấm" thân thiện với trẻ, thay cho gradient +
/// quầng màu trôi trước đây. Vẽ một lần bằng CustomPaint (tĩnh, rẻ), bọc
/// RepaintBoundary để không repaint theo nội dung phía trên.
class WonderBackground extends StatelessWidget {
  final Widget child;

  const WonderBackground({super.key, required this.child});

  /// Nền phẳng sáng dịu (không gradient) để lưới chấm + kính nổi rõ.
  static const Color base = Color(0xFFEFF3F7);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: base),
      child: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: CustomPaint(painter: _DotGridPainter()),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Lưới chấm bi đều — chấm teal rất mờ, cách nhau [_gap]px.
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  static const double _gap = 22;
  static const double _radius = 1.4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = WonderColors.tealDeep.withValues(alpha: 0.09)
      ..isAntiAlias = true;
    for (double y = _gap / 2; y < size.height; y += _gap) {
      for (double x = _gap / 2; x < size.width; x += _gap) {
        canvas.drawCircle(Offset(x, y), _radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) => false;
}
