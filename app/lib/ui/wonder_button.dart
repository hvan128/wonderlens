import 'package:flutter/material.dart';
import 'phosphor_compat.dart';

import '../theme/wonder_tokens.dart';
import 'glass_surface.dart';
import 'pressable.dart';

/// Nút hành động chính — "kẹo kính bóng": nền gradient thương hiệu rực (giữ
/// affordance + tương phản cho CTA chính), phủ chất liệu Liquid Glass BÓNG:
/// specular rim bắt sáng góc trên-trái (dùng chung [GlassRimPainter] với
/// [GlassSurface]), gloss đỉnh mạnh + vệt sáng đáy tạo khối cong của kính.
/// Cố ý KHÔNG BackdropFilter (nút đè camera preview — mỗi saveLayer là tụt
/// FPS) và giữ nền ĐẶC để CTA nổi bật; độ bóng đến từ lớp phủ, không từ blur.
class WonderButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool expand;
  final Gradient gradient;
  final double height;

  const WonderButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.gradient = WonderGradients.cta,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(WonderTokens.radiusMd);
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      // Specular rim vẽ TRÊN cùng — cùng painter với GlassSurface nên nút và
      // thẻ kính bắt sáng giống hệt nhau.
      child: CustomPaint(
        foregroundPainter: GlassRimPainter(
          radius: WonderTokens.radiusMd,
          intensity: 0.9,
        ),
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: WonderTokens.space24),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: br,
            boxShadow: WonderShadows.glow(WonderColors.teal, opacity: 0.45),
          ),
          // Lớp kính bóng: gloss trắng đậm ôm nửa trên (đỉnh sáng, giữa tắt),
          // rồi một vệt sáng mỏng vén lên ở đáy → mặt kính cong bắt sáng hai
          // đầu. Hairline sáng viền quanh. Foreground (không phải decoration)
          // để border không ăn vào padding — layout giữ nguyên từng pixel.
          foregroundDecoration: BoxDecoration(
            borderRadius: br,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.42),
                Colors.white.withValues(alpha: 0.06),
                Colors.transparent,
                Colors.white.withValues(alpha: 0.14),
              ],
              stops: const <double>[0.0, 0.34, 0.72, 1.0],
            ),
          ),
          // Nút đổi vai giữa chừng (vd. "Nghe câu chuyện" ↔ "Dừng giọng kể"):
          // chữ + icon crossfade thay vì thế chỗ đột ngột.
          child: AnimatedSwitcher(
            duration: WonderTokens.durFast,
            child: Row(
              key: ValueKey<String>(label),
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Mực đậm thay chữ trắng: gradient thương hiệu sáng nên chữ trắng
                // chỉ đạt ~1.8–2.1:1 (WCAG 1.4.3 cần 4.5:1); textStrong đạt ~9:1
                // trên cta và ~5.7:1 trên secondary mà vẫn giữ nút "phát sáng".
                if (icon != null) ...<Widget>[
                  PhosphorIcon(icon!, size: 20, color: WonderColors.textStrong),
                  const SizedBox(width: WonderTokens.space8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: WonderType.button.copyWith(
                      color: WonderColors.textStrong,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...<Widget>[
                  const SizedBox(width: WonderTokens.space8),
                  PhosphorIcon(
                    trailingIcon!,
                    size: 20,
                    color: WonderColors.textStrong,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút phụ dạng chữ — cho hành động thứ cấp ("Quét lại", "Bộ sưu tập"…).
class WonderTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const WonderTextButton({
    super.key,
    required this.label,
    this.onTap,
    this.color = WonderColors.textSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.96,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: WonderTokens.space16,
          vertical: WonderTokens.space12,
        ),
        child: Text(label, style: WonderType.textButton.copyWith(color: color)),
      ),
    );
  }
}
