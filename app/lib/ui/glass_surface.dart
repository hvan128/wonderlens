import 'dart:ui';

import 'package:flutter/material.dart';
import 'phosphor_compat.dart';

import '../theme/wonder_tokens.dart';
import 'pressable.dart';

/// Hai tông kính: tối (đặt trên camera/nền rực, chữ trắng) và sáng (đặt trên
/// nền canvas dịu, chữ đậm).
enum GlassTone { dark, light }

/// Bề mặt "liquid glass" hand-rolled theo đúng công thức:
///  1. BackdropFilter = blur + tăng bão hoà (ColorFilter.matrix) → frost thật.
///  2. Gradient nền (highlight chéo) cho khối thuỷ tinh.
///  3. foregroundDecoration = vệt specular sáng ở đỉnh + rim mờ ở đáy.
///  4. Viền hairline trắng + shadow mềm.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final GlassTone tone;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? blur;
  final double? saturation;
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
    this.saturation,
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
    final op = tintOpacity ?? (_dark ? 0.40 : 0.58);
    final borderC = Colors.white.withValues(alpha: _dark ? 0.22 : 0.65);
    final specTop = _dark ? 0.28 : 0.62;
    final sat = saturation ?? (_dark ? 1.7 : 1.25);
    final sigma = blur ?? WonderTokens.glassBlur;

    Widget panel = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: ColorFilter.matrix(_saturate(sat)),
          inner: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withValues(alpha: _dark ? 0.16 : 0.36),
                baseTint.withValues(alpha: op),
                baseTint.withValues(alpha: (op + 0.06).clamp(0.0, 1.0)),
              ],
              stops: const <double>[0.0, 0.5, 1.0],
            ),
            border: Border.all(color: borderC, width: 1),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.white.withValues(alpha: specTop),
                Colors.transparent,
                Colors.transparent,
                Colors.white.withValues(alpha: _dark ? 0.05 : 0.14),
              ],
              stops: const <double>[0.0, 0.12, 0.86, 1.0],
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

  /// Ma trận 5x4 tăng/giảm bão hoà giữ nguyên độ sáng (luminance-preserving).
  static List<double> _saturate(double s) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final inv = 1 - s;
    final r = inv * lr, g = inv * lg, b = inv * lb;
    return <double>[
      r + s, g, b, 0, 0, //
      r, g + s, b, 0, 0, //
      r, g, b + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
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
        ? const Color(0xFF7A4E00)
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
