import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/wonder_tokens.dart';

/// Nền dùng chung cho các màn nội dung: gradient canvas dịu + vài quầng màu mờ
/// trôi nhẹ. Vừa vui mắt cho trẻ, vừa tạo "chất liệu" để kính phía trên khúc xạ.
class WonderBackground extends StatelessWidget {
  final Widget child;

  const WonderBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: WonderGradients.canvas),
      child: Stack(
        children: <Widget>[
          // Chỉ dùng quầng màu họ tím/lam (bỏ quầng vàng — trên nền oải hương
          // nó đọc như "vết ố" và phá tông; xem TASK-022 feedback ảnh thật).
          const Positioned(
            top: -60,
            left: -50,
            child: _Blob(color: WonderColors.wonder, size: 230, dy: 22),
          ),
          const Positioned(
            top: 120,
            right: -70,
            child: _Blob(color: WonderColors.sky, size: 200, dy: -26, delayMs: 600),
          ),
          const Positioned(
            bottom: -40,
            left: 30,
            child: _Blob(color: WonderColors.grape, size: 210, dy: 18, delayMs: 1200),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final double dy;
  final int delayMs;

  const _Blob({
    required this.color,
    required this.size,
    required this.dy,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.24),
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: 0,
            end: dy,
            delay: Duration(milliseconds: delayMs),
            duration: 4.seconds,
            curve: Curves.easeInOut,
          ),
    );
  }
}
