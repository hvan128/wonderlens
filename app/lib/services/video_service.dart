import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import '../models/object_content.dart';

/// Tạo "video hành trình" cho vật lạ (AI-live) qua proxy: khởi động job →
/// poll trạng thái → tải MP4 về file tạm để phát (phát từ file ổn định hơn
/// stream mạng trên iOS). Trả null nếu chưa cấu hình proxy / lỗi / hết giờ.
class VideoService {
  static const String _baseUrl =
      String.fromEnvironment('PROXY_BASE_URL', defaultValue: '');
  static const String _appToken =
      String.fromEnvironment('APP_TOKEN', defaultValue: 'dev-wonderlens');

  static bool get available => _baseUrl.isNotEmpty;

  /// Sinh video cho [content]. Gọi [onProgress] (0..100) trong lúc render.
  Future<File?> generate(
    ObjectContent content, {
    void Function(int progress)? onProgress,
  }) async {
    if (_baseUrl.isEmpty) return null;
    try {
      onProgress?.call(0);
      final videoId = await _create(content);
      if (videoId == null) return null;

      // Poll ~9s/lần, dừng theo wall-clock (~4 phút) để mạng chậm không kẹt lâu;
      // maxAttempts là chặn an toàn cứng.
      const maxAttempts = 40;
      const maxWall = Duration(minutes: 4);
      final clock = Stopwatch()..start();
      for (var i = 0; i < maxAttempts; i++) {
        if (clock.elapsed > maxWall) break;
        await Future<void>.delayed(const Duration(seconds: 9));
        final status = await _status(videoId);
        if (status == null) continue; // lỗi tạm thời → thử lại
        onProgress?.call(status.progress);
        if (status.state == 'completed') {
          return _download(videoId);
        }
        if (status.state == 'failed' || status.state == 'expired') {
          debugPrint('video job ${status.state}: ${status.error}');
          return null;
        }
      }
      debugPrint('video poll timeout cho $videoId');
      return null;
    } catch (e) {
      debugPrint('video generate error: $e');
      return null;
    }
  }

  Future<String?> _create(ObjectContent content) async {
    final res = await http
        .post(
          Uri.parse('$_baseUrl/api/video/create'),
          headers: {
            'Content-Type': 'application/json',
            'x-app-token': _appToken,
          },
          body: jsonEncode({
            'name': content.name,
            'material_badge': content.materialBadge,
            'stages': content.stages
                .map((s) => {'title': s.title, 'kid_text': s.kidText})
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      debugPrint('video create ${res.statusCode}: ${res.body}');
      return null;
    }
    final id = (jsonDecode(res.body) as Map<String, dynamic>)['video_id'];
    return (id is String && id.isNotEmpty) ? id : null;
  }

  Future<_VideoStatus?> _status(String videoId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/video/status?id=$videoId'),
        headers: {'x-app-token': _appToken},
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        debugPrint('video status ${res.statusCode}: ${res.body}');
        return null;
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return _VideoStatus(
        state: (json['status'] ?? '') as String,
        progress: ((json['progress'] ?? 0) as num).toInt(),
        error: json['error'] as String?,
      );
    } catch (e) {
      debugPrint('video status error: $e');
      return null;
    }
  }

  Future<File?> _download(String videoId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/video/content?id=$videoId'),
        headers: {'x-app-token': _appToken},
      ).timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) {
        debugPrint('video content ${res.statusCode}: ${res.body}');
        return null;
      }
      final file = File('${Directory.systemTemp.path}/wonderlens_$videoId.mp4');
      await file.writeAsBytes(res.bodyBytes);
      return file;
    } catch (e) {
      debugPrint('video download error: $e');
      return null;
    }
  }
}

class _VideoStatus {
  final String state;
  final int progress;
  final String? error;
  const _VideoStatus({
    required this.state,
    required this.progress,
    this.error,
  });
}
