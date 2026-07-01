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
          style: const TextStyle(
            color: WonderColors.textStrong,
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        ..._buildLine(),
        if (_hint != null) ...<Widget>[
          const SizedBox(height: 14),
          _HintBar(text: _hint!),
        ],
        const SizedBox(height: 22),
        Text(
          'Kho nguyên liệu',
          style: TextStyle(
            color: WonderColors.textSoft,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
        widgets.add(_SlotCard(
          node: _node(_steps[i]),
          tone: _SlotTone.filled,
        ));
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
    return widgets;
  }

  Widget _buildDone(String targetName) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: <Widget>[
        Center(
          child: Text(_node(_target).emoji,
              style: const TextStyle(fontSize: 72)),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Hoàn thành! 🎉',
            style: const TextStyle(
              color: WonderColors.textStrong,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
          border: Border.all(color: border, width: 1.4),
        ),
        child: Row(
          children: <Widget>[
            Text(node.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
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
                  size: 22, color: Color(0xFF2EBD85)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
          const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text('↓',
              style: TextStyle(
                color: WonderColors.textSoft.withValues(alpha: 0.7),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              )),
        ),
      );
}

class _Chip extends StatelessWidget {
  final ({String emoji, String name}) node;
  const _Chip({required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          const SizedBox(width: 8),
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: WonderColors.sunny.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
        border: Border.all(color: WonderColors.sunny.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
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
            const Text('🔧', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Trò ghép ngược đang được chuẩn bị',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WonderColors.textStrong,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vật này chưa có công thức lắp ráp. Thử với bút bi, bút chì, tờ giấy hay chai nhựa nhé!',
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
