import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:video_player/video_player.dart';

import '../data/app_settings.dart';
import 'speech_service.dart';

/// Tạm thời ép mọi narration dùng TTS mặc định của hệ điều hành để phản hồi nhanh.
/// Đổi về `false` để quay lại đường OpenAI speech qua [SpeechService].
final bool kUseDeviceTtsOnly = true;

/// Đọc to nội dung. Mặc định hiện tại → **giọng máy** (flutter_tts) cho nhanh.
/// Khi [kUseDeviceTtsOnly] = false và API thật bật → thử giọng OpenAI (MP3 từ
/// proxy, phát qua video_player — audio-only), lỗi thì rớt về giọng máy.
/// Lỗi nuốt best-effort — giọng là phụ trợ, không chặn flow.
///
/// Trước mỗi lần đọc set audio session sang **playback** (loa ngoài): camera để
/// session ở `playAndRecord` (định tuyến ra loa tai) nên phải ép lại.
class NarrationService {
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  final SpeechService _speech = SpeechService();

  VideoPlayerController? _audio;
  Completer<void>? _playDone;
  bool _stopped = false;

  Future<void> _ensureSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
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
    await _ensureSession(); // ép loa ngoài cho cả video_player lẫn giọng máy
    if (!kUseDeviceTtsOnly && AppSettings.useLiveApi) {
      final ok = await _speakOpenAI(text);
      if (ok || _stopped) return;
      // Lỗi giọng OpenAI → rớt về giọng máy để vẫn có tiếng.
    }
    await _speakDevice(text);
  }

  /// Phát giọng đọc đã pre-gen từ asset; lỗi/missing thì đọc [fallbackText].
  Future<void> speakAsset(String assetPath, String fallbackText) async {
    _stopped = false;
    if (assetPath.trim().isEmpty) {
      await speak(fallbackText);
      return;
    }
    await _ensureSession();
    final ok = await _playAudioController(
      VideoPlayerController.asset(assetPath),
      debugLabel: 'asset audio',
    );
    if (ok || _stopped) return;
    await speak(fallbackText);
  }

  Future<bool> _speakOpenAI(String text) async {
    final file = await _speech.synthesize(text);
    if (file == null) return false;
    if (_stopped) return true;
    return _playAudioController(
      VideoPlayerController.file(file),
      debugLabel: 'openai tts',
    );
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

  Future<bool> _playAudioController(
    VideoPlayerController ctrl, {
    required String debugLabel,
  }) async {
    try {
      await _tts.stop();
      await _disposeAudio();
      _audio = ctrl;
      await ctrl.initialize();
      if (_stopped) {
        await _disposeAudio();
        return true;
      }
      final done = Completer<void>();
      _playDone = done;
      void onTick() {
        final v = ctrl.value;
        final finished =
            v.isCompleted ||
            v.hasError ||
            (v.duration > Duration.zero && v.position >= v.duration);
        if (finished && !done.isCompleted) done.complete();
      }

      ctrl.addListener(onTick);
      await ctrl.play();
      await done.future;
      ctrl.removeListener(onTick);
      _playDone = null;
      await _disposeAudio();
      return true;
    } catch (e) {
      debugPrint('$debugLabel play error: $e');
      _playDone = null;
      await _disposeAudio();
      return false;
    }
  }

  Future<void> stop() async {
    _stopped = true;
    final done = _playDone;
    if (done != null && !done.isCompleted) done.complete();
    _playDone = null;
    try {
      await _audio?.pause();
    } catch (_) {}
    await _disposeAudio();
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> _disposeAudio() async {
    final a = _audio;
    _audio = null;
    if (a != null) {
      try {
        await a.dispose();
      } catch (_) {}
    }
  }

  void dispose() {
    _stopped = true;
    final done = _playDone;
    if (done != null && !done.isCompleted) done.complete();
    _playDone = null;
    final audio = _audio;
    _audio = null;
    audio?.dispose();
    _tts.stop().catchError((_) {});
  }
}
