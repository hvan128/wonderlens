import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import '../models/object_content.dart';

/// Gọi proxy /api/generate để AI sinh "hành trình" cho vật ngoài bộ hero.
/// Trả null nếu chưa cấu hình proxy, lỗi, hoặc AI không nhận ra (kid-safe).
class GenerateService {
  static const String _baseUrl =
      String.fromEnvironment('PROXY_BASE_URL', defaultValue: '');
  static const String _appToken =
      String.fromEnvironment('APP_TOKEN', defaultValue: 'dev-wonderlens');

  static bool get available => _baseUrl.isNotEmpty;

  Future<ObjectContent?> generate(List<int> imageBytes) async {
    if (_baseUrl.isEmpty) return null;
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/api/generate'),
            headers: {
              'Content-Type': 'application/json',
              'x-app-token': _appToken,
            },
            body: jsonEncode({'image_base64': base64Encode(imageBytes)}),
          )
          .timeout(const Duration(seconds: 35));
      if (res.statusCode != 200) {
        debugPrint('generate proxy status ${res.statusCode}: ${res.body}');
        return null;
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final content = ObjectContent.fromJson(json, source: 'live');
      // AI báo không nhận ra / không phù hợp → coi như không có kết quả.
      if (content.stages.isEmpty || content.name.toLowerCase() == 'unknown') {
        return null;
      }
      return content;
    } catch (e) {
      debugPrint('generate error: $e');
      return null;
    }
  }
}
