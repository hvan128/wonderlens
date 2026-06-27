import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Cắt sát chủ thể trong một ảnh PNG đã có nền trong suốt (alpha = 0 ở nền).
///
/// Quét kênh alpha để tìm hộp bao (bounding box) của vùng đặc, rồi vẽ lại lên
/// một khung **vuông** (chủ thể canh giữa) với chút đệm — cho ra "sticker" gọn,
/// hợp với avatar tròn + ô lưới. Trả null nếu ảnh rỗng (toàn trong suốt) hoặc
/// giải mã lỗi, để gọi viên rớt về emoji.
///
/// Đây là hàm thuần (chỉ `dart:ui`), tách khỏi platform channel để test được.
Future<Uint8List?> tightCropTransparentPng(
  Uint8List pngBytes, {
  int padding = 12,
  int alphaThreshold = 16,
}) async {
  ui.Image? src;
  ui.Image? out;
  ui.Picture? picture;
  try {
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    src = frame.image;
    final int w = src.width;
    final int h = src.height;
    if (w == 0 || h == 0) return null;

    final data = await src.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    final bytes = data.buffer.asUint8List();

    int minX = w, minY = h, maxX = -1, maxY = -1;
    for (int y = 0; y < h; y++) {
      final int rowBase = y * w * 4;
      for (int x = 0; x < w; x++) {
        final int a = bytes[rowBase + x * 4 + 3];
        if (a > alphaThreshold) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    // Không có pixel đặc nào → coi như không tách được chủ thể.
    if (maxX < minX || maxY < minY) return null;

    minX = (minX - padding).clamp(0, w - 1);
    minY = (minY - padding).clamp(0, h - 1);
    maxX = (maxX + padding).clamp(0, w - 1);
    maxY = (maxY + padding).clamp(0, h - 1);

    final int cropW = maxX - minX + 1;
    final int cropH = maxY - minY + 1;
    final int side = math.max(cropW, cropH);
    final double dx = (side - cropW) / 2;
    final double dy = (side - cropH) / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(
      src,
      Rect.fromLTWH(minX.toDouble(), minY.toDouble(), cropW.toDouble(),
          cropH.toDouble()),
      Rect.fromLTWH(dx, dy, cropW.toDouble(), cropH.toDouble()),
      paint,
    );
    picture = recorder.endRecording();
    out = await picture.toImage(side, side);
    final outData = await out.toByteData(format: ui.ImageByteFormat.png);
    return outData?.buffer.asUint8List();
  } catch (_) {
    return null;
  } finally {
    src?.dispose();
    out?.dispose();
    picture?.dispose();
  }
}
