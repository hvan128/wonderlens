import 'package:flutter/material.dart';
import 'phosphor_compat.dart';

import '../theme/wonder_tokens.dart';
import 'glass_surface.dart';

/// Nhãn nhỏ (tag) dùng cho vật liệu, số chặng, trạng thái AI… Icon Phosphor
/// tuỳ chọn. Tự đổi màu chữ theo tông sáng/tối.
class WonderChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final GlassTone tone;

  const WonderChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.tone = GlassTone.dark,
  });

  @override
  Widget build(BuildContext context) {
    final dark = tone == GlassTone.dark;
    final base = color ?? (dark ? Colors.white : WonderColors.teal);
    final fg = dark ? Colors.white : WonderColors.textStrong;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WonderTokens.space12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: base.withValues(alpha: dark ? 0.16 : 0.14),
        borderRadius: BorderRadius.circular(WonderTokens.radiusSm),
        border: Border.all(
          color: base.withValues(alpha: dark ? 0.28 : 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            PhosphorIcon(icon!, size: 14, color: dark ? fg : base),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
