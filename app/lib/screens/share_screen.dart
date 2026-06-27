import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/hero_catalog.dart';
import '../models/journey_args.dart';
import '../models/object_content.dart';
import '../services/share_service.dart';
import '../ui/ui.dart';

/// Màn 6 · Chia sẻ (MỚI). Thẻ khám phá (chụp PNG để khoe) + khay chia sẻ với
/// cổng phụ huynh và các đích Zalo/Messenger. Bám mockup `.s-share`.
class ShareScreen extends StatefulWidget {
  final JourneyArgs? args;
  const ShareScreen({super.key, this.args});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  ObjectContent get _content => widget.args!.content;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.selectionClick();
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    try {
      await ShareService.shareDiscovery(
        boundaryKey: _cardKey,
        content: _content,
        origin: origin,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _save() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Đã lưu phim khám phá vào máy! 💾'),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _continue() {
    final r = widget.args?.result;
    if (r != null && (r.isNewObject || r.newBadge != null)) {
      context.pushReplacement('/badge', extra: widget.args);
    } else {
      context.go('/collection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    if (a == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1B1438),
        body: Center(
          child: WonderButton(
            label: 'Về bộ sưu tập',
            expand: false,
            onTap: () => context.go('/collection'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B1438),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF2A2150), Color(0xFF15102E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Row(
                  children: <Widget>[
                    GlassIconButton(
                      icon: PhosphorIconsBold.arrowLeft,
                      size: 44,
                      semanticLabel: 'Quay lại',
                      onTap: () =>
                          context.canPop() ? context.pop() : context.go('/collection'),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: _DiscoveryCard(content: _content),
                  ).animate().fadeIn(duration: WonderTokens.durBase).scaleXY(
                        begin: 0.94,
                        end: 1,
                        curve: WonderTokens.curveEmphasized,
                      ),
                ),
              ),
              _ShareSheet(
                busy: _busy,
                onShare: _share,
                onSave: _save,
                onContinue: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ khám phá hiển thị (cũng là ảnh được chụp để chia sẻ).
class _DiscoveryCard extends StatelessWidget {
  final ObjectContent content;
  const _DiscoveryCard({required this.content});

  String get _materialKey =>
      heroById(content.id)?.material ??
      (content.materialBadge.isEmpty ? 'Nhựa' : content.materialBadge);

  String get _fact {
    final s = content.stages.isNotEmpty ? content.stages.first : null;
    final base = s?.funFact ?? s?.kidText ?? 'Mọi đồ vật đều có một hành trình kỳ diệu!';
    return 'Bé có biết? $base';
  }

  @override
  Widget build(BuildContext context) {
    final matColor = WonderColors.material(_materialKey);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: WonderShadows.card,
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Thumbnail "video".
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 152,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.24),
                  radius: 0.7,
                  colors: <Color>[WonderColors.violet, WonderColors.wonderDeep],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Text(
                    content.emoji,
                    style: const TextStyle(
                      fontSize: 72,
                      shadows: <Shadow>[Shadow(color: Colors.black38, blurRadius: 14)],
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: PhosphorIcon(PhosphorIconsFill.play, size: 18, color: WonderColors.wonder),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 11,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${content.stages.length * 6 ~/ 60}:${(content.stages.length * 6 % 60).toString().padLeft(2, '0')}',
                        style: WonderType.body(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 11,
                    child: Text(
                      '✨ WonderLens',
                      style: WonderType.display(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  '${content.emoji} ${content.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WonderType.display(
                    color: WonderColors.textStrong,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: matColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  _materialKey,
                  style: WonderType.body(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            _fact,
            style: WonderType.body(
              color: WonderColors.textSoft,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 11),
          const _DashedDivider(),
          const SizedBox(height: 11),
          Row(
            children: <Widget>[
              const PhosphorIcon(PhosphorIconsBold.magnifyingGlass, size: 16, color: WonderColors.wonder),
              const SizedBox(width: 7),
              Text(
                'Khám phá cùng WonderLens',
                style: WonderType.display(
                  color: WonderColors.wonder,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const dash = 6.0;
        const gap = 4.0;
        final count = (c.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(
            count,
            (_) => Container(width: dash, height: 1, color: WonderColors.wonderSoft),
          ),
        );
      },
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final bool busy;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onContinue;

  const _ShareSheet({
    required this.busy,
    required this.onShare,
    required this.onSave,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black45, blurRadius: 40, offset: Offset(0, -16)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: WonderColors.wonderSoft,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 14),
              // Cổng phụ huynh.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: <Widget>[
                    const Text('🔒', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Nhờ người lớn xác nhận trước khi chia sẻ nhé!',
                        style: WonderType.body(
                          color: const Color(0xFF8A5A00),
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Chia sẻ đoạn phim khám phá',
                  style: WonderType.display(
                    color: WonderColors.textStrong,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  _Target(
                    label: 'Zalo',
                    gradient: const LinearGradient(colors: <Color>[Color(0xFF2B8FFF), Color(0xFF0068FF)]),
                    onTap: busy ? null : onShare,
                    child: Text('Zalo', style: WonderType.display(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  _Target(
                    label: 'Messenger',
                    gradient: const LinearGradient(colors: <Color>[Color(0xFFA033FF), Color(0xFF0084FF), Color(0xFFFF5E84)]),
                    onTap: busy ? null : onShare,
                    child: const Text('💬', style: TextStyle(fontSize: 22)),
                  ),
                  _Target(
                    label: 'Lưu video',
                    gradient: const LinearGradient(colors: <Color>[Color(0xFF8E86B5), Color(0xFF6E6594)]),
                    onTap: busy ? null : onSave,
                    child: const PhosphorIcon(PhosphorIconsBold.downloadSimple, size: 22, color: Colors.white),
                  ),
                  _Target(
                    label: 'Khác',
                    gradient: const LinearGradient(colors: <Color>[Color(0xFFC9C2E6), Color(0xFFA9A1C9)]),
                    onTap: busy ? null : onShare,
                    child: const Text('•••', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              WonderTextButton(
                label: busy ? 'Đang chuẩn bị…' : 'Xong',
                onTap: busy ? null : onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Target extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final Widget child;
  final VoidCallback? onTap;
  const _Target({
    required this.label,
    required this.gradient,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: Column(
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: WonderShadows.soft,
              ),
              child: Center(child: child),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: WonderType.body(
                color: WonderColors.textSoft,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
