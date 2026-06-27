import 'package:flutter/material.dart';
import 'phosphor_compat.dart';

import '../theme/wonder_tokens.dart';
import 'pressable.dart';

/// Nút hành động chính: nền gradient thương hiệu, glow mềm, phản hồi chạm mềm,
/// icon Phosphor tuỳ chọn ở đầu/cuối.
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
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: WonderTokens.space24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
          boxShadow: WonderShadows.glow(WonderColors.teal, opacity: 0.45),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              PhosphorIcon(icon!, size: 20, color: Colors.white),
              const SizedBox(width: WonderTokens.space8),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (trailingIcon != null) ...<Widget>[
              const SizedBox(width: WonderTokens.space8),
              PhosphorIcon(trailingIcon!, size: 20, color: Colors.white),
            ],
          ],
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
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
