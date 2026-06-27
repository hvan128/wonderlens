import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_cutout.dart';

/// Tách chủ thể khỏi nền ngay trên máy (offline, không gọi mạng) qua một
/// MethodChannel chung `wonderlens/segmentation`, cài đặt native theo nền tảng:
/// - iOS 17+: Apple Vision (`ios/Runner/AppDelegate.swift`).
/// - Android (minSdk 24+): ML Kit Subject Segmentation (`MainActivity.kt`).
/// - Nền tảng khác / iOS < 17 / không có chủ thể / lỗi → trả null để rớt về emoji.
///
/// Luôn nuốt lỗi và trả null: tách nền là tính năng "nice-to-have", không được
/// làm vỡ luồng khám phá chính.
class SegmentationService {
  static const MethodChannel _channel =
      MethodChannel('wonderlens/segmentation');

  /// Nhận đường dẫn ảnh chụp → trả PNG cutout (nền trong suốt, cắt sát chủ thể,
  /// khung vuông) hoặc null nếu không tách được.
  Future<Uint8List?> cutout(String imagePath) async {
    if (!Platform.isIOS && !Platform.isAndroid) return null;
    final Uint8List? raw = await _rawForeground(imagePath);
    if (raw == null || raw.isEmpty) return null;
    return tightCropTransparentPng(raw);
  }

  /// Ảnh foreground "thô" (nền trong suốt, kích thước nguyên khung) từ native.
  Future<Uint8List?> _rawForeground(String imagePath) async {
    try {
      return await _channel.invokeMethod<Uint8List>(
        'cutout',
        <String, dynamic>{'path': imagePath},
      );
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('segmentation platform error: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      debugPrint('segmentation error: $e');
      return null;
    }
  }
}
