import 'package:flutter/material.dart';

import '../theme/wonder_tokens.dart';

/// Thanh tiến độ bo tròn dùng chung (màn Generating, Badge, Bộ sưu tập).
/// Fill gradient bạc-hà → vàng tia sáng như mockup; tự đổi nền track theo
/// [onDark] để đọc rõ trên cả nền tím tối lẫn nền sáng.
class WonderProgressBar extends StatelessWidget {
  final double value; // 0..1
  final double height;
  final bool onDark;
  final Gradient gradient;
  final Duration animate;

  const WonderProgressBar({
    super.key,
    required this.value,
    this.height = 12,
    this.onDark = false,
    this.gradient = const LinearGradient(
      colors: <Color>[WonderColors.mint, WonderColors.spark],
    ),
    this.animate = WonderTokens.durSlow,
  });

  @override
  Widget build(BuildContext context) {
    final track = onDark
        ? Colors.white.withValues(alpha: 0.18)
        : WonderColors.wonder.withValues(alpha: 0.14);
    return ClipRRect(
      borderRadius: BorderRadius.circular(WonderTokens.pill),
      child: Stack(
        children: <Widget>[
          Container(height: height, color: track),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: animate,
            curve: WonderTokens.curveStandard,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v,
              child: Container(
                height: height,
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
