import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/wonder_tokens.dart';
import 'phosphor_compat.dart';
import 'pressable.dart';

/// Hai tông kính: tối (đặt trên camera/nền rực, chữ trắng) và sáng (đặt trên
/// nền canvas dịu, chữ đậm).
enum GlassTone { dark, light }

/// Bề mặt "liquid glass": làm nhoè nền phía sau + lớp phủ trong mờ + viền
/// hairline + một vệt sáng (sheen) dịu ở đỉnh. Cố ý KHÔNG dùng ColorFilter bão
/// hoà trên BackdropFilter vì nó gây viền tối ở mép (artifact premultiplied
/// alpha) — chỉ blur thuần cho sạch.
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
    final op = tintOpacity ?? (_dark ? 0.34 : 0.46);
    final borderC = Colors.white.withValues(alpha: _dark ? 0.24 : 0.55);
    final sheen = _dark ? 0.14 : 0.30;
    final sigma = blur ?? WonderTokens.glassBlur;

    Widget panel = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
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
          // Vệt sáng mềm ở đỉnh (không phải dải cứng) → cạnh kính "bắt sáng".
          foregroundDecoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.white.withValues(alpha: sheen),
                Colors.transparent,
              ],
              stops: const <double>[0.0, 0.55],
            ),
          ),
          child: child,
        ),
      ),
    );

    panel = DecoratedBox(
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

/// Nút tròn bằng kính, icon Phosphor. [active] → ánh sắc nắng (vd đèn pin bật).
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool active;
  final GlassTone tone;
  final String? semanticLabel;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = WonderTokens.iconBtnSize,
    this.active = false,
    this.tone = GlassTone.dark,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dark = tone == GlassTone.dark;
    final iconColor = active
        ? WonderColors.onSpark
        : (dark ? Colors.white : WonderColors.textStrong);
    return GlassSurface(
      tone: tone,
      radius: size / 2,
      padding: EdgeInsets.zero,
      onTap: onTap,
      semanticLabel: semanticLabel,
      tint: active ? WonderColors.sunny : null,
      tintOpacity: active ? 0.5 : null,
      shadows: active ? WonderShadows.glow(WonderColors.sunny, opacity: 0.5) : null,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: PhosphorIcon(icon, size: size * 0.42, color: iconColor),
        ),
      ),
    );
  }
}
