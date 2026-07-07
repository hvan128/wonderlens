import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/capture_store.dart';
import '../models/object_content.dart';
import '../services/narration_service.dart';
import '../ui/ui.dart';

/// Màn "khoe sticker" sau khi bé chụp (flow kiểu CapWords): cutout đã tách nền
/// được **viền trắng thành sticker** rồi **phóng lên full màn**, kèm tên + nút
/// loa đọc tên. CTA là **icon**: chụp lại · ✓ đi khám phá · ✕ huỷ.
///
/// Cutout lấy từ [CaptureStore] theo `content.id` (đã lưu lúc chụp); vật mock/
/// chưa có ảnh → rớt về emoji trên khung sáng. Không có ảnh vẫn chạy trọn flow.
class DiscoveryRevealScreen extends StatefulWidget {
  final ObjectContent content;

  const DiscoveryRevealScreen({super.key, required this.content});

  @override
  State<DiscoveryRevealScreen> createState() => _DiscoveryRevealScreenState();
}

class _DiscoveryRevealScreenState extends State<DiscoveryRevealScreen> {
  final NarrationService _narration = NarrationService();

  @override
  void dispose() {
    _narration.dispose();
    super.dispose();
  }

  void _speakName() {
    WonderHaptics.selection();
    _narration.speak(widget.content.name);
  }

  void _explore() {
    WonderHaptics.primary();
    context.push('/timeline', extra: widget.content);
  }

  void _back() {
    WonderHaptics.selection();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.content;
    final file = CaptureStore.instance.fileFor(c.id);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _RevealBackdrop()),
          SafeArea(
            child: Column(
              children: <Widget>[
                _TopBar(onClose: _back),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _Sticker(file: file, emoji: c.emoji)
                              .animate()
                              .fadeIn(duration: 320.ms)
                              .scaleXY(
                                begin: 0.72,
                                end: 1,
                                duration: 560.ms,
                                curve: Curves.easeOutBack,
                              )
                              .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
                          const SizedBox(height: 22),
                          _NameLabel(name: c.name, onSpeak: _speakName)
                              .animate(delay: 240.ms)
                              .fadeIn()
                              .slideY(begin: 0.4, end: 0, curve: WonderTokens.curveStandard),
                          if (c.materialBadge.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 12),
                            _MaterialPill(text: c.materialBadge)
                                .animate(delay: 360.ms)
                                .fadeIn(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                _CtaRow(
                  onRetry: _back,
                  onConfirm: _explore,
                  onCancel: _back,
                ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.5, end: 0),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _back,
                  child: Text(
                    'Không phải vật này? Chạm để chọn lại',
                    style: WonderType.label.copyWith(color: WonderColors.textSoft),
                  ),
                ).animate(delay: 460.ms).fadeIn(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh trên: nút đóng (quay về ống kính).
class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
      child: Row(
        children: <Widget>[
          WonderBackButton(
            onTap: onClose,
            semanticLabel: 'Quay lại ống kính',
          ),
          const Spacer(),
          Text(
            'Bé vừa tìm thấy',
            style: WonderType.label.copyWith(color: WonderColors.textSoft),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Cutout viền trắng = sticker, kèm bóng mềm + glow. Không có ảnh → emoji.
class _Sticker extends StatelessWidget {
  final File? file;
  final String emoji;
  const _Sticker({required this.file, required this.emoji});

  static const double _size = 236;
  static const int _ring = 16;

  @override
  Widget build(BuildContext context) {
    final glow = Container(
      width: _size * 1.28,
      height: _size * 1.28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            WonderColors.sunny.withValues(alpha: 0.34),
            WonderColors.sunny.withValues(alpha: 0),
          ],
        ),
      ),
    );

    final Widget subject = file == null
        ? _emojiTile()
        : _outlinedSticker(file!);

    return SizedBox(
      width: _size * 1.28,
      height: _size * 1.28,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[glow, subject],
      ),
    );
  }

  Widget _emojiTile() {
    return Container(
      width: _size * 0.8,
      height: _size * 0.8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: WonderColors.tealDeep.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 96)),
    );
  }

  Widget _outlinedSticker(File f) {
    Widget img({ColorFilter? filter}) {
      final image = Image.file(
        f,
        width: _size,
        height: _size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
      );
      return filter == null
          ? image
          : ColorFiltered(colorFilter: filter, child: image);
    }

    const white = ColorFilter.mode(Colors.white, BlendMode.srcIn);
    const shadow = ColorFilter.mode(Color(0x33123A4A), BlendMode.srcIn);
    final stroke = _size * 0.02;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          // Bóng mềm (silhouette đen mờ, hạ xuống + blur).
          Transform.translate(
            offset: Offset(0, _size * 0.05),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: img(filter: shadow),
            ),
          ),
          // Viền trắng: 16 bản silhouette trắng lệch quanh vòng tròn.
          for (int i = 0; i < _ring; i++)
            Transform.translate(
              offset: Offset(
                math.cos(2 * math.pi * i / _ring) * stroke,
                math.sin(2 * math.pi * i / _ring) * stroke,
              ),
              child: img(filter: white),
            ),
          img(),
        ],
      ),
    );
  }
}

/// Nhãn tên kiểu sticker trắng + nút loa đọc tên.
class _NameLabel extends StatelessWidget {
  final String name;
  final VoidCallback onSpeak;
  const _NameLabel({required this.name, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: WonderColors.tealDeep.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: WonderType.display.copyWith(
                color: WonderColors.textStrong,
                fontSize: 28,
                height: 1.05,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _SpeakerButton(onTap: onSpeak),
      ],
    );
  }
}

class _SpeakerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SpeakerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Đọc tên',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: WonderGradients.cta,
          ),
          child: const PhosphorIcon(
            PhosphorIconsFill.speakerSimpleHigh,
            size: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MaterialPill extends StatelessWidget {
  final String text;
  const _MaterialPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: WonderColors.teal.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WonderColors.teal.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const PhosphorIcon(PhosphorIconsFill.flask, size: 15, color: WonderColors.tealDeep),
          const SizedBox(width: 6),
          Text(
            text,
            style: WonderType.label.copyWith(color: WonderColors.tealDeep),
          ),
        ],
      ),
    );
  }
}

/// Hàng CTA icon: chụp lại · ✓ đi khám phá (chính) · ✕ huỷ.
class _CtaRow extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _CtaRow({
    required this.onRetry,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _CircleCta(
          icon: PhosphorIconsBold.arrowClockwise,
          onTap: onRetry,
          semantic: 'Chụp lại',
        ),
        const SizedBox(width: 28),
        _CircleCta(
          icon: PhosphorIconsFill.checkCircle,
          onTap: onConfirm,
          primary: true,
          semantic: 'Đi khám phá',
        ),
        const SizedBox(width: 28),
        _CircleCta(
          icon: PhosphorIconsFill.xCircle,
          onTap: onCancel,
          semantic: 'Huỷ',
        ),
      ],
    );
  }
}

class _CircleCta extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final String semantic;
  const _CircleCta({
    required this.icon,
    required this.onTap,
    required this.semantic,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final double size = primary ? 76 : 60;
    return Semantics(
      button: true,
      label: semantic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: primary ? WonderGradients.cta : null,
            color: primary ? null : Colors.white,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: (primary ? WonderColors.teal : WonderColors.tealDeep)
                    .withValues(alpha: primary ? 0.4 : 0.16),
                blurRadius: primary ? 22 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: PhosphorIcon(
            icon,
            size: primary ? 38 : 28,
            color: primary ? Colors.white : WonderColors.textSoft,
          ),
        ),
      ),
    );
  }
}

/// Nền sáng kiểu "vở chấm" + glow ấm phía sau sticker.
class _RevealBackdrop extends StatelessWidget {
  const _RevealBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFFDFBF5), Color(0xFFEDF4FA)],
        ),
      ),
      child: CustomPaint(painter: _DotGridPainter(), size: Size.infinite),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Glow ấm phía sau sticker (canh theo vùng giữa-trên).
    final glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          WonderColors.sunny.withValues(alpha: 0.20),
          WonderColors.sunny.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height * 0.34),
          radius: size.width * 0.6,
        ),
      );
    canvas.drawRect(Offset.zero & size, glow);

    // Lưới chấm mờ.
    final dot = Paint()..color = WonderColors.tealDeep.withValues(alpha: 0.05);
    const gap = 30.0;
    for (double y = gap; y < size.height; y += gap) {
      for (double x = gap; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}
