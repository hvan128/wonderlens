import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'pressable.dart';
import 'wonder_haptics.dart';

/// Độ "mở" khẩu độ lúc nghỉ (0 = sập kín, 1 = mở toang). ~0.55 cho lỗ mở vừa.
const double _kIdleOpen = 0.55;

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Logo WonderLens — **khẩu độ pinwheel pastel** (6 cánh đều, tâm sáng). Dựng
/// bằng [AperturePainter], không asset. [spin] = xoay chậm nhẹ (tôn trọng
/// Reduce Motion). Dùng cho nhận diện thương hiệu (header…). Nút chụp tương tác
/// có hiệu ứng shutter là [ApertureCaptureButton].
class WonderLogo extends StatefulWidget {
  final double size;
  final bool spin;

  const WonderLogo({super.key, this.size = 36, this.spin = true});

  @override
  State<WonderLogo> createState() => _WonderLogoState();
}

class _WonderLogoState extends State<WonderLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    final wantSpin = widget.spin && !reduce;
    if (wantSpin && !_c.isAnimating) {
      _c.repeat();
    } else if (!wantSpin && _c.isAnimating) {
      _c.stop();
    }

    final Widget mark = RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(painter: const AperturePainter(openness: _kIdleOpen)),
      ),
    );

    if (!wantSpin) return mark;
    return RotationTransition(turns: _c, child: mark);
  }
}

/// Nút chụp là logo khẩu độ — dùng ở trang chủ (mở camera) lẫn shutter màn
/// camera. [animateOnTap] = true: chạm chạy **hiệu ứng chụp** (cánh mở tách ra
/// → xoay vài vòng → sập vào + chớp sáng) rồi gọi [onCapture]; = false: gọi
/// [onCapture] ngay (shutter camera). Reduce Motion cũng bỏ hiệu ứng.
class ApertureCaptureButton extends StatefulWidget {
  final double size;
  final VoidCallback? onCapture;

  /// Gọi NGAY lúc chạm (đầu hiệu ứng) — vd pre-warm camera để nó nạp trong lúc
  /// vòng đang xoay.
  final VoidCallback? onPressStart;

  /// Đang bận (AI xử lý) → xoay liên tục nhanh, bỏ qua chạm.
  final bool busy;

  /// Vành chấm ngắm quanh nút (home bật; màn camera tắt vì nền tối).
  final bool showGuide;

  /// true → chạm chạy hiệu ứng chụp rồi mới [onCapture]; false → [onCapture]
  /// ngay (dùng cho shutter camera: chụp tức thì, hiệu ứng tan-biến lo phần sau).
  final bool animateOnTap;

  final String? semanticLabel;

  const ApertureCaptureButton({
    super.key,
    this.size = 220,
    this.onCapture,
    this.onPressStart,
    this.busy = false,
    this.showGuide = true,
    this.animateOnTap = true,
    this.semanticLabel,
  });

  @override
  State<ApertureCaptureButton> createState() => _ApertureCaptureButtonState();
}

class _ApertureCaptureButtonState extends State<ApertureCaptureButton>
    with TickerProviderStateMixin {
  // Xoay chậm lúc nghỉ.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );
  // Chuỗi hiệu ứng chụp (một lần).
  late final AnimationController _cap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  bool _capturing = false;

  static const double _turns = 2.5; // số vòng xoay khi chụp

  @override
  void dispose() {
    _idle.dispose();
    _cap.dispose();
    super.dispose();
  }

  Future<void> _startCapture() async {
    if (_capturing || widget.busy || widget.onCapture == null) return;
    widget.onPressStart?.call();
    if (!widget.animateOnTap || reduceMotionOf(context)) {
      WonderHaptics.primary();
      widget.onCapture!.call();
      return;
    }
    setState(() => _capturing = true);
    _idle.stop();
    WonderHaptics.primary();
    try {
      await _cap.forward(from: 0);
    } catch (_) {}
    if (!mounted) return;
    WonderHaptics.success(); // khoảnh khắc "chụp"
    widget.onCapture!.call();
    if (!mounted) return;
    _cap.reset();
    setState(() => _capturing = false);
  }

  // openness theo timeline: mở nhanh → giữ → sập.
  double _openness(double t) {
    const open = 0.28, hold = 0.62;
    if (t < open) {
      return _lerp(_kIdleOpen, 1, Curves.easeOutCubic.transform(t / open));
    }
    if (t < hold) return 1;
    return _lerp(1, 0, Curves.easeInCubic.transform((t - hold) / (1 - hold)));
  }

  double _rotation(double t) =>
      _turns * 2 * math.pi * Curves.easeInOutCubic.transform(t);

  double _scale(double t) {
    const snap = 0.62;
    if (t < snap) return 1 + 0.06 * Curves.easeOut.transform(t / snap);
    return _lerp(1.06, 0.9, Curves.easeInCubic.transform((t - snap) / (1 - snap)));
  }

  double _flash(double t) {
    const s = 0.78;
    if (t < s) return 0;
    return Curves.easeIn.transform((t - s) / (1 - s)) * 0.55;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    // Xoay lúc nghỉ (trang trí) hoặc lúc bận (báo đang xử lý — bận thì bỏ qua
    // Reduce Motion vì là phản hồi chức năng). Bận → xoay nhanh hơn.
    final spinning = !_capturing && (widget.busy || !reduce);
    final dur = widget.busy
        ? const Duration(milliseconds: 1100)
        : const Duration(seconds: 20);
    if (_idle.duration != dur) {
      _idle.duration = dur;
      if (_idle.isAnimating) _idle.repeat();
    }
    if (spinning) {
      if (!_idle.isAnimating) _idle.repeat();
    } else if (_idle.isAnimating) {
      _idle.stop();
    }
    final size = widget.size;

    return Semantics(
      button: true,
      label: widget.semanticLabel ?? 'Mở ống kính để soi đồ vật',
      child: Pressable(
        onTap: _startCapture,
        haptic: false,
        child: SizedBox.square(
          dimension: size,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_idle, _cap]),
            builder: (context, _) {
              final t = _cap.value;
              final openness = _capturing ? _openness(t) : _kIdleOpen;
              final rotation = _capturing
                  ? _rotation(t)
                  : (spinning ? _idle.value * 2 * math.pi : 0.0);
              final scale = _capturing ? _scale(t) : 1.0;
              final flash = _capturing ? _flash(t) : 0.0;

              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  if (widget.showGuide)
                    const Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(painter: _GuidePainter()),
                      ),
                    ),
                  Positioned.fill(
                    child: Transform.scale(
                      scale: scale,
                      child: CustomPaint(
                        painter: AperturePainter(
                          openness: openness,
                          rotation: rotation,
                        ),
                      ),
                    ),
                  ),
                  if (flash > 0)
                    IgnorePointer(
                      child: Container(
                        width: size * 0.86,
                        height: size * 0.86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: flash),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Vẽ khẩu độ camera: [_n] cánh cong chồng nhau tạo lỗ mở đa giác ở giữa.
/// [openness] 0→1 điều khiển bán kính lỗ mở (0 = sập kín, 1 = mở toang);
/// [rotation] (radian) xoay cả khẩu độ. Mỗi cánh nằm GIỮA hai mép xoắn giống
/// hệt (lệch đúng một bước góc) nên các cánh bằng nhau, không đè nhau.
class AperturePainter extends CustomPainter {
  final double openness;
  final double rotation;

  const AperturePainter({this.openness = _kIdleOpen, this.rotation = 0});

  static const int _n = 6;

  static const List<Color> _blades = <Color>[
    Color(0xFFFFD15A), // vàng
    Color(0xFF74E0B0), // mint
    Color(0xFF6FC0F2), // xanh dương
    Color(0xFF9AA4F2), // chàm-lavender
    Color(0xFFC79BEE), // tím grape
    Color(0xFFFF97AE), // hồng
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double ro = side * 0.47;
    final double ri = _lerp(side * 0.045, side * 0.32, openness.clamp(0, 1));
    final double ctrlR = ri + (ro - ri) * 0.42; // luôn nằm giữa ri..ro
    final Rect outer = Rect.fromCircle(center: c, radius: ro);
    final Rect inner = Rect.fromCircle(center: c, radius: ri);

    const double step = 2 * math.pi / _n;
    const double swirl = step * 0.9;
    final double base = -math.pi / 2 + rotation;

    Offset polar(double a, double r) =>
        c + Offset(math.cos(a) * r, math.sin(a) * r);
    Offset edgeCtrl(double a) => polar(a - swirl * 0.55, ctrlR);

    for (int k = 0; k < _n; k++) {
      final double t0 = base + k * step;
      final double t1 = t0 + step;
      final Offset startK = polar(t0, ro);

      final Path path = Path()
        ..moveTo(startK.dx, startK.dy)
        ..arcTo(outer, t0, step, false)
        ..quadraticBezierTo(
          edgeCtrl(t1).dx,
          edgeCtrl(t1).dy,
          polar(t1 - swirl, ri).dx,
          polar(t1 - swirl, ri).dy,
        )
        ..arcTo(inner, t1 - swirl, -step, false)
        ..quadraticBezierTo(
          edgeCtrl(t0).dx,
          edgeCtrl(t0).dy,
          startK.dx,
          startK.dy,
        )
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = _blades[k],
      );
    }

    // Tâm sáng dịu (thu nhỏ theo lỗ mở → khi sập gần như biến mất).
    canvas.drawCircle(
      c,
      ri * 0.78,
      Paint()
        ..isAntiAlias = true
        ..color = const Color(0xFFFDFEFF),
    );
  }

  @override
  bool shouldRepaint(covariant AperturePainter old) =>
      old.openness != openness || old.rotation != rotation;
}

/// Vành chấm bi mờ bao ngoài — gợi "ống ngắm" quanh nút chụp.
class _GuidePainter extends CustomPainter {
  const _GuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    const dots = 46;
    final paint = Paint()
      ..color = const Color(0xFF54657F).withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < dots; i++) {
      final a = 2 * math.pi * i / dots;
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * radius,
        1.7,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) => false;
}
