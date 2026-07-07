import 'dart:io';

import '../models/object_content.dart';
import 'journey_image_service.dart';
import 'speech_service.dart';
import 'video_service.dart';

/// Lời đọc của một chặng — DÙNG CHUNG với timeline để văn bản warm-up khớp đúng
/// văn bản timeline đọc (cùng text → cùng cache audio → phát tức thì).
String journeyStageSpeech(Stage s) => '${s.kidText} ${s.funFact ?? ''}'.trim();

/// Lời đọc màn cover (giới thiệu). null nếu vật không có history/story.
String? journeyCoverSpeech(ObjectContent c) {
  final history = c.history?.trim() ?? '';
  final story = c.story?.trim() ?? '';
  if (history.isEmpty && story.isEmpty) return null;
  return history.isNotEmpty
      ? history
      : 'Cùng xem ${c.name} được tạo ra như thế nào nhé!';
}

/// Toàn bộ lời đọc theo đúng thứ tự timeline sẽ đọc (cover nếu có + từng chặng).
List<String> journeyNarrationTexts(ObjectContent c) {
  final texts = <String>[];
  final cover = journeyCoverSpeech(c);
  if (cover != null) texts.add(cover);
  for (final s in c.stages) {
    texts.add(journeyStageSpeech(s));
  }
  return texts;
}

/// Điều phối **sinh ngầm mọi thứ** cho một hành trình (ảnh chặng + giọng đọc +
/// phim) NGAY khi AI trả nội dung — tận dụng thời gian bé xem sticker/khám phá
/// để lúc vào timeline đã có sẵn, không phải chờ lần đầu.
///
/// Vì sao cần coordinator (không để mỗi màn tự gọi):
/// - Ảnh & audio đã cache ra file theo id/hash → gọi sớm là timeline đọc cache.
/// - **Video KHÔNG idempotent** (mỗi lần gọi tạo job mới). Coordinator giữ future
///   video bắt đầu MỘT lần để timeline/JourneyVideo dùng chung, không render 2 phim.
///
/// Best-effort: lỗi/offline thì các getter rớt về sinh mới (đường cũ vẫn chạy).
class JourneyWarmup {
  JourneyWarmup._();
  static final JourneyWarmup instance = JourneyWarmup._();

  final JourneyImageService _imageSvc = JourneyImageService();
  final VideoService _videoSvc = VideoService();
  final SpeechService _speech = SpeechService();

  String? _id;
  Future<Map<int, File>>? _images;
  Future<File?>? _video;
  // Bump khi đổi vật / retry → job video cũ (isCancelled) tự dừng poll.
  int _videoGen = 0;
  // Giữ ref các future TTS đang chạy (chúng ghi file cache dùng chung mà
  // NarrationService đọc lại) — không cần đọc kết quả trực tiếp.
  final List<Future<File?>> _audio = <Future<File?>>[];

  /// Bắt đầu warm-up cho [content]. Gọi lại cùng content.id = không làm lại.
  /// (content.id là slug nên re-scan cùng vật ra cùng id → không sinh lại; phần
  /// [video] tự re-validate file nên vẫn an toàn khi file tạm đã bị dọn.)
  void start(ObjectContent content) {
    if (_id == content.id) return;
    _id = content.id;
    _images = _imageSvc.generate(content);
    _audio.clear();
    _warmAudio(content); // ưu tiên cover trước (xem _warmAudio)
    // TẠM DỪNG gen video (theo yêu cầu): không sinh phim ngầm nữa.
    _video = Future<File?>.value(null);
  }

  /// Pre-sinh giọng đọc. Câu ĐẦU (cover/lịch sử) dài nhất và cần đọc TRƯỚC →
  /// synth RIÊNG để được full băng thông, xong sớm nhất (bớt trễ lúc mới vào
  /// màn); các chặng synth SAU (song song) vì bé nghe cover xong mới tới.
  Future<void> _warmAudio(ObjectContent content) async {
    final texts = journeyNarrationTexts(content);
    if (texts.isEmpty) return;
    final first = _speech.synthesize(texts.first);
    _audio.add(first);
    await first;
    for (final t in texts.skip(1)) {
      _audio.add(_speech.synthesize(t));
    }
  }

  /// Ảnh từng chặng: future warm-up nếu đúng vật, không thì sinh mới.
  Future<Map<int, File>> images(ObjectContent content) =>
      (_id == content.id && _images != null)
          ? _images!
          : _imageSvc.generate(content);

  /// Phim hành trình. Dùng future warm-up (bắt đầu sớm) NẾU còn dùng được (file
  /// vẫn tồn tại). [forceFresh] (nút "Thử lại") hoặc future đã null/mất file →
  /// tạo job mới (bump gen để job cũ dừng). Vật có phim bundle → trả null.
  Future<File?> video(ObjectContent content, {bool forceFresh = false}) async {
    if ((content.video ?? '').trim().isNotEmpty) return null;
    if (!forceFresh && _id == content.id && _video != null) {
      final f = await _video!;
      if (f != null && await f.exists()) return f; // cache warm-up còn tốt
    }
    final gen = ++_videoGen;
    final fresh = _videoSvc.generate(content, isCancelled: () => gen != _videoGen);
    if (_id == content.id) _video = fresh;
    return fresh;
  }
}
