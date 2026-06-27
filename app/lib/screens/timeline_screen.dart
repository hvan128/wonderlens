import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../models/object_content.dart';
import '../services/journey_image_service.dart';
import '../services/narration_service.dart';
import '../ui/ui.dart';
import '../widgets/journey_video.dart';
import '../widgets/object_avatar.dart';
import '../widgets/share_sheet.dart';

/// Origin Timeline: cuộn xem từng chặng "hành trình tạo ra vật", có giọng đọc +
/// phim hành trình + chia sẻ. Khi mở: ghi nhận vào bộ sưu tập + confetti/huy hiệu.
class TimelineScreen extends StatefulWidget {
  final ObjectContent? content;

  const TimelineScreen({super.key, this.content});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _narration = NarrationService();
  late final ConfettiController _confetti;
  DiscoveryResult? _result;
  bool _playing = false;
  int? _currentStage;
  final _videoKey = GlobalKey<JourneyVideoState>();
  // Ảnh AI-live theo chặng (vật lạ). Hero dùng asset bundle qua Stage.illustration.
  Map<int, File> _stageImages = const {};
  bool _imagesLoading = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    final c = widget.content;
    if (c != null) {
      _result = CollectionRepository().record(c.id);
      if (_result?.isNewObject ?? false) {
        _confetti.play();
        HapticFeedback.heavyImpact();
      }
      // Tự đọc to CÂU CHUYỆN hoàn chỉnh (lịch sử + cách làm) ngay khi mở trang;
      // dừng được bằng nút "Dừng đọc" hoặc khi chạm phát video. Hoãn sau frame
      // đầu vì có gọi setState.
      final narration = c.narrationText;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Phim hành trình chạy NGẦM song song — không chờ giọng đọc xong.
        _videoKey.currentState?.autoGenerate();
        if (narration.isNotEmpty) _playStory(narration);
      });
      // Vật lạ (AI-live): sinh ảnh "đồng nhất bối cảnh" cho từng chặng qua proxy.
      // Hero objects đã có ảnh bundle (Stage.illustration) → không gọi proxy.
      if (c.source == 'live' && JourneyImageService.available) {
        _loadStageImages(c);
      }
    }
  }

  Future<void> _loadStageImages(ObjectContent c) async {
    setState(() => _imagesLoading = true);
    final imgs = await JourneyImageService().generate(c);
    if (!mounted) return;
    setState(() {
      _stageImages = imgs;
      _imagesLoading = false;
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _narration.dispose();
    super.dispose();
  }

  String _stageSpeech(Stage s) => '${s.kidText} ${s.funFact ?? ''}'.trim();

  /// Đọc to câu chuyện hoàn chỉnh — audio chính của trang chi tiết.
  Future<void> _playStory(String text) async {
    setState(() {
      _playing = true;
      _currentStage = null;
    });
    await _narration.speak(text);
    if (!mounted) return;
    final finishedNaturally = _playing; // _stop() đặt _playing=false giữa chừng
    setState(() => _playing = false);
    if (finishedNaturally) {
      // Đọc xong giọng kể → tự tạo phim hành trình ngầm (không cần bấm nút).
      _videoKey.currentState?.autoGenerate();
    }
  }

  Future<void> _stop() async {
    setState(() => _playing = false);
    await _narration.stop();
    if (mounted) setState(() => _currentStage = null);
  }

  Future<void> _speakOne(int i, Stage s) async {
    await _narration.stop();
    if (!mounted) return;
    setState(() {
      _playing = false;
      _currentStage = i;
    });
    await _narration.speak(_stageSpeech(s));
    if (mounted && _currentStage == i) {
      setState(() => _currentStage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.content;
    if (c == null) {
      return WonderScaffold(
        header: WonderHeader(
          title: 'Hành trình',
          showBack: true,
          onBack: () =>
              context.canPop() ? context.pop() : context.go('/camera'),
        ),
        body: const Center(child: Text('Chưa có dữ liệu hành trình.')),
      );
    }

    return WonderScaffold(
      header: WonderHeader(
        title: c.name,
        subtitle: 'Hành trình tạo ra',
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/camera'),
        actions: <WonderHeaderAction>[
          WonderHeaderAction(
            icon: PhosphorIconsBold.shareNetwork,
            tooltip: 'Chia sẻ',
            onTap: () => showDiscoveryShareSheet(context, c),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
            children: <Widget>[
              _Header(content: c)
                  .animate()
                  .fadeIn(duration: WonderTokens.durBase)
                  .slideY(begin: 0.12, end: 0),
              if (_result?.newBadge != null) ...<Widget>[
                const SizedBox(height: 12),
                _BadgeBanner(material: _result!.newBadge!)
                    .animate(delay: 150.ms)
                    .fadeIn()
                    .scaleXY(
                      begin: 0.92,
                      end: 1,
                      curve: WonderTokens.curveEmphasized,
                    ),
              ],
              if (c.history != null && c.history!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _HistoryCard(history: c.history!.trim())
                    .animate(delay: 80.ms)
                    .fadeIn(duration: WonderTokens.durBase)
                    .slideY(begin: 0.1, end: 0),
              ],
              const SizedBox(height: 14),
              WonderButton(
                label: _playing ? 'Dừng đọc' : 'Nghe kể chuyện',
                icon: _playing
                    ? PhosphorIconsBold.stop
                    : PhosphorIconsFill.speakerSimpleHigh,
                onTap: _playing ? _stop : () => _playStory(c.narrationText),
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < c.stages.length; i++)
                _StageTile(
                      index: i,
                      stage: c.stages[i],
                      isLast: i == c.stages.length - 1,
                      active: _currentStage == i,
                      onSpeak: () => _speakOne(i, c.stages[i]),
                      image: resolveStageImage(
                        illustration: c.stages[i].illustration,
                        liveFile: _stageImages[i],
                      ),
                      imageLoading: _imagesLoading &&
                          c.source == 'live' &&
                          resolveStageImage(
                                illustration: c.stages[i].illustration,
                                liveFile: _stageImages[i],
                              ) ==
                              null,
                    )
                    .animate(delay: (120 + i * 90).ms)
                    .fadeIn(duration: WonderTokens.durBase)
                    .slideY(
                      begin: 0.16,
                      end: 0,
                      curve: WonderTokens.curveStandard,
                    ),
              const SizedBox(height: 8),
              // Phim hành trình ở CUỐI — tự tạo ngầm sau khi đọc xong câu chuyện.
              JourneyVideo(key: _videoKey, content: c),
              const SizedBox(height: 16),
              Text(
                'Bạn vừa khám phá xong! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: WonderColors.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              WonderButton(
                label: 'Khám phá vật khác',
                icon: PhosphorIconsBold.magnifyingGlass,
                onTap: () => context.go('/camera'),
              ),
              const SizedBox(height: 10),
              WonderButton(
                label: 'Chia sẻ khám phá',
                icon: PhosphorIconsBold.shareNetwork,
                gradient: const LinearGradient(
                  colors: <Color>[WonderColors.grape, WonderColors.indigo],
                ),
                onTap: () => showDiscoveryShareSheet(context, c),
              ),
              const SizedBox(height: 6),
              Center(
                child: WonderTextButton(
                  label: 'Xem bộ sưu tập',
                  onTap: () => context.go('/collection'),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 20,
              maxBlastForce: 12,
              minBlastForce: 6,
              emissionFrequency: 0.05,
              colors: const <Color>[
                WonderColors.teal,
                WonderColors.sky,
                WonderColors.grape,
                WonderColors.sunny,
                WonderColors.mint,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ObjectContent content;
  const _Header({required this.content});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      tone: GlassTone.light,
      padding: const EdgeInsets.all(WonderTokens.space16),
      shadows: WonderShadows.card,
      child: Row(
        children: <Widget>[
          ObjectAvatar(
            objectId: content.id,
            emoji: content.emoji,
            diameter: 62,
            emojiSize: 32,
            glowOpacity: 0.4,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  content.name,
                  style: const TextStyle(
                    color: WonderColors.textStrong,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    if (content.materialBadge.isNotEmpty)
                      WonderChip(
                        label: content.materialBadge,
                        icon: PhosphorIconsBold.flask,
                        tone: GlassTone.light,
                      ),
                    if (content.source == 'live')
                      WonderChip(
                        label: 'Khám phá vui (AI)',
                        icon: PhosphorIconsFill.sparkle,
                        color: WonderColors.grape,
                        tone: GlassTone.light,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeBanner extends StatelessWidget {
  final String material;
  const _BadgeBanner({required this.material});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      tone: GlassTone.light,
      tint: WonderColors.sunny,
      tintOpacity: 0.32,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          const PhosphorIcon(
            PhosphorIconsFill.medal,
            size: 30,
            color: Color(0xFFE08A00),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Huy hiệu mới: Vật liệu $material!',
              style: const TextStyle(
                color: WonderColors.textStrong,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ "Một chút lịch sử" — lịch sử ngắn của vật/vật liệu.
class _HistoryCard extends StatelessWidget {
  final String history;
  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      tone: GlassTone.light,
      padding: const EdgeInsets.all(WonderTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[WonderColors.grape, WonderColors.indigo],
                  ),
                ),
                child: const Center(
                  child: PhosphorIcon(Symbols.history,
                      size: 20, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Một chút lịch sử',
                style: TextStyle(
                  color: WonderColors.textStrong,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            history,
            style: TextStyle(
              color: WonderColors.textStrong.withValues(alpha: 0.9),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  final int index;
  final Stage stage;
  final bool isLast;
  final bool active;
  final VoidCallback onSpeak;
  final ImageProvider? image;
  final bool imageLoading;

  const _StageTile({
    required this.index,
    required this.stage,
    required this.isLast,
    required this.active,
    required this.onSpeak,
    this.image,
    this.imageLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Cột số chặng + đường nối dọc tạo cảm giác "timeline".
          Column(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: active ? WonderGradients.badge : null,
                  color: active ? null : Colors.white,
                  border: Border.all(
                    color: active
                        ? Colors.transparent
                        : WonderColors.teal.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: active
                      ? WonderShadows.glow(WonderColors.teal, opacity: 0.4)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: active ? Colors.white : WonderColors.tealDeep,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: WonderColors.teal.withValues(alpha: 0.22),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassSurface(
                tone: GlassTone.light,
                tint: active ? WonderColors.teal : null,
                tintOpacity: active ? 0.2 : null,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (image != null || imageLoading) ...<Widget>[
                      _StageImage(image: image, loading: imageLoading),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            stage.title,
                            style: const TextStyle(
                              color: WonderColors.textStrong,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Pressable(
                          onTap: onSpeak,
                          semanticLabel: 'Nghe chặng này',
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: WonderColors.teal.withValues(alpha: 0.12),
                            ),
                            child: const PhosphorIcon(
                              PhosphorIconsFill.speakerSimpleHigh,
                              size: 18,
                              color: WonderColors.tealDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stage.kidText,
                      style: TextStyle(
                        color: WonderColors.textStrong.withValues(alpha: 0.9),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    if (stage.funFact != null &&
                        stage.funFact!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: WonderColors.sunny.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(
                            WonderTokens.radiusSm,
                          ),
                          border: Border.all(
                            color: WonderColors.sunny.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const PhosphorIcon(
                              PhosphorIconsFill.lightbulb,
                              size: 17,
                              color: Color(0xFFE08A00),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stage.funFact!,
                                style: TextStyle(
                                  color: WonderColors.textStrong.withValues(
                                    alpha: 0.88,
                                  ),
                                  fontSize: 13.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ảnh minh hoạ của một chặng. Khung 16/10 bo góc, giữ chỗ ổn định. Khi đang
/// sinh ảnh (AI-live) hiện shimmer; ảnh lỗi rớt về placeholder mềm, không vỡ.
class _StageImage extends StatelessWidget {
  final ImageProvider? image;
  final bool loading;

  const _StageImage({required this.image, required this.loading});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: image != null
            ? Image(
                image: image!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                frameBuilder: (context, child, frame, wasSync) {
                  if (wasSync || frame != null) {
                    return child.animate().fadeIn(duration: WonderTokens.durBase);
                  }
                  return _placeholder(shimmer: true);
                },
                errorBuilder: (context, error, stack) =>
                    _placeholder(shimmer: false),
              )
            : _placeholder(shimmer: loading),
      ),
    );
  }

  Widget _placeholder({required bool shimmer}) {
    final box = Container(
      color: WonderColors.teal.withValues(alpha: 0.1),
      child: Center(
        child: PhosphorIcon(
          PhosphorIconsFill.image,
          size: 26,
          color: WonderColors.teal.withValues(alpha: 0.5),
        ),
      ),
    );
    if (!shimmer) return box;
    return box.animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: Colors.white.withValues(alpha: 0.55),
        );
  }
}
