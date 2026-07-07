import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show StandardMessageCodec;

/// Nền **Liquid Glass native của iOS 26** (`UIGlassEffect`) qua PlatformView —
/// glass thật của hệ điều hành, mượt & thích ứng nội dung phía sau. [child] là
/// lớp nội dung Flutter phủ LÊN kính. Nền tảng khác (hoặc iOS cũ) rớt về
/// `BackdropFilter` blur trắng mờ. Kính tự bo capsule theo chiều cao.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double radius;

  const LiquidGlass({super.key, required this.child, this.radius = 999});

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ClipRRect(
        borderRadius: br,
        child: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: UiKitView(
                viewType: 'wonder_liquid_glass',
                creationParamsCodec: StandardMessageCodec(),
              ),
            ),
            // Tint kính rất nhẹ + viền sáng → luôn đọc ra "kính" kể cả khi glass
            // native trong veo trên nền sáng (native vẫn lo khúc xạ/bắt sáng thật).
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: br,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      );
    }
    // Fallback: frosted blur trắng đều.
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          ),
          child: child,
        ),
      ),
    );
  }
}
