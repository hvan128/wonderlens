import 'package:flutter/material.dart';

import '../data/capture_store.dart';
import '../ui/ui.dart';

/// Avatar tròn của một vật: nếu đã có **ảnh sản phẩm** (cutout tách nền do trẻ
/// chụp) thì hiện ảnh; nếu chưa thì rớt về **emoji** trên nền gradient (look cũ).
///
/// Lắng nghe [CaptureStore.revision] để tự cập nhật ngay khi vừa lưu ảnh mới
/// (vd: quét xong → overlay/timeline hiện ảnh thật, không cần rời màn).
class ObjectAvatar extends StatelessWidget {
  final String objectId;
  final String emoji;
  final double diameter;
  final double emojiSize;
  final double glowOpacity;

  const ObjectAvatar({
    super.key,
    required this.objectId,
    required this.emoji,
    this.diameter = 66,
    this.emojiSize = 34,
    this.glowOpacity = 0.42,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CaptureStore.revision,
      builder: (context, _, _) {
        final file = CaptureStore.instance.fileFor(objectId);
        if (file == null) {
          return _emojiBadge();
        }
        return Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2,
            ),
            boxShadow: WonderShadows.glow(WonderColors.teal,
                opacity: glowOpacity),
          ),
          child: ClipOval(
            child: Image.file(
              file,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stack) => _emojiBadge(),
            ),
          ),
        );
      },
    );
  }

  Widget _emojiBadge() {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: WonderGradients.badge,
        boxShadow: WonderShadows.glow(WonderColors.teal, opacity: glowOpacity),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }
}
