import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/hero_catalog.dart';
import '../data/material_catalog.dart';
import '../models/object_content.dart';
import '../services/learn_play_service.dart';
import '../ui/ui.dart';

/// Màn "Ghép ngược" (F-13 / TASK-012 / Domain 5).
///
/// Kéo nguyên liệu vào đúng thứ tự để lắp ra đồ vật (dầu mỏ → hạt nhựa → bút bi).
/// Thả sai → gợi ý nhẹ nhàng, không "thua". Lắp đủ → vật thành hình + mừng.
/// Offline cho hero; vật thiếu `assembly` → ẩn game (route trả trạng thái rỗng).
class AssemblyGameScreen extends StatefulWidget {
  final ObjectContent? content;

  const AssemblyGameScreen({super.key, required this.content});

  @override
  State<AssemblyGameScreen> createState() => _AssemblyGameScreenState();
}

class _AssemblyGameScreenState extends State<AssemblyGameScreen> {
  final LearnPlayService _service = LearnPlayService.fromCatalog();
  late final ConfettiController _confetti;

  late final List<String> _steps; // nguyên liệu cần đặt (theo thứ tự)
  late final String _target; // vật đích (mắt cuối)
  late List<String> _tray; // còn lại trong kho, đã xáo
  int _placed = 0;
  String? _hint;

  bool get _hasGame => widget.content?.assembly != null;
  bool get _complete => _hasGame && _placed >= _steps.length;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    final assembly = widget.content?.assembly;
    if (assembly != null) {
      final chain = _service.assemblyChain(assembly);
      _steps = chain.sublist(0, chain.length - 1);
      _target = chain.last;
      _tray = List<String>.of(_steps)..shuffle();
    } else {
      _steps = const <String>[];
      _target = '';
      _tray = const <String>[];
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _tryPlace(String id) {
    if (_complete) return;
    if (_service.isNextInChain(_steps, _placed, id)) {
      setState(() {
        _placed++;
        _tray = List<String>.of(_tray)..remove(id);
        _hint = null;
      });
      HapticFeedback.lightImpact();
      if (_complete) {
        _confetti.play();
        HapticFeedback.heavyImpact();
      }
    } else {
      setState(() =>
          _hint = 'Chưa đúng thứ tự rồi! Hãy bắt đầu từ nguyên liệu thô nhất nhé.');
      HapticFeedback.mediumImpact();
    }
  }

  void _restart() {
    setState(() {
      _placed = 0;
      _tray = List<String>.of(_steps)..shuffle();
      _hint = null;
    });
  }

  ({String emoji, String name}) _node(String id) {
    final m = MaterialCatalog.instance.byId(id);
    if (m != null) return (emoji: m.emoji, name: m.name);
    final h = heroById(id);
    if (h != null) return (emoji: h.emoji, name: h.name);
    return (emoji: '✨', name: id);
  }

  @override
  Widget build(BuildContext context) {
    final targetName = widget.content?.assembly?.target ?? widget.content?.name ?? '';
    return WonderScaffold(
      header: WonderHeader(
        title: 'Ghép ngược',
        subtitle: targetName,
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
      body: !_hasGame
          ? const _NoGame()
          : (_complete ? _buildDone(targetName) : _buildGame(targetName)),
    );
  }

  Widget _buildGame(String targetName) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        Text(
          'Kéo nguyên liệu vào đúng thứ tự để tạo ra $targetName!',
          style: WonderType.display(
            color: WonderColors.textStrong,
            fontSize: 17,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: WonderTokens.space12),
        // Tiến độ lắp ráp (mảnh đã đặt / tổng) — trẻ thấy ngay mình sắp xong chưa.
        Row(
          children: <Widget>[
            Expanded(
              child: WonderProgressBar(
                value: _steps.isEmpty ? 0 : _placed / _steps.length,
                height: 10,
              ),
            ),
            const SizedBox(width: WonderTokens.space8),
            Text(
              '$_placed/${_steps.length}',
              style: WonderType.display(
                color: WonderColors.textSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: WonderTokens.space16),
        ..._buildLine(),
        if (_hint != null) ...<Widget>[
          const SizedBox(height: WonderTokens.space12),
          _HintBar(text: _hint!),
        ],
        const SizedBox(height: WonderTokens.space24),
        Text(
          'Kho nguyên liệu',
          style: WonderType.display(
            color: WonderColors.textSoft,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: WonderTokens.space12),
        Wrap(
          spacing: WonderTokens.space12,
          runSpacing: WonderTokens.space12,
          children: <Widget>[
            for (final id in _tray) _DraggableChip(node: _node(id), id: id),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildLine() {
    final widgets = <Widget>[];
    for (var i = 0; i < _steps.length; i++) {
      if (i > 0) widgets.add(const _Arrow());
      if (i < _placed) {
        // Mảnh vừa đặt đúng → pulse phóng nhẹ. Key theo slot: element mới chỉ
        // được tạo khi slot chuyển từ ô thả → đã lấp, nên animation chạy đúng lúc.
        widgets.add(
          _SlotCard(node: _node(_steps[i]), tone: _SlotTone.filled)
              .animate(key: ValueKey<String>('slot-filled-$i'))
              .scaleXY(
                begin: 0.85,
                end: 1,
                duration: WonderTokens.durBase,
                curve: WonderTokens.curveEmphasized,
              ),
        );
      } else if (i == _placed) {
        widgets.add(DragTarget<String>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (d) => _tryPlace(d.data),
          builder: (context, candidate, rejected) =>
              _DropSlot(hot: candidate.isNotEmpty),
        ));
      } else {
        widgets.add(const _SlotCard(
          node: (emoji: '❓', name: '???'),
          tone: _SlotTone.ghost,
        ));
      }
    }
    widgets.add(const _Arrow());
    widgets.add(_SlotCard(
      node: _node(_target),
      tone: _SlotTone.target,
    ));
    // Chuỗi slot vào màn lần lượt (fadeIn + trượt nhẹ) như các màn khác.
    // Key cố định theo vị trí để lần setState sau không chạy lại stagger.
    return <Widget>[
      for (var i = 0; i < widgets.length; i++)
        widgets[i]
            .animate(key: ValueKey<String>('line-$i'), delay: (i * 60).ms)
            .fadeIn(duration: WonderTokens.durBase)
            .slideY(begin: 0.1, end: 0),
    ];
  }

  Widget _buildDone(String targetName) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: <Widget>[
        // Emoji vật (nội dung từ data) nảy vào — khoảnh khắc "tèn ten" khi lắp xong.
        Center(
          child: Text(_node(_target).emoji,
              style: const TextStyle(fontSize: 72)),
        )
            .animate()
            .fadeIn(duration: WonderTokens.durBase)
            .scaleXY(
              begin: 0.6,
              end: 1,
              duration: WonderTokens.durBase,
              curve: WonderTokens.curveEmphasized,
            ),
        const SizedBox(height: WonderTokens.space12),
        Center(
          child: Text(
            'Hoàn thành! 🎉',
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
            'Bạn vừa lắp ra $targetName từ nguyên liệu thô!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WonderColors.textSoft,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: WonderTokens.space20),
        GlassSurface(
          tone: GlassTone.light,
          padding: const EdgeInsets.all(16),
          shadows: WonderShadows.soft,
          child: Row(
            children: const <Widget>[
              Text('🏅', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bạn nhận được huy hiệu Thợ lắp ráp!',
                  style: TextStyle(
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
        WonderTextButton(label: 'Chơi lại', onTap: _restart),
      ],
    );
  }
}

enum _SlotTone { filled, ghost, target }

class _SlotCard extends StatelessWidget {
  final ({String emoji, String name}) node;
  final _SlotTone tone;

  const _SlotCard({required this.node, required this.tone});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, double opacity) = switch (tone) {
      _SlotTone.filled => (
          WonderColors.mint.withValues(alpha: 0.18),
          WonderColors.mint.withValues(alpha: 0.5),
          1.0,
        ),
      _SlotTone.ghost => (
          Colors.white.withValues(alpha: 0.35),
          WonderColors.textSoft.withValues(alpha: 0.2),
          0.5,
        ),
      _SlotTone.target => (
          WonderColors.sunny.withValues(alpha: 0.18),
          WonderColors.sunny.withValues(alpha: 0.55),
          1.0,
        ),
    };
    return Opacity(
      opacity: opacity,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: WonderTokens.space16,
          vertical: WonderTokens.space16,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
          border: Border.all(color: border, width: 1.4),
        ),
        child: Row(
          children: <Widget>[
            // Slot chưa mở: icon dấu hỏi (emoji thật là nội dung, chỉ hiện khi lấp).
            if (tone == _SlotTone.ghost)
              const PhosphorIcon(PhosphorIconsBold.question,
                  size: 26, color: WonderColors.textFaint)
            else
              Text(node.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: WonderTokens.space12),
            Expanded(
              child: Text(
                node.name,
                style: const TextStyle(
                  color: WonderColors.textStrong,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (tone == _SlotTone.filled)
              const PhosphorIcon(PhosphorIconsFill.sealCheck,
                  size: 22, color: WonderColors.success),
          ],
        ),
      ),
    );
  }
}

class _DropSlot extends StatelessWidget {
  final bool hot;
  const _DropSlot({required this.hot});

  @override
  Widget build(BuildContext context) {
    final color = hot ? WonderColors.teal : WonderColors.textSoft;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: WonderTokens.space16,
        vertical: WonderTokens.space20,
      ),
      decoration: BoxDecoration(
        color: WonderColors.teal.withValues(alpha: hot ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: hot ? 0.7 : 0.4),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          PhosphorIcon(PhosphorIconsBold.arrowRight,
              size: 20, color: WonderColors.teal),
          const SizedBox(width: WonderTokens.space8),
          Text(
            'Thả nguyên liệu vào đây',
            style: TextStyle(
              color: WonderColors.tealDeep,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: WonderTokens.space4),
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: WonderColors.wonderSoft,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: PhosphorIcon(
                PhosphorIconsBold.arrowDown,
                size: 18,
                color: WonderColors.textSoft,
              ),
            ),
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  final ({String emoji, String name}) node;
  const _Chip({required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WonderTokens.space16,
        vertical: WonderTokens.space12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
        border: Border.all(color: WonderColors.teal.withValues(alpha: 0.4)),
        boxShadow: WonderShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(node.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: WonderTokens.space8),
          Text(
            node.name,
            style: const TextStyle(
              color: WonderColors.textStrong,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggableChip extends StatelessWidget {
  final ({String emoji, String name}) node;
  final String id;

  const _DraggableChip({required this.node, required this.id});

  @override
  Widget build(BuildContext context) {
    final chip = _Chip(node: node);
    return Draggable<String>(
      data: id,
      feedback: Material(
        type: MaterialType.transparency,
        child: Opacity(opacity: 0.92, child: chip),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
  }
}

class _HintBar extends StatelessWidget {
  final String text;
  const _HintBar({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WonderTokens.space12),
      decoration: BoxDecoration(
        color: WonderColors.sunny.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
        border: Border.all(color: WonderColors.sunny.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          const PhosphorIcon(PhosphorIconsFill.lightbulb,
              size: 20, color: WonderColors.honey),
          const SizedBox(width: WonderTokens.space8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: WonderColors.textStrong.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoGame extends StatelessWidget {
  const _NoGame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
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
                  size: 44,
                  color: WonderColors.wonder,
                ),
              ),
            ),
            const SizedBox(height: WonderTokens.space16),
            Text(
              'Trò ghép ngược đang được chuẩn bị',
              textAlign: TextAlign.center,
              style: WonderType.display(
                color: WonderColors.textStrong,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: WonderTokens.space8),
            Text(
              'Vật này chưa có công thức lắp ráp. Thử với bút bi, bút chì, tờ giấy hay chai nhựa nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
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
