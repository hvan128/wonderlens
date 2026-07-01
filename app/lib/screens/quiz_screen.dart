import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/object_content.dart';
import '../models/quiz.dart';
import '../services/learn_play_service.dart';
import '../ui/ui.dart';

const Color _correctColor = Color(0xFF2EBD85);
const Color _wrongColor = Color(0xFFE5564E);

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
          style: TextStyle(
            color: WonderColors.textSoft,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        GlassSurface(
          tone: GlassTone.light,
          padding: const EdgeInsets.all(18),
          shadows: WonderShadows.card,
          child: Text(
            q.question,
            style: const TextStyle(
              color: WonderColors.textStrong,
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionTile(
              label: q.options[i],
              state: _optionState(q, i),
              onTap: () => _choose(i),
            ),
          ),
        if (_revealed) ...<Widget>[
          const SizedBox(height: 6),
          _ExplainCard(
            correct: _selected == q.answerIndex,
            explain: q.explain,
          ),
          const SizedBox(height: 16),
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
    if (!_revealed) return _OptionState.idle;
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
        Center(
          child: Text(
            List<String>.filled(stars, '⭐').join(),
            style: const TextStyle(fontSize: 44),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            perfect ? 'Tuyệt vời! Đúng hết!' : 'Giỏi lắm!',
            style: const TextStyle(
              color: WonderColors.textStrong,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Bạn trả lời đúng ${result.correct}/${result.total} câu',
            style: TextStyle(
              color: WonderColors.textSoft,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 20),
        GlassSurface(
          tone: GlassTone.light,
          padding: const EdgeInsets.all(16),
          shadows: WonderShadows.soft,
          child: Row(
            children: <Widget>[
              const Text('🏅', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bạn nhận được huy hiệu Nhà thông thái!',
                  style: const TextStyle(
                    color: WonderColors.textStrong,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        WonderButton(
          label: 'Khám phá tiếp',
          icon: PhosphorIconsBold.magnifyingGlass,
          trailingIcon: PhosphorIconsBold.arrowRight,
          onTap: () => context.canPop() ? context.pop() : context.go('/camera'),
        ),
        const SizedBox(height: 10),
        WonderTextButton(label: 'Làm lại', onTap: _restart),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

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
    final (Color border, Color bg, IconData? icon, Color iconColor) =
        switch (state) {
      _OptionState.correct => (
          _correctColor,
          _correctColor.withValues(alpha: 0.16),
          PhosphorIconsFill.sealCheck,
          _correctColor,
        ),
      _OptionState.wrong => (
          _wrongColor,
          _wrongColor.withValues(alpha: 0.14),
          PhosphorIconsFill.warningCircle,
          _wrongColor,
        ),
      _OptionState.dimmed => (
          WonderColors.textSoft.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.4),
          null,
          WonderColors.textSoft,
        ),
      _OptionState.idle => (
          WonderColors.textSoft.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.6),
          null,
          WonderColors.textSoft,
        ),
    };

    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
          border: Border.all(color: border, width: 1.4),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: WonderColors.textStrong,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (icon != null) ...<Widget>[
              const SizedBox(width: 8),
              PhosphorIcon(icon, size: 22, color: iconColor),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExplainCard extends StatelessWidget {
  final bool correct;
  final String explain;

  const _ExplainCard({required this.correct, required this.explain});

  @override
  Widget build(BuildContext context) {
    final color = correct ? _correctColor : _wrongColor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(correct ? '🎉' : '💡', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              explain.isNotEmpty
                  ? explain
                  : (correct ? 'Chính xác!' : 'Gần đúng rồi, thử lại lần sau nhé!'),
              style: TextStyle(
                color: WonderColors.textStrong.withValues(alpha: 0.88),
                fontSize: 14.5,
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
            const Text('🧩', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Đố vui đang được chuẩn bị',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WonderColors.textStrong,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vật này chưa có câu đố. Hãy khám phá các đồ vật quen thuộc để chơi đố vui nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WonderColors.textSoft,
                fontSize: 14.5,
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
