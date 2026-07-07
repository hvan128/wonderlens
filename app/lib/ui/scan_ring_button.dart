import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'phosphor_compat.dart';

import '../theme/wonder_tokens.dart';
import 'motion.dart';
import 'wonder_haptics.dart';

/// Nút vòng "kính lúp ma thuật" — bản v2 dịu mắt: thay vòng cầu vồng đặc bằng
/// **các cung màu rời** (candy arcs) xoay chậm quanh lõi shutter trắng có icon
/// kính lúp. Dùng chung cho hai chỗ để giữ cùng một "tinh thần vòng":
///   • Trang chủ  → vòng lớn, [showGuide] bật vành chấm bi ngoài, chạm mở camera.
///   • Màn camera → shutter cỡ [WonderTokens.scanSize]; [busy] khi đang nhận diện
///     (cung xoay nhanh + sáng hơn, lõi hiện spinner).
class ScanRingButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool busy;
  final double size;

  /// Vành chấm bi mờ bao ngoài (kiểu "quỹ đạo") — dùng cho vòng lớn ở trang chủ.
  final bool showGuide;

  /// Icon giữa lõi — mặc định kính lúp (đồng nhất định danh "soi").
  final IconData centerIcon;

  /// Nhãn trợ năng — mỗi ngữ cảnh một câu (mở camera vs. đang soi).
  final String? semanticLabel;

  const ScanRingButton({
    super.key,
    this.onTap,
    this.busy = false,
    this.size = WonderTokens.scanSize,
    this.showGuide = false,
    this.centerIcon = PhosphorIconsBold.magnifyingGlass,
    this.semanticLabel,
  });

  @override
  State<ScanRingButton> createState() => _ScanRingButtonState();
}

class _ScanRingButtonState extends State<ScanRingButton>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: _spinDuration,
  )..repeat();

  /// Scale khi nhấn — unbounded để spring bouncy được vọt quá 1.0 lúc nhả.
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
    value: 1.0,
  );

  /// Tỉ lệ thu nhỏ khi ngón tay đè lên nút.
  static const double _pressedScale = 0.9;

  // Vòng lớn xoay chậm hơn (êm mắt); busy thì xoáy nhanh dứt khoát.
  Duration get _spinDuration => widget.busy
      ? const Duration(milliseconds: 1400)
      : const Duration(seconds: 12);

  @override
  void didUpdateWidget(covariant ScanRingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busy != widget.busy) {
      _spin
        ..duration = _spinDuration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _press.dispose();
    super.dispose();
  }

  /// Nhấn xuống: thu về [_pressedScale] bằng spring snappy — nhanh, dứt khoát.
  void _pressDown() {
    if (widget.onTap == null) return;
    _press.animateWith(
      WonderSpring.snappy.simulation(
        from: _press.value,
        to: _pressedScale,
        velocity: _press.velocity,
      ),
    );
  }

  /// Nhả tay: nảy về 1.0 bằng spring bouncy, bàn giao velocity hiện tại để
  /// chuyển động liền mạch — nút trung tâm của bé nên nảy vui mắt.
  void _release() {
    _press.animateWith(
      WonderSpring.bouncy.simulation(
        from: _press.value,
        to: 1.0,
        velocity: _press.velocity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reduce Motion: cung màu đứng yên (vẫn đủ nhận diện nút); spring phản hồi
    // nhấn giữ nguyên vì là phản hồi nhân-quả.
    final reduce = reduceMotionOf(context);
    if (reduce && _spin.isAnimating) {
      _spin.stop();
    } else if (!reduce && !_spin.isAnimating) {
      _spin.repeat();
    }
    final size = widget.size;
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel ??
          (widget.busy ? 'Đang soi manh mối…' : 'Mở hành trình khám phá'),
      child: GestureDetector(
        onTapDown: (_) => _pressDown(),
        onTapCancel: _release,
        onTapUp: (_) {
          _release();
          if (widget.onTap != null) {
            // Nút hành động chính — haptic đậm hơn selection thường.
            WonderHaptics.primary();
            widget.onTap!();
          }
        },
        child: ScaleTransition(
          scale: _press,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Vành chấm bi tĩnh (quỹ đạo) — chỉ ở vòng lớn trang chủ.
                if (widget.showGuide)
                  const RepaintBoundary(
                    child: CustomPaint(painter: _GuidePainter()),
                  ),
                // Cung màu đối xứng tròn nên xoay layer ≡ xoay shader: raster
                // MỘT lần (RepaintBoundary) rồi để compositor xoay — không
                // repaint arcs + MaskFilter.blur mỗi frame trên màn camera.
                RotationTransition(
                  turns: _spin,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _SegmentRingPainter(busy: widget.busy),
                    ),
                  ),
                ),
                Center(child: _core(size)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _core(double size) {
    final d = size * 0.6;
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: <Color>[Colors.white, Color(0xFFEAF8FB)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.busy
          ? Padding(
              padding: EdgeInsets.all(d * 0.3),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(WonderColors.teal),
              ),
            )
          : Center(
              child: PhosphorIcon(
                widget.centerIcon,
                size: d * 0.42,
                color: WonderColors.tealDeep,
              ),
            ),
    );
  }
}

/// Sáu cung màu rời quanh lõi — rainbow candy dịu, có khe hở giữa các cung
/// (khác vòng sweep đặc cũ). Mỗi cung có một lớp glow mờ phía dưới cho mềm.
class _SegmentRingPainter extends CustomPainter {
  final bool busy;

  _SegmentRingPainter({required this.busy});

  // Ấm → lạnh, quay vòng: vàng → xanh lá → xanh dương → chàm → tím → hồng.
  static const List<Color> _segments = <Color>[
    WonderColors.sunny,
    WonderColors.mint,
    WonderColors.sky,
    WonderColors.indigo,
    WonderColors.grape,
    WonderColors.coral,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = size.width * 0.058;
    // Chừa chỗ cho glow + vành chấm bi ngoài.
    final radius = size.width / 2 - stroke * 1.7;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const n = 6; // == _segments.length
    const full = 2 * math.pi / n;
    final gap = full * 0.36; // khe hở giữa các cung
    final sweep = full - gap;
    const startBase = -math.pi / 2; // cung vàng bắt đầu ở đỉnh

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * (busy ? 2.4 : 1.9)
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, busy ? 10 : 7);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < n; i++) {
      final start = startBase + i * full + gap / 2;
      final color = _segments[i];
      glow.color = color.withValues(alpha: busy ? 0.5 : 0.34);
      canvas.drawArc(rect, start, sweep, false, glow);
      arc.color = color;
      canvas.drawArc(rect, start, sweep, false, arc);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentRingPainter old) => old.busy != busy;
}

/// Vành chấm bi mờ bao ngoài — gợi "ống ngắm / quỹ đạo" quanh nút lớn.
class _GuidePainter extends CustomPainter {
  const _GuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    const dots = 46;
    final paint = Paint()
      ..color = WonderColors.textSoft.withValues(alpha: 0.26)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < dots; i++) {
      final a = 2 * math.pi * i / dots;
      final o = center + Offset(math.cos(a), math.sin(a)) * radius;
      canvas.drawCircle(o, 1.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) => false;
}
