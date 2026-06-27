import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'phosphor_compat.dart';

import '../theme/wonder_tokens.dart';

/// Nút quét trung tâm kiểu "kính lúp ma thuật": vòng gradient cầu vồng xoay +
/// glow mềm, lõi là đĩa shutter trắng có icon kính lúp Phosphor. Khi [busy]
/// (đang nhận diện) vòng xoay nhanh & sáng hơn, lõi hiện spinner.
class ScanRingButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool busy;
  final double size;

  const ScanRingButton({
    super.key,
    this.onTap,
    this.busy = false,
    this.size = WonderTokens.scanSize,
  });

  @override
  State<ScanRingButton> createState() => _ScanRingButtonState();
}

class _ScanRingButtonState extends State<ScanRingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: _spinDuration,
  )..repeat();

  bool _pressed = false;

  Duration get _spinDuration => widget.busy
      ? const Duration(milliseconds: 1400)
      : const Duration(seconds: 7);

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
    super.dispose();
  }

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Semantics(
      button: true,
      label: 'Quét để khám phá',
      child: GestureDetector(
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) {
          _set(false);
          widget.onTap?.call();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: WonderTokens.durFast,
          curve: Curves.easeOut,
          child: SizedBox(
            width: size,
            height: size,
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, child) => CustomPaint(
                painter: _RingPainter(rotation: _spin.value, busy: widget.busy),
                child: child,
              ),
              child: Center(child: _core(size)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _core(double size) {
    final d = size * 0.58;
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
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: widget.busy
          ? Padding(
              padding: EdgeInsets.all(d * 0.28),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(WonderColors.teal),
              ),
            )
          : Center(
              child: PhosphorIcon(
                PhosphorIconsBold.magnifyingGlass,
                size: d * 0.5,
                color: WonderColors.tealDeep,
              ),
            ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double rotation; // 0..1
  final bool busy;

  _RingPainter({required this.rotation, required this.busy});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = size.width * 0.085;
    final radius = size.width / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final shader = SweepGradient(
      colors: WonderGradients.ring,
      transform: GradientRotation(rotation * 2 * math.pi),
    ).createShader(rect);

    final glow = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * (busy ? 2.1 : 1.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, busy ? 11 : 7);
    canvas.drawCircle(center, radius, glow);

    final ring = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, ring);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.rotation != rotation || old.busy != busy;
}
