import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'phosphor_compat.dart';

import '../theme/wonder_tokens.dart';
import 'glass_surface.dart';
import 'pressable.dart';

/// Một nút hành động ở góc phải header (chia sẻ, đèn pin, về nhà…).
class WonderHeaderAction {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  /// Đang bật (vd đèn pin) → nút ánh sắc nắng.
  final bool active;

  const WonderHeaderAction({
    required this.icon,
    this.onTap,
    this.tooltip,
    this.active = false,
  });
}

/// Header dùng chung cho toàn app — thay cho `AppBar` mặc định.
///
/// Linh hoạt theo ngữ cảnh:
///  • `branded`  → logo + wordmark gradient (màn chính / camera).
///  • `title`    → tiêu đề (+ phụ đề) với nút quay lại tuỳ chọn (màn nội dung).
///  • `tone`     → sáng (trên nền canvas) hoặc tối (đè lên camera).
///  • `floating` → thanh kính bo tròn nổi (true) hoặc trong suốt phẳng (false).
///
/// Mọi điều hướng do màn hình truyền vào ([onBack], [actions]) nên lớp UI này
/// không phụ thuộc router.
class WonderHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool branded;
  final bool showBack;
  final VoidCallback? onBack;
  final List<WonderHeaderAction> actions;
  final GlassTone tone;
  final bool floating;
  final bool animate;

  const WonderHeader({
    super.key,
    this.title,
    this.subtitle,
    this.branded = false,
    this.showBack = false,
    this.onBack,
    this.actions = const <WonderHeaderAction>[],
    this.tone = GlassTone.light,
    this.floating = true,
    this.animate = true,
  });

  bool get _dark => tone == GlassTone.dark;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: <Widget>[
        if (showBack) ...<Widget>[
          _CircleButton(
            icon: PhosphorIconsBold.arrowLeft,
            onTap: onBack,
            tone: tone,
            floating: floating,
            tooltip: 'Quay lại',
          ),
          const SizedBox(width: WonderTokens.space12),
        ] else if (branded) ...<Widget>[
          _Logo(dark: _dark),
          const SizedBox(width: WonderTokens.space12),
        ],
        Expanded(
          child: branded
              ? _Wordmark(dark: _dark)
              : _TitleBlock(
                  title: title ?? '',
                  subtitle: subtitle,
                  dark: _dark,
                ),
        ),
        for (var i = 0; i < actions.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: WonderTokens.space8),
          _CircleButton(
            icon: actions[i].icon,
            onTap: actions[i].onTap,
            tone: tone,
            floating: floating,
            active: actions[i].active,
            tooltip: actions[i].tooltip,
          ),
        ],
      ],
    );

    Widget bar;
    if (floating) {
      bar = Padding(
        padding: const EdgeInsets.fromLTRB(
          WonderTokens.space16,
          WonderTokens.space8,
          WonderTokens.space16,
          0,
        ),
        child: GlassSurface(
          tone: tone,
          radius: WonderTokens.radiusLg,
          padding: const EdgeInsets.symmetric(
            horizontal: WonderTokens.space12,
            vertical: WonderTokens.space8,
          ),
          child: row,
        ),
      );
    } else {
      bar = Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 14, 0),
        child: row,
      );
    }

    if (!animate) return bar;
    return bar
        .animate()
        .fadeIn(duration: WonderTokens.durBase)
        .slideY(begin: -0.4, end: 0, curve: WonderTokens.curveStandard);
  }
}

class _TitleBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool dark;

  const _TitleBlock({required this.title, this.subtitle, required this.dark});

  @override
  Widget build(BuildContext context) {
    final strong = dark ? Colors.white : WonderColors.textStrong;
    final soft = dark
        ? Colors.white.withValues(alpha: 0.75)
        : WonderColors.textSoft;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WonderType.title.copyWith(color: strong),
        ),
        if (subtitle != null && subtitle!.isNotEmpty)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WonderType.caption.copyWith(color: soft),
          ),
      ],
    );
  }
}

/// Logo nhỏ: huy hiệu tròn gradient + ống nhòm.
class _Logo extends StatelessWidget {
  final bool dark;
  const _Logo({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: WonderGradients.badge,
        boxShadow: WonderShadows.glow(WonderColors.teal, opacity: 0.4),
      ),
      child: const Center(
        child: PhosphorIcon(
          PhosphorIconsDuotone.binoculars,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Chữ thương hiệu WonderLens với gradient.
class _Wordmark extends StatelessWidget {
  final bool dark;
  const _Wordmark({required this.dark});

  @override
  Widget build(BuildContext context) {
    final colors = dark
        ? const <Color>[Colors.white, Color(0xFFD9F6FB)]
        : const <Color>[
            WonderColors.tealDeep,
            WonderColors.sky,
            WonderColors.grape,
          ];
    return ShaderMask(
      shaderCallback: (rect) =>
          LinearGradient(colors: colors).createShader(rect),
      child: Text(
        'WonderLens',
        // Trắng để ShaderMask nhuộm gradient; cỡ 22 nhỉnh hơn title thường.
        style: WonderType.title.copyWith(
          fontSize: 22,
          color: Colors.white,
          shadows: dark
              ? const <Shadow>[Shadow(color: Colors.black54, blurRadius: 8)]
              : null,
        ),
      ),
    );
  }
}

/// Nút tròn của header. Trên thanh kính (floating) dùng tông phẳng nhẹ để tránh
/// "kính chồng kính"; khi trong suốt (trên camera) dùng nút kính nổi.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final GlassTone tone;
  final bool floating;
  final bool active;
  final String? tooltip;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.tone,
    required this.floating,
    this.active = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (!floating) {
      // Non-floating chỉ dùng đè trực tiếp camera preview → blur: 0 để giữ
      // ngân sách ≤3 bề mặt blur (DESIGN.md §6).
      Widget button = GlassIconButton(
        icon: icon,
        onTap: onTap,
        tone: tone,
        active: active,
        size: 48,
        semanticLabel: tooltip,
        blur: 0,
      );
      // Cùng hợp đồng với nhánh floating: có tooltip là phải bọc Tooltip
      // (test tap bằng find.byTooltip; long-press phải hiện nhãn).
      if (tooltip != null) {
        button = Tooltip(message: tooltip!, child: button);
      }
      return button;
    }

    final dark = tone == GlassTone.dark;
    final fg = active
        ? const Color(0xFF7A4E00)
        : (dark ? Colors.white : WonderColors.textStrong);
    final base = dark ? Colors.white : WonderColors.textStrong;
    final bg = active
        ? WonderColors.sunny.withValues(alpha: 0.92)
        : base.withValues(alpha: dark ? 0.16 : 0.07);

    Widget button = Pressable(
      onTap: onTap,
      semanticLabel: tooltip,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: Center(child: PhosphorIcon(icon, size: 21, color: fg)),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
