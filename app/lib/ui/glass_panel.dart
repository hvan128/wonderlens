import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/wonder_tokens.dart';
import 'glass_surface.dart';
import 'motion.dart';
import 'phosphor_compat.dart';
import 'pressable.dart';
import 'wonder_haptics.dart';

/// Cạnh/góc đang được kéo để resize panel.
enum PanelEdge {
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  bool get hasTop => this == top || this == topLeft || this == topRight;
  bool get hasBottom =>
      this == bottom || this == bottomLeft || this == bottomRight;
  bool get hasLeft => this == left || this == topLeft || this == bottomLeft;
  bool get hasRight => this == right || this == topRight || this == bottomRight;
}

/// Trạng thái hình học của một [GlassPanel]: vị trí + kích thước + luật
/// clamp/rubber-band/resize. Toàn bộ logic nằm đây (không trong widget) nên
/// test thuần Dart được, và màn hình có thể lưu/khôi phục bố cục panel.
class GlassPanelController extends ChangeNotifier {
  GlassPanelController({
    this._position = const Offset(24, 24),
    this._size = const Size(300, 240),
    this.minSize =
        const Size(WonderTokens.panelMinWidth, WonderTokens.panelMinHeight),
    this.maxSize,
    this.margin = WonderTokens.panelSnapMargin,
  });

  final Size minSize;
  final Size? maxSize;

  /// Khoảng đệm tối thiểu giữa panel và mép vùng chứa.
  final double margin;

  Offset _position;
  Size _size;
  Size _area = Size.zero;

  Offset get position => _position;
  Size get size => _size;
  Rect get rect => _position & _size;

  /// Vùng chứa hiện tại — [GlassPanelArea] cập nhật mỗi lần layout.
  Size get area => _area;
  set area(Size v) {
    if (v == _area) return;
    _area = v;
    // Vùng chứa đổi (xoay máy, bàn phím) → kéo panel về trong tầm nhìn.
    final clamped = clampToLegal(_position);
    if (clamped != _position) {
      _position = clamped;
    }
    notifyListeners();
  }

  /// Dải vị trí hợp lệ cho góc trên-trái của panel trong vùng chứa hiện tại.
  Rect get legalRect {
    final maxX = _area.width - _size.width - margin;
    final maxY = _area.height - _size.height - margin;
    // Panel to hơn vùng chứa → ưu tiên ghim mép trên-trái ở margin.
    return Rect.fromLTRB(
      margin,
      margin,
      maxX < margin ? margin : maxX,
      maxY < margin ? margin : maxY,
    );
  }

  Offset clampToLegal(Offset p) {
    final r = legalRect;
    return Offset(
      p.dx.clamp(r.left, r.right),
      p.dy.clamp(r.top, r.bottom),
    );
  }

  void jumpTo(Offset p) {
    if (p == _position) return;
    _position = p;
    notifyListeners();
  }

  /// Vị trí "thô" tích lũy theo ngón tay trong MỘT gesture kéo. Rubber-band
  /// phải là hàm của TỔNG vượt biên — áp đệ quy lên giá trị đã cản sẽ làm
  /// panel gần như đứng im tại biên thay vì đi tiếp với nửa delta.
  Offset? _dragRaw;

  /// Gọi khi bắt đầu kéo (pan start) để mốc raw khớp vị trí hiện tại.
  void beginDrag() => _dragRaw = _position;

  /// Gọi khi kết thúc gesture kéo.
  void endDrag() => _dragRaw = null;

  /// Kéo theo ngón tay. Ra ngoài vùng hợp lệ vẫn đi tiếp nhưng với lực cản
  /// rubber-band (nửa phần vượt) — thả ra sẽ spring về trong.
  void dragBy(Offset delta) {
    final raw = (_dragRaw ?? _position) + delta;
    _dragRaw = raw;
    final r = legalRect;
    double axis(double raw, double lo, double hi) {
      if (raw < lo) return lo + (raw - lo) * 0.5;
      if (raw > hi) return hi + (raw - hi) * 0.5;
      return raw;
    }

    jumpTo(Offset(axis(raw.dx, r.left, r.right), axis(raw.dy, r.top, r.bottom)));
  }

  /// Đích spring khi thả tay: chiếu theo đà rồi clamp vào vùng hợp lệ.
  Offset settleTarget(Offset velocity) {
    return clampToLegal(Offset(
      projectMomentum(_position.dx, velocity.dx),
      projectMomentum(_position.dy, velocity.dy),
    ));
  }

  /// Resize bằng cách kéo [edge] một đoạn [delta]; cạnh đối diện đứng yên.
  /// Tôn trọng [minSize]/[maxSize] và không cho cạnh vượt ra ngoài margin.
  ///
  /// Cận được gộp và SẮP THỨ TỰ trước khi clamp: panel có thể đang nằm ngoài
  /// legalRect (rubber-band, area vừa co lại) khiến lo > hi — khi đó bỏ qua
  /// trục ấy thay vì để `clamp` throw ArgumentError.
  void resizeBy(Offset delta, PanelEdge edge) {
    if (_area == Size.zero) return; // chưa layout — chưa có luật để áp

    var left = _position.dx;
    var top = _position.dy;
    var right = left + _size.width;
    var bottom = top + _size.height;

    final maxW = (maxSize?.width ?? (_area.width - 2 * margin))
        .clamp(minSize.width, double.infinity);
    final maxH = (maxSize?.height ?? (_area.height - 2 * margin))
        .clamp(minSize.height, double.infinity);

    double move(double v, double lo, double hi, double fallback) =>
        lo > hi ? fallback : v.clamp(lo, hi);

    if (edge.hasLeft) {
      left = move(
        left + delta.dx,
        math.max(margin, right - maxW),
        right - minSize.width,
        left,
      );
    }
    if (edge.hasRight) {
      right = move(
        right + delta.dx,
        left + minSize.width,
        math.min(_area.width - margin, left + maxW),
        right,
      );
    }
    if (edge.hasTop) {
      top = move(
        top + delta.dy,
        math.max(margin, bottom - maxH),
        bottom - minSize.height,
        top,
      );
    }
    if (edge.hasBottom) {
      bottom = move(
        bottom + delta.dy,
        top + minSize.height,
        math.min(_area.height - margin, top + maxH),
        bottom,
      );
    }

    final pos = Offset(left, top);
    final size = Size(right - left, bottom - top);
    if (pos == _position && size == _size) return;
    _position = pos;
    _size = size;
    notifyListeners();
  }
}

/// Vùng chứa các [GlassPanel] nổi — Stack quản z-order (panel được chạm nổi
/// lên trên cùng). Là OVERLAY trong cây widget của màn hình, KHÔNG phải route
/// (đẩy route sẽ làm camera dispose theo didPushNext).
class GlassPanelArea extends StatefulWidget {
  /// Nội dung nền phía sau các panel (tuỳ chọn).
  final Widget? background;
  final List<GlassPanel> panels;

  const GlassPanelArea({super.key, this.background, required this.panels});

  @override
  State<GlassPanelArea> createState() => _GlassPanelAreaState();
}

class _GlassPanelAreaState extends State<GlassPanelArea> {
  late List<GlassPanel> _ordered = List.of(widget.panels);

  @override
  void didUpdateWidget(covariant GlassPanelArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Giữ z-order hiện tại, đồng bộ panel thêm/bớt theo identity controller.
    final byController = <GlassPanelController, GlassPanel>{
      for (final p in widget.panels) p.controller: p,
    };
    _ordered = <GlassPanel>[
      for (final p in _ordered)
        if (byController.containsKey(p.controller))
          byController.remove(p.controller)!,
      ...byController.values,
    ];
  }

  void bringToFront(GlassPanelController controller) {
    final i = _ordered.indexWhere((p) => p.controller == controller);
    if (i < 0 || i == _ordered.length - 1) return;
    setState(() => _ordered.add(_ordered.removeAt(i)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        for (final p in widget.panels) {
          p.controller.area = constraints.biggest;
        }
        return _PanelAreaScope(
          state: this,
          child: Stack(
            children: <Widget>[
              if (widget.background != null)
                Positioned.fill(child: widget.background!),
              for (final p in _ordered)
                KeyedSubtree(key: ObjectKey(p.controller), child: p),
            ],
          ),
        );
      },
    );
  }
}

class _PanelAreaScope extends InheritedWidget {
  final _GlassPanelAreaState state;

  const _PanelAreaScope({required this.state, required super.child});

  @override
  bool updateShouldNotify(covariant _PanelAreaScope old) => old.state != state;
}

/// Cửa sổ kính nổi kiểu visionOS: kéo bằng thanh tiêu đề (momentum + spring
/// snap về vùng an toàn), resize từ cạnh/góc, chạm là nổi lên trên cùng.
///
/// Chỉ thanh tiêu đề nhận drag — nội dung bên trong giữ nguyên gesture của nó
/// (scroll/tap không bị tranh). Dùng bên trong [GlassPanelArea].
class GlassPanel extends StatefulWidget {
  final GlassPanelController controller;
  final String title;
  final IconData? icon;
  final Widget child;
  final GlassTone tone;
  final bool resizable;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry contentPadding;

  const GlassPanel({
    super.key,
    required this.controller,
    required this.title,
    required this.child,
    this.icon,
    this.tone = GlassTone.light,
    this.resizable = true,
    this.onClose,
    this.contentPadding = const EdgeInsets.fromLTRB(
      WonderTokens.space16,
      WonderTokens.space8,
      WonderTokens.space16,
      WonderTokens.space16,
    ),
  });

  @override
  State<GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<GlassPanel>
    with TickerProviderStateMixin {
  late final Ticker _settleTicker = createTicker(_onSettleTick);
  SpringOffsetSimulation? _settle;
  Offset _settleTarget = Offset.zero;

  /// 0 = nằm yên, 1 = đang được nhấc lên (scale + shadow đậm hơn).
  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: WonderTokens.durFast,
  );

  /// Đích spring có bị clamp so với đà thật không — để haptic lúc chạm mép.
  bool _settleWasClamped = false;

  @override
  void dispose() {
    _settleTicker.dispose();
    _lift.dispose();
    super.dispose();
  }

  _GlassPanelAreaState? get _areaState {
    final el =
        context.getElementForInheritedWidgetOfExactType<_PanelAreaScope>();
    return (el?.widget as _PanelAreaScope?)?.state;
  }

  void _stopSettle() {
    if (_settleTicker.isActive) _settleTicker.stop();
    _settle = null;
  }

  void _onSettleTick(Duration elapsed) {
    final sim = _settle;
    if (sim == null) {
      _settleTicker.stop();
      return;
    }
    final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final c = widget.controller;

    // Vùng chứa đổi giữa chừng (xoay máy, bàn phím) → đích cũ có thể đã nằm
    // ngoài vùng hợp lệ; đổi đích và bàn giao velocity để không khựng.
    final validTarget = c.clampToLegal(_settleTarget);
    if (validTarget != _settleTarget) {
      _settleTarget = validTarget;
      _settle = SpringOffsetSimulation(
        spring: WonderSpring.smooth,
        from: c.position,
        to: validTarget,
        velocity: sim.v(t),
      );
      _settleTicker.stop();
      _settleTicker.start();
      return;
    }

    if (sim.isDone(t)) {
      // Đặt đúng đích khi xong — dừng ở x(t) là lệch vĩnh viễn theo tolerance.
      c.jumpTo(_settleTarget);
      _stopSettle();
      if (_settleWasClamped) WonderHaptics.tick();
      return;
    }
    c.jumpTo(sim.x(t));
  }

  void _onBarPanStart(DragStartDetails d) {
    _stopSettle();
    widget.controller.beginDrag();
    _areaState?.bringToFront(widget.controller);
    WonderHaptics.selection();
    _lift.animateTo(1, curve: Curves.easeOut);
  }

  void _onBarPanUpdate(DragUpdateDetails d) {
    widget.controller.dragBy(d.delta);
  }

  void _onBarPanEnd(DragEndDetails d) {
    widget.controller.endDrag();
    _lift.animateBack(0, curve: Curves.easeOut);
    final velocity = d.velocity.pixelsPerSecond;
    final target = widget.controller.settleTarget(velocity);
    final projected = Offset(
      projectMomentum(widget.controller.position.dx, velocity.dx),
      projectMomentum(widget.controller.position.dy, velocity.dy),
    );
    _settleWasClamped = (target - projected).distance > 1;
    _settleTarget = target;
    _settle = SpringOffsetSimulation(
      spring: WonderSpring.smooth,
      from: widget.controller.position,
      to: target,
      velocity: velocity,
    );
    _settleTicker.start();
  }

  void _onResize(PanelEdge edge, DragUpdateDetails d) {
    widget.controller.resizeBy(d.delta, edge);
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.tone == GlassTone.dark;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[widget.controller, _lift]),
      builder: (context, _) {
        final c = widget.controller;
        final lift = _lift.value;
        return Positioned(
          left: c.position.dx,
          top: c.position.dy,
          width: c.size.width,
          height: c.size.height,
          child: Listener(
            // Chạm bất kỳ đâu trên panel → nổi lên trên cùng. Listener không
            // vào gesture arena nên không cướp tap/scroll của nội dung.
            onPointerDown: (_) => _areaState?.bringToFront(c),
            child: Transform.scale(
              scale: 1 + 0.02 * lift,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: GlassSurface(
                      tone: widget.tone,
                      radius: WonderTokens.radiusLg,
                      padding: EdgeInsets.zero,
                      shadows: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.12 + 0.14 * lift,
                          ),
                          blurRadius: 18 + 14 * lift,
                          offset: Offset(0, 8 + 6 * lift),
                        ),
                      ],
                      child: Column(
                        children: <Widget>[
                          _PanelBar(
                            title: widget.title,
                            icon: widget.icon,
                            dark: dark,
                            onClose: widget.onClose,
                            onPanStart: _onBarPanStart,
                            onPanUpdate: _onBarPanUpdate,
                            onPanEnd: _onBarPanEnd,
                          ),
                          Expanded(
                            child: Padding(
                              padding: widget.contentPadding,
                              child: widget.child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.resizable) ..._resizeZones(),
                  if (widget.resizable)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: IgnorePointer(
                        child: _ResizeGripMark(dark: dark),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Dải hit-test vô hình dọc cạnh/góc. Chỉ đăng ký pan nên tap của nội dung
  /// sát mép vẫn hoạt động bình thường.
  List<Widget> _resizeZones() {
    const t = WonderTokens.resizeHitSize;
    Widget zone(PanelEdge e, {
      double? left,
      double? top,
      double? right,
      double? bottom,
      double? width,
      double? height,
    }) {
      return Positioned(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        width: width,
        height: height,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) {
            _stopSettle();
            _areaState?.bringToFront(widget.controller);
          },
          onPanUpdate: (d) => _onResize(e, d),
        ),
      );
    }

    return <Widget>[
      zone(PanelEdge.left, left: 0, top: t, bottom: t, width: t / 2),
      zone(PanelEdge.right, right: 0, top: t, bottom: t, width: t / 2),
      zone(PanelEdge.top, top: 0, left: t, right: t, height: t / 2),
      zone(PanelEdge.bottom, bottom: 0, left: t, right: t, height: t / 2),
      zone(PanelEdge.topLeft, left: 0, top: 0, width: t, height: t),
      zone(PanelEdge.topRight, right: 0, top: 0, width: t, height: t),
      zone(PanelEdge.bottomLeft, left: 0, bottom: 0, width: t, height: t),
      zone(PanelEdge.bottomRight, right: 0, bottom: 0, width: t, height: t),
    ];
  }
}

/// Thanh tiêu đề — vùng kéo duy nhất của panel.
class _PanelBar extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool dark;
  final VoidCallback? onClose;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  const _PanelBar({
    required this.title,
    required this.icon,
    required this.dark,
    required this.onClose,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : WonderColors.textStrong;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: SizedBox(
        height: WonderTokens.panelBarHeight,
        child: Row(
          children: <Widget>[
            const SizedBox(width: WonderTokens.space16),
            if (icon != null) ...<Widget>[
              PhosphorIcon(icon!, size: 17, color: fg),
              const SizedBox(width: WonderTokens.space8),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WonderType.heading.copyWith(fontSize: 15, color: fg),
              ),
            ),
            if (onClose != null)
              Pressable(
                onTap: onClose,
                semanticLabel: 'Đóng $title',
                child: SizedBox(
                  width: WonderTokens.panelBarHeight,
                  height: WonderTokens.panelBarHeight,
                  child: Center(
                    child: PhosphorIcon(
                      PhosphorIconsFill.xCircle,
                      size: 20,
                      color: fg.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: WonderTokens.space16),
          ],
        ),
      ),
    );
  }
}

/// Vạch grip nhỏ ở góc dưới-phải — gợi ý "kéo được" kiểu visionOS.
class _ResizeGripMark extends StatelessWidget {
  final bool dark;

  const _ResizeGripMark({required this.dark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(14, 14),
      painter: _GripPainter(
        color: (dark ? Colors.white : WonderColors.textStrong)
            .withValues(alpha: 0.45),
      ),
    );
  }
}

class _GripPainter extends CustomPainter {
  final Color color;

  const _GripPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    // Cung 1/4 ở góc dưới-phải, kiểu window grip của visionOS.
    canvas.drawLine(
      Offset(size.width, size.height * 0.35),
      Offset(size.width * 0.35, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height * 0.75),
      Offset(size.width * 0.75, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GripPainter old) => old.color != color;
}
