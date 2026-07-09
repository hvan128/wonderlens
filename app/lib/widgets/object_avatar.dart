import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

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

  /// Bề dày viền trắng die-cut theo tỉ lệ [diameter] (chỉ khi [sticker]). Mặc
  /// định 0.06; hạ xuống cho viền mảnh hơn (vd bày trên card giấy).
  final double stickerBorderFactor;

  /// Bóng đổ mềm (blur) sau sticker. TẮT khi render trong Hero overlay lúc bay:
  /// ImageFiltered trong overlay có thể nháy đen 1 frame (glitch Impeller) và
  /// blur lại mỗi frame rất tốn.
  final bool stickerShadow;

  const ObjectAvatar({
    super.key,
    required this.objectId,
    required this.emoji,
    this.diameter = 66,
    this.emojiSize = 34,
    this.glowOpacity = 0.42,
    this.hero = false,
    this.sticker = false,
    this.stickerBorderFactor = 0.06,
    this.stickerShadow = true,
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
            boxShadow: WonderShadows.glow(
              WonderColors.teal,
              opacity: glowOpacity,
            ),
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
    final border = (diameter * stickerBorderFactor).clamp(2.0, 7.0);
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
    // srcATop + màu: giữ nguyên alpha ảnh nhưng nhuộm đặc → silhouette theo hình.
    Widget silhouette(Color c) => ColorFiltered(
      colorFilter: ColorFilter.mode(c, BlendMode.srcATop),
      child: Image.file(
        file,
        width: inner,
        height: inner,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
    // Bóng đổ mềm ôm theo hình (đặt sau lưng) → sticker nổi trên mọi nền, kể cả
    // nền sáng đồng tông (viền trắng vẫn tách khỏi nền).
    final Widget shadow = Transform.translate(
      offset: Offset(0, border * 0.9),
      child: Opacity(
        opacity: 0.22,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: border, sigmaY: border),
          child: silhouette(Colors.black),
        ),
      ),
    );

    // RepaintBoundary: raster sticker (gồm cả blur bóng) MỘT lần → lúc kéo modal
    // chỉ re-composite (transform), không blur lại mỗi frame ⇒ hết giật.
    return RepaintBoundary(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (stickerShadow) shadow,
            for (var i = 0; i < 8; i++)
              Transform.translate(
                offset:
                    Offset(
                      math.cos(i * math.pi / 4),
                      math.sin(i * math.pi / 4),
                    ) *
                    border,
                child: silhouette(Colors.white),
              ),
            photo(),
          ],
        ),
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
