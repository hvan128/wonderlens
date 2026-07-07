import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/object_content.dart';

/// Mở khay chia sẻ của hệ thống cho một lần khám phá hoặc cả bộ sưu tập.
///
/// Ưu tiên chia sẻ **ảnh thẻ** (đẹp để khoe) kèm caption; nếu chụp ảnh lỗi vì
/// bất cứ lý do gì thì tự rơi về **chia sẻ text** — demo không bao giờ vỡ.
class ShareService {
  /// Caption cho một lần khám phá (dùng cho cả ảnh lẫn fallback text-only).
  static String caption(ObjectContent c) {
    final stages = c.stages.map((s) => '• ${s.title}').join('\n');
    return 'Mình vừa mở khóa hành trình khoa học về "${c.name}" ${c.emoji} '
        'trên WonderLens!\n\n'
        '$stages\n\n'
        'Tải WonderLens để soi đồ vật, mở manh mối và gom huy hiệu nhé! 🔭';
  }

  /// Caption khoe thành tích bộ sưu tập.
  static String collectionCaption({
    required String levelTitle,
    required int discoveredCount,
    required int totalCount,
    required int earnedCount,
  }) {
    return 'Mình đang là "$levelTitle" trên WonderLens! 🔭\n'
        'Đã mở khóa $discoveredCount/$totalCount đồ vật và gom $earnedCount '
        'huy hiệu vật liệu 🏅\n\n'
        'Cùng tải WonderLens để biến đồ vật quanh mình thành câu chuyện khoa học nhé!';
  }

  /// Chia sẻ một lần khám phá (màn Hành trình).
  static Future<void> shareDiscovery({
    required GlobalKey boundaryKey,
    required ObjectContent content,
    Rect? origin,
  }) {
    return _shareImageOrText(
      boundaryKey: boundaryKey,
      text: caption(content),
      subject: 'WonderLens — Nhiệm vụ khoa học về ${content.name}',
      fileBase: 'discovery_${content.id}',
      origin: origin,
    );
  }

  /// Chia sẻ thành tích bộ sưu tập (màn Bộ sưu tập).
  static Future<void> shareCollection({
    required GlobalKey boundaryKey,
    required String levelTitle,
    required int discoveredCount,
    required int totalCount,
    required int earnedCount,
    Rect? origin,
  }) {
    return _shareImageOrText(
      boundaryKey: boundaryKey,
      text: collectionCaption(
        levelTitle: levelTitle,
        discoveredCount: discoveredCount,
        totalCount: totalCount,
        earnedCount: earnedCount,
      ),
      subject: 'WonderLens — Rương khám phá của mình',
      fileBase: 'collection',
      origin: origin,
    );
  }

  /// Lõi chung: chụp [boundaryKey] thành PNG rồi mở khay chia sẻ; lỗi thì gửi text.
  /// [origin] là vị trí nút bấm (cần cho iPad để neo popover share sheet).
  static Future<void> _shareImageOrText({
    required GlobalKey boundaryKey,
    required String text,
    required String subject,
    required String fileBase,
    Rect? origin,
  }) async {
    try {
      final bytes = await _capturePng(boundaryKey);
      if (bytes == null) {
        await _shareText(text, origin);
        return;
      }
      final dir = await getTemporaryDirectory();
      final safe = fileBase.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final file = File('${dir.path}/wonderlens_$safe.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
          files: <XFile>[XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      // Bất kỳ lỗi nào (chụp ảnh / ghi file / nền tảng) đều rơi về text.
      await _shareText(text, origin);
    }
  }

  static Future<void> _shareText(String text, Rect? origin) async {
    await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
  }

  static Future<Uint8List?> _capturePng(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return null;
    final object = context.findRenderObject();
    if (object is! RenderRepaintBoundary) return null;
    // pixelRatio 3 → ảnh nét trên màn retina/khi gửi lên mạng xã hội.
    final image = await object.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }
}
