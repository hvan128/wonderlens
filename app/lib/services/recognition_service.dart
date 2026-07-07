import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import '../data/app_settings.dart';
import '../data/hero_catalog.dart';

/// Kết quả nhận diện vật từ proxy (OpenAI Vision) hoặc mock offline.
class RecognitionResult {
  final String objectId;
  final double confidence;
  final String displayName;
  final String source; // 'openai' | 'mock_offline' | 'mock_error'

  const RecognitionResult({
    required this.objectId,
    required this.confidence,
    required this.displayName,
    required this.source,
  });
}

/// Gọi Vercel proxy để nhận diện ảnh khi [AppSettings.useLiveApi] bật. Khi tắt
/// (Mock offline) thì trả mock_offline. Nếu đang bật API nhưng lỗi mạng/parse
/// thì trả mock_error + log để dễ phát hiện proxy hỏng (không nuốt lỗi âm thầm).
/// Mock **xoay tua** qua bộ hero để demo offline không kẹt một vật.
class RecognitionService {
  RecognitionResult mockOffline() => _mock('mock_offline');

  Future<RecognitionResult> recognize(List<int> imageBytes) async {
    if (!AppSettings.useLiveApi) {
      return mockOffline();
    }
    try {
      final res = await http
          .post(
            Uri.parse('${AppSettings.baseUrl}/api/recognize'),
            headers: {
              'Content-Type': 'application/json',
              'x-app-token': AppSettings.appToken,
            },
            body: jsonEncode({'image_base64': base64Encode(imageBytes)}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        debugPrint('recognize proxy status ${res.statusCode}: ${res.body}');
        return _mock('mock_error');
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return RecognitionResult(
        objectId: (json['object_id'] ?? 'unknown') as String,
        confidence: ((json['confidence'] ?? 0) as num).toDouble(),
        displayName: (json['display_name'] ?? 'Vật bí ẩn') as String,
        source: (json['source'] ?? 'openai') as String,
      );
    } catch (e) {
      debugPrint('recognize error: $e');
      return _mock('mock_error');
    }
  }

  /// Con trỏ xoay tua dùng chung — mỗi lần mock trả vật hero kế tiếp.
  static int _mockTurn = 0;

  RecognitionResult _mock(String source) {
    final item = heroCatalog[_mockTurn % heroCatalog.length];
    _mockTurn = (_mockTurn + 1) % heroCatalog.length;
    return RecognitionResult(
      objectId: item.id,
      confidence: 0.96,
      displayName: item.name,
      source: source,
    );
  }
}
