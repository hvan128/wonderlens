import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../ui/ui.dart';
import 'object_avatar.dart';
import 'object_sticker_grid.dart';

/// Một vật thể sticker trên tấm nền Rương. Giữ vị trí (tâm) + vận tốc để kéo/ném
/// và (khi bật trọng lực) rơi–nảy. **Góc nghiêng cố định** theo [WonderTilt] —
/// KHÔNG quay vòng để tránh cảm giác "xoay tít". `held` = đang bị ngón tay cầm.
class _Body {
  _Body({
    required this.item,
    required this.index,
    required this.pos,
    required this.radius,
    required this.angle,
  });

  final StickerItem item;
  int index;
  Offset pos;
  Offset vel = Offset.zero;
  double radius;
  final double angle;
  bool held = false;

  double get invMass => held ? 0 : 1;
}

/// Rương dạng **tấm nền sticker linh hoạt**. Mặc định: lưới xếp gọn (2 cột so le,
/// có tem tên) như cũ — vật đứng yên, **không quay**. Kéo bất kỳ vật nào để đổi
/// chỗ tự do, buông ra là nằm yên đúng chỗ.
///
/// Hai nút điều khiển (cha sở hữu trạng thái):
/// - **Thả rơi** ([gravity] = true): bật trọng lực → tất cả cùng rơi xuống, nảy
///   đàn hồi, va chạm nhau + tường/sàn(mép tab bar)/nút chụp rồi dồn đống. Thử
///   nghiệm cho vui.
/// - **Xếp gọn** ([gravity] = false, tăng [tidyEpoch]): tắt trọng lực + đưa mọi
///   vật mượt về lại lưới.
///
/// Chạm mở hành trình (giữ Hero morph sang cover timeline), giữ mở sheet.
class StickerPhysicsField extends StatefulWidget {
  final List<StickerItem> items;
  final void Function(String id) onTap;
  final void Function(String id)? onLongPress;

  /// Chiều cao vùng bị **thanh tab** che ở đáy → sàn ở `height - bottomInset`.
  final double bottomInset;

  /// Khoảng chừa cho **header** ở trên → trần ở `topInset`.
  final double topInset;

  /// Nút chụp neo đáy: khoảng cách đáy→cạnh dưới nút + đường kính → chướng ngại
  /// tròn để (khi thả rơi) vật dồn quanh, không đè aperture.
  final double captureBottomInset;
  final double captureSize;

  final double bodyDiameter;

  /// true = bật trọng lực (mode "Thả rơi"). false = xếp gọn / kéo thả tĩnh.
  final bool gravity;

  /// Tăng 1 → ép đưa mọi vật về lưới (dùng cho nút "Xếp gọn" ngay cả khi đang
  /// tắt trọng lực và người dùng đã kéo vật lộn xộn).
  final int tidyEpoch;

  /// Vị trí **chuẩn hoá** (nx, ny ∈ [0,1]) lần trước theo id — khôi phục đúng
  /// chỗ lúc rời đi. Thiếu id nào thì vật đó về ô lưới mặc định.
  final Map<String, Offset> initialLayout;

  /// Báo bố cục mới (đã chuẩn hoá) để cha lưu lại — gọi khi kéo xong / rơi ổn
  /// định / xếp gọn xong.
  final void Function(Map<String, Offset> normalized)? onLayoutChanged;

  const StickerPhysicsField({
    super.key,
    required this.items,
    required this.onTap,
    this.onLongPress,
    required this.bottomInset,
    required this.topInset,
    required this.captureBottomInset,
    required this.captureSize,
    this.bodyDiameter = 112,
    this.gravity = false,
    this.tidyEpoch = 0,
    this.initialLayout = const <String, Offset>{},
    this.onLayoutChanged,
  });

  @override
  State<StickerPhysicsField> createState() => _StickerPhysicsFieldState();
}

class _StickerPhysicsFieldState extends State<StickerPhysicsField>
    with SingleTickerProviderStateMixin {
  // ---- Hằng số vật lý (pixel/giây) — chỉnh cảm giác ở đây. ----
  static const double _gravityAccel = 2600;
  static const double _bodyRestitution = 0.42;
  static const double _wallRestitution = 0.4;
  static const double _floorRestitution = 0.36;
  static const double _captureRestitution = 0.44;
  static const double _wallMargin = 10;
  // Bán kính va chạm / đường kính ô. Nhỏ hơn nửa ô để lúc "Thả rơi" các vật
  // xếp khít, chồng mép nhẹ như đống thật (vòng tròn to gây khoảng hở lớn,
  // nhất là với vật mỏng như que kem / tờ giấy).
  static const double _radiusFactor = 0.38;
  static const double _maxSpeed = 4200;
  static const double _sleepSpeed = 5;
  static const int _sleepFrames = 20;
  static const double _homeRate = 13; // tốc độ đưa về lưới (mượt, tới hạn)
  static const double _labelWidth = 150;

  final math.Random _rng = math.Random(7);
  final List<_Body> _bodies = <_Body>[];
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _dragDt = 1 / 60;
  int _idleFrames = 0;
  bool _laidOut = false;
  bool _homing = false; // đang đưa về lưới (nút Xếp gọn)

  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(StickerPhysicsField old) {
    super.didUpdateWidget(old);
    if (widget.items.length != old.items.length ||
        !_sameIds(widget.items, old.items)) {
      _reconcileBodies();
    }
    if (widget.gravity && !old.gravity) {
      _startFalling();
    } else if (!widget.gravity && old.gravity) {
      _tidy();
    }
    if (widget.tidyEpoch != old.tidyEpoch && !widget.gravity) {
      _tidy();
    }
  }

  bool _sameIds(List<StickerItem> a, List<StickerItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  double get _radius => widget.bodyDiameter * _radiusFactor;
  double get _floorY => _size.height - widget.bottomInset;
  double get _ceilY => widget.topInset;

  Offset get _captureCenter => Offset(
    _size.width / 2,
    _size.height - widget.captureBottomInset - widget.captureSize / 2,
  );
  double get _captureRadius => widget.captureSize / 2 + 8;

  // ---- Lưới neo (tái hiện lưới 2 cột so le cũ) ----

  Offset _anchorFor(int i) {
    final d = widget.bodyDiameter;
    final col = i % 2;
    final row = i ~/ 2;
    final x = col == 0 ? _size.width * 0.29 : _size.width * 0.71;
    final rowPitch = d + 52;
    final y =
        _ceilY + d / 2 + 14 + row * rowPitch + (col == 1 ? rowPitch * 0.42 : 0);
    // Chặn trong khung để không tràn xuống dưới tab bar / ra ngoài mép.
    return _clampInside(Offset(x, y));
  }

  Offset _clampInside(Offset p) {
    final d = widget.bodyDiameter;
    return Offset(
      p.dx.clamp(_wallMargin + d / 2, _size.width - _wallMargin - d / 2),
      p.dy.clamp(_ceilY + d / 2, _floorY - d / 2),
    );
  }

  /// Vị trí khởi tạo cho vật [i]/[id]: khôi phục từ [initialLayout] (chuẩn hoá)
  /// nếu có, ngược lại về ô lưới mặc định.
  Offset _restoredOrAnchor(int i, String id) {
    final saved = widget.initialLayout[id];
    if (saved != null) {
      return _clampInside(
        Offset(saved.dx * _size.width, saved.dy * _size.height),
      );
    }
    return _anchorFor(i);
  }

  // ---- Dựng / đồng bộ danh sách vật ----

  void _layout(Size size) {
    _size = size;
    if (_laidOut) return;
    _laidOut = true;
    _bodies
      ..clear()
      ..addAll([
        for (var i = 0; i < widget.items.length; i++)
          _Body(
            item: widget.items[i],
            index: i,
            pos: _restoredOrAnchor(i, widget.items[i].id),
            radius: _radius,
            angle: WonderTilt.at(i),
          ),
      ]);
    // Mặc định xếp gọn sẵn — không rơi, không quay. Bơm repaint để lần đầu vào
    // màn (ticker chưa chạy ở mode tĩnh) vẫn vẽ ra các sticker vừa dựng.
    _repaint.value++;
  }

  /// Item thay đổi (xóa/thêm): giữ vật còn tồn tại, thêm vật mới ở neo, bỏ vật
  /// đã mất.
  void _reconcileBodies() {
    if (!_laidOut) return;
    final byId = {for (final b in _bodies) b.item.id: b};
    final next = <_Body>[];
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final existing = byId[item.id];
      if (existing != null) {
        next.add(existing..index = i);
      } else {
        next.add(
          _Body(
            item: item,
            index: i,
            pos: _restoredOrAnchor(i, item.id),
            radius: _radius,
            angle: WonderTilt.at(i),
          ),
        );
      }
    }
    _bodies
      ..clear()
      ..addAll(next);
    _persist();
    if (widget.gravity) _wake();
    _repaint.value++;
  }

  /// Bật trọng lực: từ chỗ hiện tại buông cho rơi + hẩy nhẹ ngẫu nhiên để tản.
  void _startFalling() {
    if (!_laidOut) return;
    _homing = false;
    for (final b in _bodies) {
      if (b.held) continue;
      b.vel = Offset(
        (_rng.nextDouble() - 0.5) * 140,
        20 + _rng.nextDouble() * 60,
      );
    }
    WonderHaptics.primary();
    _wake();
  }

  /// Xếp gọn: tắt trọng lực rồi đưa mượt mọi vật về lưới.
  void _tidy() {
    if (!_laidOut) return;
    _homing = true;
    for (final b in _bodies) {
      b.vel = Offset.zero;
    }
    WonderHaptics.selection();
    _wake();
  }

  void _wake() {
    _idleFrames = 0;
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _stopAndPersist() {
    _ticker.stop();
    _persist();
  }

  /// Ghi lại bố cục hiện tại (chuẩn hoá theo kích thước tấm nền) để lần sau mở
  /// lại đúng chỗ.
  void _persist() {
    final cb = widget.onLayoutChanged;
    if (cb == null || _size.isEmpty || _bodies.isEmpty) return;
    final w = _size.width;
    final h = _size.height;
    cb(<String, Offset>{
      for (final b in _bodies) b.item.id: Offset(b.pos.dx / w, b.pos.dy / h),
    });
  }

  // ---- Vòng lặp ----

  void _onTick(Duration elapsed) {
    if (_size.isEmpty) return;
    var dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    dt = dt.clamp(0.0, 1 / 30);
    _dragDt = dt <= 0 ? 1 / 60 : dt;
    if (dt <= 0) return;

    if (widget.gravity) {
      const substeps = 2;
      final h = dt / substeps;
      for (var s = 0; s < substeps; s++) {
        _integrate(h);
        _collide();
      }
      _maybeSleepByEnergy();
    } else {
      _stepTidyOrIdle(dt);
    }

    _repaint.value++;
  }

  /// Trọng lực tắt: đưa về lưới (nếu đang xếp gọn) hoặc chỉ ghim vật bị kéo.
  void _stepTidyOrIdle(double dt) {
    var anyMoving = false;
    if (_homing) {
      final k = 1 - math.exp(-_homeRate * dt);
      for (final b in _bodies) {
        if (b.held) {
          anyMoving = true;
          continue;
        }
        final target = _anchorFor(b.index);
        final delta = target - b.pos;
        if (delta.distance < 0.6) {
          b.pos = target;
        } else {
          b.pos += delta * k;
          anyMoving = true;
        }
      }
      if (!anyMoving) _homing = false;
    } else {
      for (final b in _bodies) {
        if (b.held) anyMoving = true;
      }
    }
    if (!anyMoving) {
      if (++_idleFrames >= 2) _stopAndPersist();
    } else {
      _idleFrames = 0;
    }
  }

  void _maybeSleepByEnergy() {
    var maxSpeed = 0.0;
    var anyHeld = false;
    for (final b in _bodies) {
      if (b.held) anyHeld = true;
      final sp = b.vel.distance;
      if (sp > maxSpeed) maxSpeed = sp;
    }
    if (!anyHeld && maxSpeed < _sleepSpeed) {
      if (++_idleFrames >= _sleepFrames) _stopAndPersist();
    } else {
      _idleFrames = 0;
    }
  }

  void _integrate(double h) {
    for (final b in _bodies) {
      if (b.held) continue;
      b.vel = b.vel.translate(0, _gravityAccel * h);
      b.vel *= math.pow(0.7, h).toDouble(); // cản khí nhẹ
      final sp = b.vel.distance;
      if (sp > _maxSpeed) b.vel = b.vel * (_maxSpeed / sp);
      b.pos += b.vel * h;
    }
  }

  void _collide() {
    for (var iter = 0; iter < 4; iter++) {
      for (var i = 0; i < _bodies.length; i++) {
        for (var j = i + 1; j < _bodies.length; j++) {
          _resolvePair(_bodies[i], _bodies[j]);
        }
      }
    }
    for (final b in _bodies) {
      _resolveCapture(b);
      _resolveBounds(b);
      if (!b.held && b.vel.distance < 3) b.vel = Offset.zero;
    }
  }

  void _resolvePair(_Body a, _Body b) {
    var delta = b.pos - a.pos;
    var dist = delta.distance;
    final minDist = a.radius + b.radius;
    if (dist >= minDist) return;
    if (dist <= 0.0001) {
      delta = Offset(1 + a.index * 0.01, 0.5);
      dist = delta.distance;
    }
    final n = delta / dist;
    final penetration = minDist - dist;
    final invSum = a.invMass + b.invMass;
    if (invSum == 0) return;

    const percent = 0.8;
    final correction = n * (penetration / invSum * percent);
    a.pos -= correction * a.invMass;
    b.pos += correction * b.invMass;

    final rv = b.vel - a.vel;
    final velN = rv.dx * n.dx + rv.dy * n.dy;
    if (velN < 0) {
      final jImp = -(1 + _bodyRestitution) * velN / invSum;
      final impulse = n * jImp;
      a.vel -= impulse * a.invMass;
      b.vel += impulse * b.invMass;
    }
  }

  void _resolveCapture(_Body b) {
    if (b.held) return;
    final delta = b.pos - _captureCenter;
    final dist = delta.distance;
    final minDist = b.radius + _captureRadius;
    if (dist >= minDist || dist <= 0.0001) return;
    final n = delta / dist;
    b.pos = _captureCenter + n * minDist;
    final velN = b.vel.dx * n.dx + b.vel.dy * n.dy;
    if (velN < 0) b.vel -= n * ((1 + _captureRestitution) * velN);
  }

  void _resolveBounds(_Body b) {
    final left = _wallMargin + b.radius;
    final right = _size.width - _wallMargin - b.radius;
    final top = _ceilY + b.radius;
    final bottom = _floorY - b.radius;

    if (b.pos.dx < left) {
      b.pos = Offset(left, b.pos.dy);
      if (b.vel.dx < 0) b.vel = Offset(-b.vel.dx * _wallRestitution, b.vel.dy);
    } else if (b.pos.dx > right) {
      b.pos = Offset(right, b.pos.dy);
      if (b.vel.dx > 0) b.vel = Offset(-b.vel.dx * _wallRestitution, b.vel.dy);
    }

    if (b.pos.dy < top) {
      b.pos = Offset(b.pos.dx, top);
      if (b.vel.dy < 0) b.vel = Offset(b.vel.dx, -b.vel.dy * _wallRestitution);
    } else if (b.pos.dy > bottom) {
      b.pos = Offset(b.pos.dx, bottom);
      if (b.vel.dy > 0) {
        final bounce = -b.vel.dy * _floorRestitution;
        final dy = bounce.abs() < 40 ? 0.0 : bounce;
        final dx = b.vel.dx * 0.8; // ma sát sàn
        b.vel = Offset(dx, dy);
      }
    }

    if (b.held) {
      b.pos = Offset(b.pos.dx.clamp(left, right), b.pos.dy.clamp(top, bottom));
    }
  }

  // ---- Cử chỉ ----

  void _onPanStart(_Body b) {
    b.held = true;
    b.vel = Offset.zero;
    // Đưa vật đang cầm lên lớp trên cùng.
    _bodies.remove(b);
    _bodies.add(b);
    // Kéo tay thì bỏ chế độ tự về lưới (để đặt đâu nằm đó).
    _homing = false;
    _wake();
  }

  void _onPanUpdate(_Body b, DragUpdateDetails d) {
    b.pos += d.delta;
    if (widget.gravity) {
      final v = d.delta / _dragDt;
      b.vel = b.vel * 0.4 + v * 0.6;
    }
    _wake();
  }

  void _onPanEnd(_Body b, DragEndDetails d) {
    b.held = false;
    if (widget.gravity) {
      final pv = d.velocity.pixelsPerSecond;
      var throwV = pv == Offset.zero ? b.vel : pv;
      final sp = throwV.distance;
      if (sp > _maxSpeed) throwV = throwV * (_maxSpeed / sp);
      b.vel = throwV;
    } else {
      b.vel = Offset.zero; // đặt đâu nằm đó
    }
    _persist();
    _wake();
  }

  // ---- Vẽ ----

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!_laidOut) {
            _layout(size);
          } else if (_size != size) {
            _size = size;
          }
        });
        _size = size;

        final showLabel = !widget.gravity;
        return ClipRect(
          child: ValueListenableBuilder<int>(
            valueListenable: _repaint,
            builder: (context, _, _) {
              final d = widget.bodyDiameter;
              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  for (final b in _bodies)
                    Positioned(
                      // Key theo danh tính vật → đổi thứ tự z (đưa lên trên khi
                      // kéo) không làm gesture/recognizer gán nhầm sang vật khác.
                      key: ValueKey<String>(b.item.id),
                      left: b.pos.dx - _labelWidth / 2,
                      top: b.pos.dy - d / 2,
                      width: _labelWidth,
                      child: _StickerPuck(
                        body: b,
                        diameter: d,
                        showLabel: showLabel,
                        onTap: () => widget.onTap(b.item.id),
                        onLongPress: widget.onLongPress == null
                            ? null
                            : () => widget.onLongPress!(b.item.id),
                        onPanStart: (_) => _onPanStart(b),
                        onPanUpdate: (dd) => _onPanUpdate(b, dd),
                        onPanEnd: (dd) => _onPanEnd(b, dd),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Một sticker kéo được: sticker (nghiêng cố định) + tem tên (khi [showLabel]).
/// Cầm–kéo bằng pan, chạm mở hành trình (giữ Hero morph sang cover timeline),
/// giữ mở sheet. Bọc trong khung rộng [_labelWidth] để tâm sticker luôn khớp
/// vị trí vật lý dù có tem hay không.
class _StickerPuck extends StatelessWidget {
  final _Body body;
  final double diameter;
  final bool showLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  const _StickerPuck({
    required this.body,
    required this.diameter,
    required this.showLabel,
    required this.onTap,
    required this.onLongPress,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    final item = body.item;
    final sticker = Hero(
      tag: collectionObjectHeroTag(item.id),
      createRectTween: stickerLinearRectTween,
      flightShuttleBuilder: objectStickerFlightShuttleBuilder(
        item: item,
        diameter: diameter,
        tilt: body.angle,
        isOpener: true,
        flightEndTilt: 0,
        labelInHero: false,
      ),
      child: Transform.rotate(
        angle: body.angle,
        child: ObjectAvatar(
          objectId: item.id,
          emoji: item.emoji,
          diameter: diameter,
          emojiSize: diameter * 0.48,
          glowOpacity: 0.16,
          sticker: true,
          stickerVisualScale: objectStickerVisualScale(item.id),
          stickerVisualOffset: objectStickerVisualOffset(item.id),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(width: diameter, height: diameter, child: sticker),
          if (showLabel)
            Transform.translate(
              offset: const Offset(0, -12),
              child: SizedBox(
                width: _StickerPhysicsFieldState._labelWidth,
                child: StickerLabel(item.name),
              ),
            ),
        ],
      ),
    );
  }
}
