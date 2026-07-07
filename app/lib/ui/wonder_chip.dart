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
    final br = BorderRadius.circular(WonderTokens.radiusSm);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WonderTokens.space12,
        vertical: WonderTokens.space8,
      ),
      decoration: BoxDecoration(
        color: base.withValues(alpha: dark ? 0.16 : 0.14),
        borderRadius: br,
        border: Border.all(
          color: base.withValues(alpha: dark ? 0.28 : 0.30),
        ),
      ),
      // Sheen mềm ở đỉnh — cùng chất kính với GlassSurface, không đổi layout.
      foregroundDecoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.10),
            Colors.transparent,
          ],
          stops: const <double>[0.0, 0.55],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            PhosphorIcon(icon!, size: 14, color: dark ? fg : base),
            const SizedBox(width: 6),
          ],
          // Nhãn dài (vật liệu AI-live) cắt bớt thay vì tràn khỏi pill.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WonderType.label.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
