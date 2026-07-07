import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../data/app_settings.dart';
import 'speech_service.dart';

/// Đọc to nội dung. Bật API thật → **giọng OpenAI** (MP3 cache từ proxy, phát
/// qua **just_audio**). Dùng MỘT [AudioPlayer] tái sử dụng: đổi đoạn chỉ cần
/// `setFilePath` (rất nhanh) thay vì tạo/huỷ controller mỗi đoạn như video_player
/// → gần như không còn khoảng lặng đầu mỗi chặng (ADR-011). Offline/lỗi → rớt về
/// **giọng máy** on-device (flutter_tts) để không bao giờ im. Lỗi nuốt best-effort.
class NarrationService {
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  final SpeechService _speech = SpeechService();

  AudioPlayer? _player;
  Completer<void>? _playDone;
  bool _stopped = false;
  bool _sessionReady = false;

  /// Cấu hình iOS audio session sang **playback** (ra loa, bỏ qua công tắc im)
  /// MỘT lần — thiếu bước này just_audio phát mà không có tiếng.
  Future<void> _ensureSession() async {
    if (_sessionReady) return;
    try {
      final session = await AudioSession.instance;
      // music() = category playback → ra LOA, to, bỏ qua công tắc im (speech()
      // dùng mode spokenAudio có thể định tuyến khác). setActive để chắc chắn bật.
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
      _sessionReady = true;
    } catch (e) {
      debugPrint('audio session config error: $e');
    }
  }

  Future<void> _ensureTts() async {
    if (_ttsReady) return;
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.58); // nhịp nhanh gọn
    await _tts.setPitch(1.1);
    await _tts.awaitSpeakCompletion(true);
    _ttsReady = true;
  }

  /// Đọc một đoạn, chờ tới khi đọc xong (hoặc bị stop()).
  Future<void> speak(String text) async {
    _stopped = false;
    if (text.trim().isEmpty) return;
    if (AppSettings.useLiveApi) {
      final ok = await _speakOpenAI(text);
      if (ok || _stopped) return;
      // Lỗi giọng OpenAI → rớt về giọng máy để vẫn có tiếng.
    }
    await _speakDevice(text);
  }

  Future<bool> _speakOpenAI(String text) async {
    final file = await _speech.synthesize(text);
    if (file == null) return false;
    if (_stopped) return true;
    try {
      await _ensureSession();
      final player = _player ??= AudioPlayer();
      await player.setFilePath(file.path); // nhanh với file local đã cache
      if (_stopped) return true;

      // Hoàn tất khi phát HẾT (processingState.completed) HOẶC bị stop() (stop()
      // complete _playDone) — khớp hợp đồng timeline dựa vào: speak() trả về
      // giống nhau ở cả hai trường hợp.
      final done = Completer<void>();
      _playDone = done;
      final sub = player.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed &&
            !done.isCompleted) {
          done.complete();
        }
      });
      unawaited(player.play());
      await done.future;
      await sub.cancel();
      _playDone = null;
      return true;
    } catch (e) {
      debugPrint('just_audio play error: $e');
      _playDone = null;
      return false;
    }
  }

  Future<void> _speakDevice(String text) async {
    try {
      await _ensureTts();
      await _tts.stop();
      if (_stopped) return;
      await _tts.speak(text);
    } catch (e) {
      debugPrint('device tts error: $e');
    }
  }

  Future<void> stop() async {
    _stopped = true;
    final done = _playDone;
    _playDone = null;
    if (done != null && !done.isCompleted) done.complete();
    try {
      await _player?.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _stopped = true;
    final done = _playDone;
    _playDone = null;
    if (done != null && !done.isCompleted) done.complete();
    _player?.dispose();
    _tts.stop().catchError((_) {});
  }
}
