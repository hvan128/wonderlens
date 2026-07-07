import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/wonder_tokens.dart';
import 'phosphor_compat.dart';
import 'pressable.dart';

/// Hai tông kính: tối (đặt trên camera/nền rực, chữ trắng) và sáng (đặt trên
/// nền canvas dịu, chữ đậm).
enum GlassTone { dark, light }

/// Bề mặt "liquid glass": làm nhoè nền phía sau + lớp phủ trong mờ + viền
/// hairline + vệt sáng (sheen) dịu ở đỉnh + rim specular bắt sáng ở cạnh
/// trên-trái như kính thật nghiêng về nguồn sáng.
///
/// Cố ý KHÔNG dùng ColorFilter bão hoà trên BackdropFilter vì nó gây viền tối
/// ở mép (artifact premultiplied alpha) — chỉ blur thuần cho sạch. Mỗi surface
/// đúng MỘT BackdropFilter; không lồng kính trong kính (tốn saveLayer, tụt FPS
/// trên camera preview).
class GlassSurface extends StatelessWidget {
  final Widget child;
  final GlassTone tone;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? blur;
  final Color? tint;
  final double? tintOpacity;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const GlassSurface({
    super.key,
    required this.child,
    this.tone = GlassTone.dark,
    this.radius = WonderTokens.radiusLg,
    this.padding = const EdgeInsets.all(WonderTokens.space16),
    this.blur,
    this.tint,
    this.tintOpacity,
    this.shadows,
    this.onTap,
    this.semanticLabel,
  });

  bool get _dark => tone == GlassTone.dark;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final baseTint = tint ?? (_dark ? WonderColors.ink : Colors.white);
    // Tone sáng trong hơn (0.40 thay 0.46) để MÀU nền lọt qua → ra chất kính
    // thật thay vì panel trắng đặc; vẫn đủ đục cho chữ đậm đọc rõ.
    final op = tintOpacity ?? (_dark ? 0.34 : 0.40);
    final borderC = Colors.white.withValues(alpha: _dark ? 0.24 : 0.6);
    final sheen = _dark ? 0.14 : 0.34;
    final sigma = blur ?? WonderTokens.glassBlur;

    final Widget core = CustomPaint(
      // Rim specular vẽ TRÊN cùng — không ảnh hưởng layout của child.
      foregroundPainter: GlassRimPainter(
        radius: radius,
        intensity: _dark ? 0.55 : 1.0,
      ),
      // AnimatedContainer: đổi trạng thái tint (đèn pin bật, chặng highlight…)
      // chuyển màu mềm thay vì nhảy cắt. Khi giá trị không đổi thì không có
      // animation nào chạy — chi phí lúc nghỉ bằng Container thường.
      child: AnimatedContainer(
        duration: WonderTokens.durBase,
        curve: WonderTokens.curveStandard,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: br,
          // Lớp tint mờ — đỉnh đậm hơn đáy chút cho cảm giác khối kính.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              baseTint.withValues(alpha: (op + 0.05).clamp(0.0, 1.0)),
              baseTint.withValues(alpha: op),
            ],
          ),
          border: Border.all(color: borderC, width: 1),
        ),
        // Gloss kính: vệt sáng crisp ở đỉnh tắt dần, rồi ĐÁY tối nhẹ (chỉ tone
        // sáng) tạo cảm giác độ dày của tấm kính. Đỉnh sáng + đáy sẫm là dấu
        // hiệu thị giác chính để mắt đọc ra "một tấm kính", không phải mảng phẳng.
        foregroundDecoration: BoxDecoration(
          borderRadius: br,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.white.withValues(alpha: sheen),
              Colors.white.withValues(alpha: sheen * 0.35),
              Colors.transparent,
              if (!_dark) Colors.black.withValues(alpha: 0.05),
            ],
            stops: <double>[0.0, 0.14, 0.55, if (!_dark) 1.0],
          ),
        ),
        child: child,
      ),
    );

    // blur ≤ 0 → bỏ hẳn BackdropFilter (không tốn saveLayer) — lối thoát cho
    // bề mặt đè trên camera preview/video, nơi mỗi backdrop blur là tụt FPS.
    Widget panel = ClipRRect(
      borderRadius: br,
      child: sigma > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: core,
            )
          : core,
    );

    // Glow/bóng đổ cũng chuyển mềm cùng nhịp với tint (vd bật đèn pin →
    // quầng nắng sáng dần thay vì bật công tắc).
    panel = AnimatedContainer(
      duration: WonderTokens.durBase,
      curve: WonderTokens.curveStandard,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: shadows ?? WonderShadows.soft,
      ),
      child: panel,
    );

    if (onTap != null) {
      panel = Pressable(onTap: onTap, semanticLabel: semanticLabel, child: panel);
    }
    return panel;
  }
}

/// Viền "bắt sáng" của kính: stroke gradient sáng rõ ở cạnh trên-trái, tắt dần
/// về dưới-phải — mô phỏng specular highlight của Liquid Glass. Vẽ đè lên
/// hairline border hiện có nên không đổi layout. Public để [WonderButton]
/// dùng chung recipe kính (cùng một chất liệu specular toàn app).
class GlassRimPainter extends CustomPainter {
  final double radius;
  final double intensity;

  const GlassRimPainter({required this.radius, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Colors.white.withValues(alpha: intensity),
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: intensity * 0.25),
        ],
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GlassRimPainter old) =>
      old.radius != radius || old.intensity != intensity;
}

/// Nút tròn bằng kính, icon Phosphor. [active] → ánh sắc nắng (vd đèn pin bật).
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool active;
  final GlassTone tone;
  final String? semanticLabel;

  /// `blur: 0` cho nút đè trực tiếp lên camera/video — bỏ BackdropFilter
  /// (ngân sách ≤3 bề mặt blur của DESIGN.md); tint được nâng đậm bù lại.
  final double? blur;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = WonderTokens.iconBtnSize,
    this.active = false,
    this.tone = GlassTone.dark,
    this.semanticLabel,
    this.blur,
  });

  @override
  Widget build(BuildContext context) {
    final dark = tone == GlassTone.dark;
    final noBlur = blur != null && blur! <= 0;
    final iconColor = active
        ? const Color(0xFF7A4E00)
        : (dark ? Colors.white : WonderColors.textStrong);
    return GlassSurface(
      tone: tone,
      radius: size / 2,
      padding: EdgeInsets.zero,
      onTap: onTap,
      semanticLabel: semanticLabel,
      blur: blur,
      tint: active ? WonderColors.sunny : null,
      // Không blur → nền camera xuyên thẳng qua tint; nâng độ đặc để icon
      // vẫn tách khỏi cảnh camera sáng loạn (scrim đen của màn lo phần còn lại).
      tintOpacity: active ? (noBlur ? 0.88 : 0.5) : (noBlur ? 0.48 : null),
      shadows: active ? WonderShadows.glow(WonderColors.sunny, opacity: 0.5) : null,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          // Icon đổi glyph/màu theo trạng thái (vd đèn pin ↔ tia sét) →
          // crossfade nhanh cùng nhịp với tint của mặt kính bên dưới.
          child: AnimatedSwitcher(
            duration: WonderTokens.durFast,
            child: PhosphorIcon(
              icon,
              key: ValueKey<String>('${icon.codePoint}-$active'),
              size: size * 0.42,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
