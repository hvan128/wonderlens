import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/object_content.dart';
import '../services/video_service.dart';
import '../ui/ui.dart';

/// Khối "Phim hành trình" trên màn Timeline.
/// - Vật hero có [ObjectContent.video] (asset đóng gói): phát ngay, offline.
/// - Vật lạ (AI-live) + có proxy: bấm nút → Sora tạo (~vài phút) → phát từ file tạm.
/// - Không có asset lẫn proxy: ẩn hẳn.
///
/// State để public ([JourneyVideoState]) để màn cha kích hoạt tạo phim ngầm
/// (autoGenerate) qua GlobalKey. Video phát TẮT TIẾNG nên không chặn giọng đọc.
class JourneyVideo extends StatefulWidget {
  final ObjectContent content;

  /// Tuỳ chọn màn cha truyền vào — hiện KHÔNG được gọi nữa: video tắt tiếng,
  /// chạy độc lập nên không cần dừng giọng đọc khi phát.
  final VoidCallback? onPlay;

  const JourneyVideo({super.key, required this.content, this.onPlay});

  @override
  State<JourneyVideo> createState() => JourneyVideoState();
}

enum _Phase { idle, generating, ready, error }

class JourneyVideoState extends State<JourneyVideo> {
  VideoPlayerController? _controller;
  final _service = VideoService();
  _Phase _phase = _Phase.idle;
  int _progress = 0;
  bool _wasPlaying = false;
  File? _tempFile; // file tạm của video AI-live, dọn khi dispose

  bool get _hasAsset => (widget.content.video ?? '').isNotEmpty;
  bool get _canGenerate => VideoService.available;

  @override
  void initState() {
    super.initState();
    if (_hasAsset) {
      _initController(VideoPlayerController.asset(widget.content.video!));
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    // Dọn file tạm của chính widget này (best-effort).
    final f = _tempFile;
    if (f != null) {
      f.delete().catchError((_) => f);
    }
    super.dispose();
  }

  /// Pause video nếu đang phát — màn cha có thể gọi (tuỳ chọn). Video tắt tiếng
  /// nên không bắt buộc, giữ để tương thích lời gọi sẵn có.
  void pauseVideo() {
    final c = _controller;
    if (c != null && c.value.isPlaying) {
      c.pause();
      setState(() {});
    }
  }

  // Chỉ rebuild khi trạng thái phát/dừng đổi (đỡ rebuild mỗi frame).
  void _onTick() {
    final playing = _controller?.value.isPlaying ?? false;
    if (mounted && playing != _wasPlaying) {
      _wasPlaying = playing;
      setState(() {});
    }
  }

  Future<void> _initController(VideoPlayerController ctrl) async {
    try {
      await ctrl.initialize();
      await ctrl.setLooping(false);
      await ctrl.setVolume(0); // tắt tiếng: phim chạy độc lập, không chặn narration
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      ctrl.addListener(_onTick);
      setState(() {
        _controller = ctrl;
        _phase = _Phase.ready;
      });
    } catch (e) {
      if (mounted) setState(() => _phase = _Phase.error);
      await ctrl.dispose();
    }
  }

  Future<void> _generate() async {
    setState(() {
      _phase = _Phase.generating;
      _progress = 0;
    });
    final file = await _service.generate(
      widget.content,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );
    if (!mounted) return;
    if (file == null) {
      setState(() => _phase = _Phase.error);
      return;
    }
    _tempFile = file;
    await _initController(VideoPlayerController.file(file));
    // KHÔNG tự phát: sinh xong chỉ chuyển sang trạng thái sẵn sàng (nút play).
    // Người dùng chủ động bấm mới chiếu.
  }

  /// Thử lại theo nguồn: hero thì init lại asset đóng gói; vật lạ thì gọi Sora.
  void _retry() {
    if (_hasAsset) {
      setState(() => _phase = _Phase.idle);
      _initController(VideoPlayerController.asset(widget.content.video!));
    } else {
      _generate();
    }
  }

  /// Tự sinh phim ngầm — màn cha gọi SAU khi đọc xong giọng kể. Chỉ sinh khi
  /// chưa có asset sẵn, có proxy và đang ở trạng thái chờ (idle).
  void autoGenerate() {
    if (_hasAsset || !_canGenerate) return;
    if (_phase != _Phase.idle) return;
    _generate();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      // Phát lại từ đầu nếu đã xem hết.
      if (c.value.position >= c.value.duration) {
        c.seekTo(Duration.zero);
      }
      c.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Không có gì để hiện (vật lạ nhưng chưa cấu hình proxy).
    if (!_hasAsset && !_canGenerate) return const SizedBox.shrink();

    return GlassSurface(
      tone: GlassTone.light,
      padding: const EdgeInsets.all(14),
      shadows: WonderShadows.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: WonderGradients.badge,
                ),
                child: const Center(
                  child: PhosphorIcon(PhosphorIconsFill.filmStrip,
                      size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Phim hành trình',
                style: TextStyle(
                  color: WonderColors.textStrong,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case _Phase.ready:
        return _player();
      case _Phase.generating:
        return _generating();
      case _Phase.error:
        return _errorBox();
      case _Phase.idle:
        // hero asset đang init thì hiện loading; vật lạ chờ tự sinh sau giọng kể.
        return _hasAsset ? _initing() : _autoHint();
    }
  }

  Widget _player() {
    final c = _controller!;
    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
          child: AspectRatio(
            aspectRatio:
                c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
            child: GestureDetector(
              onTap: _togglePlay,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  VideoPlayer(c),
                  if (!c.value.isPlaying)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: WonderGradients.badge,
                        boxShadow:
                            WonderShadows.glow(WonderColors.teal, opacity: 0.5),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const PhosphorIcon(PhosphorIconsFill.play,
                          size: 38, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        VideoProgressIndicator(
          c,
          allowScrubbing: true,
          colors: const VideoProgressColors(playedColor: WonderColors.teal),
        ),
      ],
    );
  }

  Widget _generating() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: <Widget>[
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(WonderColors.teal),
          ),
          const SizedBox(height: 12),
          Text(
            _progress > 0
                ? 'Đang vẽ phim hành trình… $_progress%'
                : 'Đang chuẩn bị phim hành trình…',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WonderColors.textStrong,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '(có thể mất vài phút, chờ chút nhé!)',
            style: TextStyle(
              color: WonderColors.textSoft,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _initing() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(WonderColors.teal),
        ),
      ),
    );
  }

  /// Trạng thái chờ: KHÔNG có nút — phim sẽ tự tạo ngầm sau khi đọc xong câu
  /// chuyện (màn cha gọi [autoGenerate]).
  Widget _autoHint() {
    return Row(
      children: <Widget>[
        const PhosphorIcon(PhosphorIconsFill.filmSlate,
            size: 20, color: WonderColors.grape),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Phim hành trình sẽ tự xuất hiện sau khi nghe xong câu chuyện nhé!',
            style: TextStyle(
              color: WonderColors.textStrong.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PhosphorIcon(PhosphorIconsFill.warningCircle,
                size: 20, color: WonderColors.coral),
            SizedBox(width: 8),
            Text(
              'Chưa mở được phim lần này',
              style: TextStyle(
                color: WonderColors.textStrong,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        // Hero luôn cho thử lại (init lại asset); vật lạ cần proxy để tạo.
        if (_hasAsset || _canGenerate) ...<Widget>[
          const SizedBox(height: 12),
          WonderButton(
            label: 'Thử lại',
            icon: PhosphorIconsBold.arrowClockwise,
            gradient: const LinearGradient(
              colors: <Color>[WonderColors.grape, WonderColors.indigo],
            ),
            onTap: _retry,
          ),
        ],
      ],
    );
  }
}
