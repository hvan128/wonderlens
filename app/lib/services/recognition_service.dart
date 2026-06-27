import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

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

/// Gọi Vercel proxy để nhận diện ảnh. Nếu chưa cấu hình proxy thì trả mock
/// (mock_offline). Nếu có proxy nhưng lỗi mạng/parse thì trả mock_error +
/// log để dễ phát hiện proxy hỏng (không nuốt lỗi âm thầm).
class RecognitionService {
  /// Override khi chạy: flutter run --dart-define=PROXY_BASE_URL=https://...
  static const String _baseUrl =
      String.fromEnvironment('PROXY_BASE_URL', defaultValue: '');

  /// Shared secret khớp APP_SHARED_SECRET ở proxy.
  static const String _appToken =
      String.fromEnvironment('APP_TOKEN', defaultValue: 'dev-wonderlens');

  Future<RecognitionResult> recognize(List<int> imageBytes) async {
    if (_baseUrl.isEmpty) {
      return _mock('mock_offline');
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/api/recognize'),
            headers: {
              'Content-Type': 'application/json',
              'x-app-token': _appToken,
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

  RecognitionResult _mock(String source) => RecognitionResult(
        objectId: 'paper_cup',
        confidence: 0.96,
        displayName: 'Cốc giấy',
        source: source,
      );
}
