import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class PhotoLibrarySaveResult {
  final bool saved;
  final bool hadImage;

  const PhotoLibrarySaveResult({required this.saved, required this.hadImage});
}

/// Lưu ảnh thẻ sticker của vật vào thư viện ảnh của máy.
///
/// Không thêm plugin mới: iOS/Android tự cài qua MethodChannel
/// `wonderlens/photo_library`.
class PhotoLibraryService {
  static const MethodChannel _channel = MethodChannel(
    'wonderlens/photo_library',
  );

  Future<PhotoLibrarySaveResult> saveStickerCard({
    required GlobalKey boundaryKey,
    required String objectId,
    required String objectName,
  }) async {
    final bytes = await _capturePng(boundaryKey);
    if (bytes == null) {
      return const PhotoLibrarySaveResult(saved: false, hadImage: false);
    }

    final dir = await getTemporaryDirectory();
    final base = objectName.trim().isEmpty ? objectId : objectName;
    final safe = base.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final name = 'wonderlens_${safe.isEmpty ? 'sticker' : safe}.png';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);

    final saved =
        await _channel.invokeMethod<bool>('saveImage', {
          'path': file.path,
          'name': name,
          'album': 'WonderLens',
        }) ??
        false;
    return PhotoLibrarySaveResult(saved: saved, hadImage: true);
  }

  static Future<Uint8List?> _capturePng(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return null;

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 48));
    await WidgetsBinding.instance.endOfFrame;

    if (!context.mounted) return null;
    final object = context.findRenderObject();
    if (object is! RenderRepaintBoundary) return null;

    try {
      final image = await object.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
