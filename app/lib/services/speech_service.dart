import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/app_settings.dart';

/// Tải giọng đọc OpenAI (MP3) từ proxy `/api/speech` và cache theo nội dung
/// (cùng văn bản → dùng lại file, không gọi lại OpenAI). Trả null khi lỗi/không
/// cấu hình để [NarrationService] rớt về giọng máy on-device.
class SpeechService {
  /// Bump khi đổi giọng/tốc độ/model ở proxy → bỏ qua audio cache cũ, tải lại.
  static const _voiceVersion = 'v2';

  // STATIC để dùng chung giữa MỌI instance (warm-up pre-sinh + NarrationService
  // đọc lại): cache file đã tải + dedup synth đang chạy (cùng text → chờ chung,
  // không gọi proxy 2 lần, không đọc trúng file đang ghi dở).
  static final Map<String, File> _mem = {};
  static final Map<String, Future<File?>> _inflight = {};

  Future<File?> synthesize(String text) {
    final t = text.trim();
    if (t.isEmpty) return Future<File?>.value(null);
    final key =
        '${_voiceVersion}_${t.hashCode.toUnsigned(32).toRadixString(16)}';
    return _inflight.putIfAbsent(
      key,
      () => _synth(t, key).whenComplete(() => _inflight.remove(key)),
    );
  }

  Future<File?> _synth(String t, String key) async {
    final cached = _mem[key];
    if (cached != null && await cached.exists()) return cached;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/wl_tts_$key.mp3');
      if (await file.exists() && await file.length() > 0) {
        _mem[key] = file;
        return file;
      }
      final res = await http
          .post(
            Uri.parse('${AppSettings.baseUrl}/api/speech'),
            headers: {
              'Content-Type': 'application/json',
              'x-app-token': AppSettings.appToken,
            },
            body: jsonEncode({'text': t}),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        debugPrint('speech proxy ${res.statusCode}: ${res.body}');
        return null;
      }
      // Ghi ATOMIC: ghi .part rồi rename → reader không bao giờ đọc file nửa vời.
      final tmp = File('${file.path}.part');
      await tmp.writeAsBytes(res.bodyBytes);
      await tmp.rename(file.path);
      _mem[key] = file;
      return file;
    } catch (e) {
      debugPrint('speech error: $e');
      return null;
    }
  }
}
