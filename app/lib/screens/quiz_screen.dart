import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/object_content.dart';
import '../models/quiz.dart';
import '../services/learn_play_service.dart';
import '../ui/ui.dart';

/// Màn "Đố vui" sau timeline (F-10 / TASK-009 / Domain 5).
///
/// 1–3 câu củng cố kiến thức vừa xem. Không "phạt": chọn sai vẫn được giải thích
/// thân thiện và hoàn thành vẫn nhận sao. Offline cho hero; vật lạ/AI-live không
/// có quiz → hiện trạng thái "đang chuẩn bị". Nhận qua route `/quiz` (extra = content).
class QuizScreen extends StatefulWidget {
  final ObjectContent? content;

  const QuizScreen({super.key, required this.content});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final LearnPlayService _service;
  late final ConfettiController _confetti;
  late final List<QuizQuestion> _quiz;
  final List<int> _answers = <int>[];
  int _index = 0;
  int? _selected;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _service = LearnPlayService.fromCatalog();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _quiz = widget.content?.quiz ?? const <QuizQuestion>[];
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  bool get _isResult => _index >= _quiz.length;

  void _choose(int i) {
    if (_revealed) return;
    setState(() {
      _selected = i;
      _revealed = true;
    });
    HapticFeedback.selectionClick();
  }

  void _next() {
    _answers.add(_selected ?? -1);
    final wasLast = _index == _quiz.length - 1;
    setState(() {
      _index++;
      _selected = null;
      _revealed = false;
    });
    if (wasLast) {
      final result = _service.scoreQuiz(_quiz, _answers);
      if (result.correct > 0) {
        _confetti.play();
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _restart() {
    setState(() {
      _answers.clear();
      _index = 0;
      _selected = null;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WonderScaffold(
      header: WonderHeader(
        title: 'Đố vui',
        subtitle: widget.content?.name ?? '',
        showBack: true,
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/collection'),
      ),
      overlay: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 18,
          gravity: 0.25,
        ),
      ),
      body: _quiz.isEmpty
          ? const _NoQuiz()
          : (_isResult ? _buildResult() : _buildQuestion()),
    );
  }

  Widget _buildQuestion() {
    final q = _quiz[_index];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Text(
          'Câu ${_index + 1}/${_quiz.length}',
          style: WonderType.body(
            color: WonderColors.textSoft,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: WonderTokens.space8),
        // Thanh tiến độ câu hỏi — trẻ thấy ngay mình đang ở đâu trong bài đố.
        WonderProgressBar(
          value: (_index + 1) / _quiz.length,
          height: 10,
        ),
        const SizedBox(height: WonderTokens.space12),
        GlassSurface(
          tone: GlassTone.light,
          padding: const EdgeInsets.all(WonderTokens.space20),
          shadows: WonderShadows.card,
          child: Text(
            q.question,
            style: WonderType.display(
              color: WonderColors.textStrong,
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        )
            // Key theo câu hỏi để entrance chạy lại mỗi lần đổi câu.
            .animate(key: ValueKey<String>('question-$_index'))
            .fadeIn(duration: WonderTokens.durBase)
            .slideY(begin: 0.08, end: 0, curve: WonderTokens.curveStandard),
        const SizedBox(height: WonderTokens.space16),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: WonderTokens.space12),
            child: _OptionTile(
              label: q.options[i],
              state: _optionState(q, i),
              onTap: () => _choose(i),
            )
                .animate(
                  key: ValueKey<String>('option-$_index-$i'),
                  delay: (60 + i * 60).ms,
                )
                .fadeIn(duration: WonderTokens.durBase)
                .slideY(begin: 0.1, end: 0, curve: WonderTokens.curveStandard),
          ),
        if (_revealed) ...<Widget>[
          const SizedBox(height: WonderTokens.space8),
          _ExplainCard(
            correct: _selected == q.answerIndex,
            explain: q.explain,
          )
              .animate()
              .fadeIn(duration: WonderTokens.durBase)
              .slideY(begin: 0.08, end: 0, curve: WonderTokens.curveStandard),
          const SizedBox(height: WonderTokens.space16),
          WonderButton(
            label: _index == _quiz.length - 1 ? 'Xem kết quả' : 'Câu tiếp theo',
            icon: PhosphorIconsBold.arrowRight,
            onTap: _next,
          ),
        ],
      ],
    );
  }

  _OptionState _optionState(QuizQuestion q, int i) {
    if (!_revealed) {
      return i == _selected ? _OptionState.selected : _OptionState.idle;
    }
    if (i == q.answerIndex) return _OptionState.correct;
    if (i == _selected) return _OptionState.wrong;
    return _OptionState.dimmed;
  }

  Widget _buildResult() {
    final result = _service.scoreQuiz(_quiz, _answers);
    final stars = result.stars;
    final perfect = result.correct == result.total;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: <Widget>[
        // Hàng 3 sao: sao đạt nảy vào lần lượt màu vàng, sao chưa đạt mờ nhạt.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: WonderTokens.space4,
                ),
                child: i < stars
                    ? const PhosphorIcon(
                        PhosphorIconsFill.star,
                        size: 44,
                        color: WonderColors.spark,
                      )
                        .animate(delay: (i * 120).ms)
                        .fadeIn(duration: WonderTokens.durFast)
                        .scaleXY(
                          begin: 0,
                          end: 1,
                          duration: WonderTokens.durBase,
                          curve: WonderTokens.curveEmphasized,
                        )
                    : PhosphorIcon(
                        PhosphorIconsFill.star,
                        size: 44,
                        color: WonderColors.textFaint.withValues(alpha: 0.4),
                      ),
              ),
          ],
        ),
        const SizedBox(height: WonderTokens.space12),
        Center(
          child: Text(
            perfect ? 'Tuyệt vời! Đúng hết!' : 'Giỏi lắm!',
            style: WonderType.display(
              color: WonderColors.textStrong,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: WonderTokens.space8),
        Center(
          child: Text(
            'Bạn trả lời đúng ${result.correct}/${result.total} câu',
            style: WonderType.body(
              color: WonderColors.textSoft,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: WonderTokens.space20),
        GlassSurface(
          tone: GlassTone.light,
          padding: const EdgeInsets.all(WonderTokens.space16),
          shadows: WonderShadows.soft,
          child: Row(
            children: <Widget>[
              const Text('🏅', style: TextStyle(fontSize: 28)),
              const SizedBox(width: WonderTokens.space12),
              Expanded(
                child: Text(
                  'Bạn nhận được huy hiệu Nhà thông thái!',
                  style: WonderType.body(
                    color: WonderColors.textStrong,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WonderTokens.space24),
        WonderButton(
          label: 'Khám phá tiếp',
          icon: PhosphorIconsBold.magnifyingGlass,
          trailingIcon: PhosphorIconsBold.arrowRight,
          onTap: () => context.canPop() ? context.pop() : context.go('/camera'),
        ),
        const SizedBox(height: WonderTokens.space8),
        WonderTextButton(label: 'Làm lại', onTap: _restart),
      ],
    );
  }
}

enum _OptionState { idle, selected, correct, wrong, dimmed }

/// Ô đáp án kiểu Duolingo: viền 2px rõ ràng, nền trắng; đổi màu theo trạng thái
/// (chọn → tím, đúng → xanh + check, sai → đỏ + rung nhẹ) để phản hồi tức thì.
class _OptionTile extends StatelessWidget {
  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (Color border, Color bg, IconData? icon, Color accent) =
        switch (state) {
      _OptionState.correct => (
          WonderColors.success,
          WonderColors.success.withValues(alpha: 0.14),
          PhosphorIconsFill.checkCircle,
          WonderColors.success,
        ),
      _OptionState.wrong => (
          WonderColors.danger,
          WonderColors.danger.withValues(alpha: 0.12),
          PhosphorIconsFill.xCircle,
          WonderColors.danger,
        ),
      _OptionState.selected => (
          WonderColors.wonder,
          WonderColors.wonderSoft,
          null,
          WonderColors.wonder,
        ),
      _OptionState.dimmed => (
          WonderColors.textFaint.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.55),
          null,
          WonderColors.textSoft,
        ),
      _OptionState.idle => (
          WonderColors.wonder.withValues(alpha: 0.16),
          Colors.white,
          null,
          WonderColors.textSoft,
        ),
    };

    Widget tile = Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: WonderTokens.durFast,
        curve: WonderTokens.curveStandard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: WonderType.body(
                  color: state == _OptionState.dimmed
                      ? WonderColors.textSoft
                      : WonderColors.textStrong,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (icon != null) ...<Widget>[
              const SizedBox(width: WonderTokens.space8),
              PhosphorIcon(icon, size: 22, color: accent),
            ],
          ],
        ),
      ),
    );

    // Chọn sai → rung ngang ngắn kiểu Duolingo (nhẹ nhàng, không đáng sợ).
    if (state == _OptionState.wrong) {
      tile = tile.animate().shake(
            duration: 250.ms,
            hz: 8,
            offset: const Offset(4, 0),
            rotation: 0,
          );
    }
    return tile;
  }
}

class _ExplainCard extends StatelessWidget {
  final bool correct;
  final String explain;

  const _ExplainCard({required this.correct, required this.explain});

  @override
  Widget build(BuildContext context) {
    final color = correct ? WonderColors.success : WonderColors.danger;
    return Container(
      padding: const EdgeInsets.all(WonderTokens.space16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PhosphorIcon(
            correct ? PhosphorIconsFill.confetti : PhosphorIconsFill.lightbulb,
            size: 22,
            color: color,
          ),
          const SizedBox(width: WonderTokens.space12),
          Expanded(
            child: Text(
              explain.isNotEmpty
                  ? explain
                  : (correct ? 'Chính xác!' : 'Gần đúng rồi, thử lại lần sau nhé!'),
              style: WonderType.body(
                color: WonderColors.textStrong.withValues(alpha: 0.88),
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoQuiz extends StatelessWidget {
  const _NoQuiz();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Biểu tượng ghép hình trong đĩa tím dịu — trạng thái chờ thân thiện.
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: WonderColors.wonderSoft,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: PhosphorIcon(
                  PhosphorIconsBold.puzzlePiece,
                  size: 48,
                  color: WonderColors.wonder,
                ),
              ),
            ),
            const SizedBox(height: WonderTokens.space16),
            Text(
              'Đố vui đang được chuẩn bị',
              textAlign: TextAlign.center,
              style: WonderType.display(
                color: WonderColors.textStrong,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: WonderTokens.space8),
            Text(
              'Vật này chưa có câu đố. Hãy khám phá các đồ vật quen thuộc để chơi đố vui nhé!',
              textAlign: TextAlign.center,
              style: WonderType.body(
                color: WonderColors.textSoft,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
