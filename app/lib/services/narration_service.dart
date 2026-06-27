import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:video_player/video_player.dart';

import '../data/app_settings.dart';
import 'speech_service.dart';

/// Đọc to nội dung. Khi bật API thật → dùng **giọng OpenAI** (MP3 tải từ proxy,
/// phát qua video_player — audio-only). Khi offline/lỗi → rớt về **giọng máy**
/// on-device (flutter_tts) để không bao giờ im lặng. Lỗi nuốt best-effort —
/// giọng đọc là phụ trợ, không được làm hỏng luồng xem hành trình.
class NarrationService {
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  final SpeechService _speech = SpeechService();

  VideoPlayerController? _audio;
  Completer<void>? _playDone;
  bool _stopped = false;

  Future<void> _ensureTts() async {
    if (_ttsReady) return;
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.45); // chậm lại cho trẻ dễ nghe
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
      await _disposeAudio();
      final ctrl = VideoPlayerController.file(file);
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
        final finished = v.isCompleted ||
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
      debugPrint('openai tts play error: $e');
      _playDone = null;
      await _disposeAudio();
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
    _audio?.dispose();
    _tts.stop().catchError((_) {});
  }
}
