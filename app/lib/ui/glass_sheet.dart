import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/wonder_tokens.dart';
import 'glass_surface.dart';
import 'motion.dart';
import 'wonder_haptics.dart';

/// Mở sheet kính nổi từ đáy màn hình (kiểu sheet iOS 26: bo tròn cả bốn góc,
/// cách mép một khoảng thở). Trượt vào/ra bằng spring; kéo xuống quá 1/3 hoặc
/// fling nhanh → đóng, nhẹ hơn → nảy về chỗ.
///
/// Trả về giá trị pop qua `Navigator.pop(context, value)` như sheet thường.
/// Nội dung cuộn được vẫn cuộn bình thường — scroll của con thắng drag của
/// sheet trong gesture arena; kéo đóng bằng grabber/vùng không cuộn.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  GlassTone tone = GlassTone.light,
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false, // tự xử lý để tap nền cũng đóng CÓ animation
    barrierLabel: 'Đóng',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: WonderTokens.durFast,
    pageBuilder: (context, _, _) => Material(
      type: MaterialType.transparency,
      child: GlassSheet(
        title: title,
        tone: tone,
        dismissible: dismissible,
        child: Builder(builder: builder),
      ),
    ),
    transitionBuilder: (context, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

/// Thân sheet — public để test `find.byType(GlassSheet)` được.
class GlassSheet extends StatefulWidget {
  final String? title;
  final GlassTone tone;
  final bool dismissible;
  final Widget child;

  const GlassSheet({
    super.key,
    this.title,
    this.tone = GlassTone.light,
    this.dismissible = true,
    required this.child,
  });

  @override
  State<GlassSheet> createState() => _GlassSheetState();
}

class _GlassSheetState extends State<GlassSheet>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);

  /// Đo chiều cao THÂN sheet (không phải cả màn) để quy đổi px kéo → fraction.
  final GlobalKey _bodyKey = GlobalKey();

  /// 1 = giấu hẳn dưới đáy, 0 = mở hoàn toàn. Cho phép âm nhẹ (kéo quá đà).
  double _fraction = 1;

  /// Fraction "thô" tích lũy theo ngón tay trong MỘT gesture — rubber-band là
  /// hàm của tổng vượt biên, không áp đệ quy lên giá trị đã cản (đệ quy làm
  /// sheet đứng im tại biên thay vì đi tiếp với lực cản).
  double? _dragRaw;

  Simulation? _sim;
  double _target = 0;
  bool _closing = false;

  /// Ngưỡng đóng: kéo quá 1/3 chiều cao, hoặc fling xuống > 0.9 chiều cao/s.
  static const double _dismissFraction = 0.34;
  static const double _dismissVelocity = 0.9;

  @override
  void initState() {
    super.initState();
    _springTo(0, WonderSpring.snappy);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _springTo(double target, WonderSpring spring, {double velocity = 0}) {
    _target = target;
    _sim = spring.simulation(
      from: _fraction,
      to: target,
      velocity: velocity,
      // Trục fraction 0..1 — tolerance pixel sẽ cắt spring ngay đỉnh nảy đầu.
      tolerance: WonderSpring.unitTolerance,
    );
    if (_ticker.isActive) _ticker.stop();
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final sim = _sim;
    if (sim == null) {
      _ticker.stop();
      return;
    }
    final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final done = sim.isDone(t);
    // Khi xong phải ĐẶT ĐÚNG ĐÍCH — dừng ở x(t) là đứng lệch vĩnh viễn.
    setState(() => _fraction = done ? _target : sim.x(t));
    if (done) {
      _ticker.stop();
      _sim = null;
      if (_closing && mounted) {
        // Guard kép: nếu route đã bị pop từ chỗ khác (nút trong sheet) thì
        // pop lần nữa sẽ trúng màn hình bên dưới.
        final route = ModalRoute.of(context);
        if (route != null && route.isCurrent) Navigator.of(context).pop();
      }
    }
  }

  void close() {
    if (_closing) return;
    _closing = true;
    WonderHaptics.selection();
    _springTo(1.05, WonderSpring.snappy);
  }

  double get _bodyHeight {
    final h = _bodyKey.currentContext?.size?.height;
    return (h == null || h <= 0) ? 1 : h;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_closing) return;
    _sim = null;
    final raw = (_dragRaw ?? _fraction) + d.delta.dy / _bodyHeight;
    _dragRaw = raw;
    double display;
    if (raw < 0) {
      display = raw * 0.4; // rubber-band khi kéo quá đỉnh
    } else if (!widget.dismissible) {
      display = raw * 0.25; // không cho đóng → chỉ nhún nhẹ theo tay
    } else {
      display = raw;
    }
    final maxDown = widget.dismissible ? 1.2 : 0.2;
    setState(() => _fraction = display.clamp(-0.06, maxDown));
  }

  void _onDragEnd(DragEndDetails d) {
    _dragRaw = null;
    if (_closing) return;
    final v = d.velocity.pixelsPerSecond.dy / _bodyHeight; // fraction/giây
    final shouldClose =
        widget.dismissible &&
        (v > _dismissVelocity ||
            (_fraction > _dismissFraction && v > -_dismissVelocity));
    if (shouldClose) {
      _closing = true;
      _springTo(1.05, WonderSpring.smooth, velocity: v);
    } else {
      _springTo(0, WonderSpring.bouncy, velocity: v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.tone == GlassTone.dark;
    final media = MediaQuery.of(context);
    final fg = dark ? Colors.white : WonderColors.textStrong;

    return Stack(
      children: <Widget>[
        // Tap nền → đóng có animation (barrier của route chỉ lo fade màu).
        // Có nhãn semantics để VoiceOver đọc được "Đóng" — barrierDismissible
        // của route đang tắt nên node này là lối thoát duy nhất không cần nút.
        if (widget.dismissible)
          Positioned.fill(
            child: Semantics(
              label: 'Đóng',
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: close,
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              WonderTokens.space12,
              0,
              WonderTokens.space12,
              WonderTokens.space12 + media.padding.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: media.size.height * 0.86,
                maxWidth: 560,
              ),
              child: FractionalTranslation(
                translation: Offset(0, _fraction.clamp(-0.06, 1.2)),
                child: GestureDetector(
                  key: _bodyKey,
                  behavior: HitTestBehavior.deferToChild,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  child: GlassSurface(
                    tone: widget.tone,
                    radius: WonderTokens.radiusXl,
                    padding: EdgeInsets.zero,
                    tintOpacity: dark ? 0.5 : 0.62,
                    shadows: WonderShadows.card,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _Grabber(fg: fg),
                        if (widget.title != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: WonderTokens.space20,
                            ),
                            child: Text(
                              widget.title!,
                              textAlign: TextAlign.center,
                              style: WonderType.heading.copyWith(color: fg),
                            ),
                          ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              WonderTokens.space20,
                              WonderTokens.space12,
                              WonderTokens.space20,
                              WonderTokens.space20,
                            ),
                            child: widget.child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Vạch grabber — affordance "kéo được" + vùng chạm rộng để kéo đóng.
class _Grabber extends StatelessWidget {
  final Color fg;

  const _Grabber({required this.fg});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: fg.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(WonderTokens.pill),
          ),
        ),
      ),
    );
  }
}
