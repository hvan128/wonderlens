import 'package:flutter_tts/flutter_tts.dart';

/// Đọc to nội dung bằng giọng máy (offline, không cần mạng/API key).
/// Dùng tiếng Việt nếu thiết bị hỗ trợ.
class NarrationService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.45); // chậm lại cho trẻ dễ nghe
    await _tts.setPitch(1.1);
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  /// Đọc một đoạn, chờ tới khi đọc xong (hoặc bị stop()).
  Future<void> speak(String text) async {
    await _ensureReady();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  void dispose() {
    _tts.stop();
  }
}
