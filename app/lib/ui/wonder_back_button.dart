import 'package:flutter/material.dart';

import 'glass_surface.dart';
import 'phosphor_compat.dart';

/// Nút quay lại dùng chung — mũi tên kính tròn, thường ghim ở góc trái header.
///
/// Gói [GlassIconButton] với mũi tên trái + nhãn mặc định để mọi màn có một nút
/// back nhất quán (kích thước, tông, semantics). Router-độc lập: màn hình tự
/// truyền [onTap] để không ràng buộc lớp UI vào điều hướng.
class WonderBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final GlassTone tone;
  final double size;
  final String semanticLabel;

  const WonderBackButton({
    super.key,
    this.onTap,
    this.tone = GlassTone.light,
    this.size = 44,
    this.semanticLabel = 'Quay lại',
  });

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      icon: PhosphorIconsBold.arrowLeft,
      tone: tone,
      size: size,
      onTap: onTap,
      semanticLabel: semanticLabel,
    );
  }
}
