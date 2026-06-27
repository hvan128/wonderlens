import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../models/object_content.dart';
import '../services/narration_service.dart';

/// Origin Timeline: cuộn xem từng chặng "hành trình tạo ra vật", có giọng đọc.
/// Khi mở: ghi nhận vào bộ sưu tập + confetti/huy hiệu nếu là vật/huy hiệu mới.
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
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _narration.dispose();
    super.dispose();
  }

  String _stageSpeech(Stage s) => '${s.kidText} ${s.funFact ?? ''}'.trim();

  Future<void> _playAll(List<Stage> stages) async {
    setState(() => _playing = true);
    for (var i = 0; i < stages.length; i++) {
      if (!_playing || !mounted) break;
      setState(() => _currentStage = i);
      await _narration.speak(_stageSpeech(stages[i]));
    }
    if (mounted) {
      setState(() {
        _playing = false;
        _currentStage = null;
      });
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
      return Scaffold(
        appBar: AppBar(title: const Text('Hành trình')),
        body: const Center(child: Text('Chưa có dữ liệu hành trình.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(c.name)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _Header(content: c),
              if (_result?.newBadge != null) ...[
                const SizedBox(height: 12),
                _BadgeBanner(material: _result!.newBadge!),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _playing ? _stop : () => _playAll(c.stages),
                icon: Icon(
                    _playing ? Icons.stop_rounded : Icons.volume_up_rounded),
                label: Text(_playing ? 'Dừng đọc' : 'Nghe kể chuyện 🔊'),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < c.stages.length; i++)
                _StageTile(
                  index: i,
                  stage: c.stages[i],
                  isLast: i == c.stages.length - 1,
                  active: _currentStage == i,
                  onSpeak: () => _speakOne(i, c.stages[i]),
                ),
              const SizedBox(height: 16),
              Text('Bạn vừa khám phá xong! 🎉',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/camera'),
                child: const Text('Khám phá vật khác 🔍'),
              ),
              TextButton(
                onPressed: () => context.go('/collection'),
                child: const Text('Xem bộ sưu tập'),
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
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Text('🏅', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Huy hiệu mới: Vật liệu $material!',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ObjectContent content;
  const _Header({required this.content});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(content.emoji, style: const TextStyle(fontSize: 52)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(content.name,
                  style: Theme.of(context).textTheme.headlineSmall),
              Wrap(
                spacing: 6,
                children: [
                  if (content.materialBadge.isNotEmpty)
                    Chip(label: Text(content.materialBadge)),
                  if (content.source == 'live')
                    const Chip(
                      avatar: Text('✨'),
                      label: Text('Khám phá vui (AI)'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StageTile extends StatelessWidget {
  final int index;
  final Stage stage;
  final bool isLast;
  final bool active;
  final VoidCallback onSpeak;

  const _StageTile({
    required this.index,
    required this.stage,
    required this.isLast,
    required this.active,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 16),
          child: child,
        ),
      ),
      child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột số chặng + đường nối dọc tạo cảm giác "timeline".
          Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primaryContainer,
                child: Text('${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: active
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onPrimaryContainer,
                    )),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    color: theme.colorScheme.primaryContainer,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: active ? theme.colorScheme.primaryContainer : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(stage.title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        IconButton(
                          tooltip: 'Nghe chặng này',
                          icon: const Icon(Icons.volume_up_rounded),
                          onPressed: onSpeak,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(stage.kidText, style: theme.textTheme.bodyLarge),
                    if (stage.funFact != null && stage.funFact!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('💡 ${stage.funFact}',
                            style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
