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
  final Map<String, File> _mem = {};

  Future<File?> synthesize(String text) async {
    final t = text.trim();
    if (t.isEmpty) return null;
    final key = t.hashCode.toUnsigned(32).toRadixString(16);

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
      await file.writeAsBytes(res.bodyBytes);
      _mem[key] = file;
      return file;
    } catch (e) {
      debugPrint('speech error: $e');
      return null;
    }
  }
}
