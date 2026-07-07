import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'motion.dart';
import 'wonder_haptics.dart';

/// Bọc bất kỳ widget nào để có phản hồi chạm "mềm": thu nhỏ nhẹ + haptic.
/// Dùng chung cho mọi nút/thẻ bấm được trong app.
///
/// Scale chạy bằng spring vật lý [WonderSpring.snappy]: nhấn xuống dứt khoát,
/// nhả ra nảy nhẹ về 1.0. Velocity đang có được bàn giao khi đổi hướng giữa
/// chừng (nhấn rồi nhả nhanh) nên chuyển động không bao giờ bị khựng.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool haptic;
  final String? semanticLabel;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.94,
    this.haptic = true,
    this.semanticLabel,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  /// Tolerance theo đơn vị scale: hành trình nhấn chỉ ~0.06 nên phải mịn hơn
  /// nhiều so với tolerance mặc định của [WonderSpring.simulation] (0.1, hiệu
  /// chỉnh cho pixel) — dùng 0.1 ở đây spring sẽ bị coi là xong ngay lập tức.
  static const Tolerance _scaleTolerance =
      Tolerance(distance: 0.001, velocity: 0.01);

  /// Giá trị controller chính là hệ số scale; unbounded để cho phép vượt nhẹ
  /// qua 1.0 khi nảy (spring underdamped).
  late final AnimationController _controller =
      AnimationController.unbounded(value: 1.0, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Chạy spring từ trạng thái hiện tại về [target], bàn giao velocity đang
  /// có của controller để đổi hướng giữa chừng vẫn liền mạch.
  void _springTo(double target) {
    if (widget.onTap == null) return;
    _controller.animateWith(SpringSimulation(
      WonderSpring.snappy.description,
      _controller.value,
      target,
      _controller.velocity,
      tolerance: _scaleTolerance,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _springTo(widget.pressedScale),
        onTapCancel: () => _springTo(1.0),
        onTapUp: (_) {
          _springTo(1.0);
          // Chỉ rung khi thật sự bấm được — disabled mà rung là phản hồi giả.
          if (widget.onTap != null) {
            if (widget.haptic) WonderHaptics.selection();
            widget.onTap!();
          }
        },
        child: ScaleTransition(
          scale: _controller,
          child: widget.child,
        ),
      ),
    );
  }
}
