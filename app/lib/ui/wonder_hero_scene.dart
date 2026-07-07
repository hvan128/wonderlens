import 'package:flutter/material.dart';

import '../theme/wonder_tokens.dart';
import 'wonder_mascot.dart';

/// Khung hero minh hoạ cho màn chào: **ảnh scene nền** (bo góc, có bóng) với
/// **linh vật thở nhẹ** đứng trong scene. Chạm cả khung = CTA (mở ống kính).
///
/// Chỉ dùng cho màn hero/onboarding — các màn chức năng vẫn giữ nền liquid-glass.
/// Scene là ảnh tĩnh ([scene]); "hơi thở" đến từ [WonderMascot] mood [mood]
/// (mặc định [MascotMood.idle] — float/squash rất khẽ).
class WonderHeroScene extends StatelessWidget {
  /// Asset ảnh scene (vd 'assets/images/scene_discovery.jpg').
  final String scene;

  /// Sắc thái linh vật (mặc định idle = thở nhẹ).
  final MascotMood mood;

  /// Chiều cao khung hero (px).
  final double height;

  /// Chiều cao linh vật = factor × [height].
  final double mascotHeightFactor;

  /// Vị trí linh vật đứng trong scene (canh theo chỗ trống của ảnh).
  final Alignment mascotAlign;

  /// Canh dọc khi crop ảnh scene (cover) — kéo để lộ đúng vùng (vd mặt bàn).
  final Alignment sceneAlign;

  final double radius;

  /// Chạm cả khung → CTA. null = không tương tác.
  final VoidCallback? onTap;

  /// Nhãn ngữ nghĩa cho nút (khi có [onTap]).
  final String? semanticLabel;

  /// Huy hiệu nổi phía trên (vd chip "Chạm để khám phá").
  final Widget? topBadge;

  const WonderHeroScene({
    super.key,
    required this.scene,
    this.mood = MascotMood.idle,
    this.height = 320,
    this.mascotHeightFactor = 0.56,
    this.mascotAlign = const Alignment(0, 0.5),
    this.sceneAlign = const Alignment(0, 0.55),
    this.radius = 32,
    this.onTap,
    this.semanticLabel,
    this.topBadge,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: WonderColors.tealDeep.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(
              child: Image.asset(scene, fit: BoxFit.cover, alignment: sceneAlign),
            ),
            Align(
              alignment: mascotAlign,
              child: WonderMascot(mood: mood, size: height * mascotHeightFactor),
            ),
            if (topBadge != null)
              Positioned(top: 12, left: 0, right: 0, child: Center(child: topBadge)),
          ],
        ),
      ),
    );

    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
