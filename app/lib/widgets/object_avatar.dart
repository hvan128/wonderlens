import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/capture_store.dart';
import '../ui/ui.dart';

/// Avatar tròn của một vật: nếu đã có **ảnh sản phẩm** (cutout tách nền do trẻ
/// chụp) thì hiện ảnh; nếu chưa thì rớt về **emoji** trên nền gradient (look cũ).
///
/// Lắng nghe [CaptureStore.revision] để tự cập nhật ngay khi vừa lưu ảnh mới
/// (vd: quét xong → overlay/timeline hiện ảnh thật, không cần rời màn).
///
/// [hero] = true → bọc trong [Hero] tag theo [objectId]: avatar "bay" giữa
/// hai màn khi chuyển route (thẻ khám phá → timeline, ô sưu tập → timeline).
/// Mỗi route chỉ được có MỘT avatar hero cho cùng một vật.
class ObjectAvatar extends StatelessWidget {
  final String objectId;
  final String emoji;
  final double diameter;
  final double emojiSize;
  final double glowOpacity;
  final bool hero;

  /// `sticker` = true → hiện ảnh cutout **die-cut viền trắng** (không cắt tròn),
  /// kiểu miếng dán theo đúng hình vật. Không có ảnh thật → rớt về emoji badge.
  final bool sticker;

  const ObjectAvatar({
    super.key,
    required this.objectId,
    required this.emoji,
    this.diameter = 66,
    this.emojiSize = 34,
    this.glowOpacity = 0.42,
    this.hero = false,
    this.sticker = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar();
    if (!hero) return avatar;
    // Material transparency: subtree bay trong overlay của Navigator (ngoài
    // cây Material thường) — thiếu nó Text emoji sẽ vẽ style debug lỗi.
    return Hero(
      tag: 'object-avatar-$objectId',
      child: Material(type: MaterialType.transparency, child: avatar),
    );
  }

  Widget _buildAvatar() {
    return ValueListenableBuilder<int>(
      valueListenable: CaptureStore.revision,
      builder: (context, _, _) {
        final file = CaptureStore.instance.fileFor(objectId);
        if (file == null) {
          return _emojiBadge();
        }
        if (sticker) {
          return _stickerCutout(file);
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

  /// Ảnh cutout die-cut: viền trắng theo đúng silhouette của vật. Vẽ nhiều bản
  /// silhouette-trắng lệch quanh 8 hướng (dựng chắc trên mọi backend, không phụ
  /// thuộc ImageFilter.dilate) rồi đặt ảnh thật lên trên. Ảnh render nhỏ hơn
  /// khung [diameter] đúng bằng bề dày viền để đường viền không bị cắt mép.
  Widget _stickerCutout(File file) {
    final border = (diameter * 0.06).clamp(3.0, 7.0);
    final inner = diameter - border * 2;

    Widget photo() => Image.file(
      file,
      width: inner,
      height: inner,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stack) => _emojiBadge(),
    );
    // srcATop + trắng: giữ nguyên alpha ảnh nhưng nhuộm trắng toàn bộ → silhouette.
    Widget whiteSilhouette() => ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop),
      child: Image.file(
        file,
        width: inner,
        height: inner,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          for (var i = 0; i < 8; i++)
            Transform.translate(
              offset:
                  Offset(math.cos(i * math.pi / 4), math.sin(i * math.pi / 4)) *
                  border,
              child: whiteSilhouette(),
            ),
          photo(),
        ],
      ),
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
