import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'phosphor_compat.dart';

import '../theme/wonder_tokens.dart';
import '../theme/wonder_typography.dart';
import 'pressable.dart';

/// Nút hành động chính kiểu "chunky 3D" (học Duolingo): mặt gradient thương
/// hiệu nổi trên một cạnh dưới sẫm màu; khi bấm, mặt nút lún xuống che cạnh —
/// cảm giác vật lý rõ ràng cho trẻ, kèm haptic. API giữ nguyên như bản cũ nên
/// không phải sửa call-site.
class WonderButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool expand;
  final Gradient gradient;
  final double height;

  /// Màu chữ/icon (mặc định trắng). Đặt mực nâu cho nút vàng tia sáng.
  final Color foreground;

  /// Màu glow dưới nút (mặc định tím). Đổi sang vàng cho CTA tia sáng.
  final Color glowColor;

  /// Màu cạnh 3D dưới nút; mặc định tự sẫm hoá từ màu cuối của gradient.
  final Color? edgeColor;

  const WonderButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.gradient = WonderGradients.cta,
    this.height = 56,
    this.foreground = Colors.white,
    this.glowColor = WonderColors.wonder,
    this.edgeColor,
  });

  @override
  State<WonderButton> createState() => _WonderButtonState();
}

class _WonderButtonState extends State<WonderButton> {
  /// Độ dày cạnh 3D — cũng là quãng lún khi bấm.
  static const double _edge = 4;

  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  Color get _edgeColor {
    if (widget.edgeColor != null) return widget.edgeColor!;
    final hsl = HSLColor.fromColor(widget.gradient.colors.last);
    return hsl
        .withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(WonderTokens.radiusMd);
    final enabled = widget.onTap != null;

    final face = AnimatedContainer(
      duration: WonderTokens.durFast,
      curve: Curves.easeOut,
      // Lún xuống bằng transform (không đổi layout) → mượt, không giật khối.
      transform: Matrix4.translationValues(0, _down ? _edge : 0, 0),
      height: widget.height,
      width: widget.expand ? double.infinity : null,
      margin: const EdgeInsets.only(bottom: _edge),
      padding: const EdgeInsets.symmetric(horizontal: WonderTokens.space24),
      decoration: BoxDecoration(
        gradient: widget.gradient,
        borderRadius: radius,
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (widget.icon != null) ...<Widget>[
            PhosphorIcon(widget.icon!, size: 20, color: widget.foreground),
            const SizedBox(width: WonderTokens.space8),
          ],
          Flexible(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              style: WonderType.display(
                color: widget.foreground,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (widget.trailingIcon != null) ...<Widget>[
            const SizedBox(width: WonderTokens.space8),
            PhosphorIcon(
              widget.trailingIcon!,
              size: 20,
              color: widget.foreground,
            ),
          ],
        ],
      ),
    );

    Widget button = Stack(
      children: <Widget>[
        // Cạnh 3D + glow: phủ vùng nút, hở ra `_edge` px dưới mặt nút.
        Positioned.fill(
          top: _edge,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _edgeColor,
              borderRadius: radius,
              boxShadow: WonderShadows.glow(widget.glowColor, opacity: 0.35),
            ),
          ),
        ),
        face,
      ],
    );

    if (!enabled) {
      button = Opacity(opacity: 0.55, child: button);
    }

    return Semantics(
      button: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) {
          _set(false);
          if (widget.onTap == null) return;
          HapticFeedback.selectionClick();
          widget.onTap!();
        },
        child: button,
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
        child: Text(
          label,
          style: WonderType.body(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
