import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../services/camera_warmup.dart';
import '../ui/ui.dart';
import '../util/vn_time.dart';
import '../widgets/dev_panel.dart';
import '../widgets/object_sticker_grid.dart';
import 'day_detail_screen.dart';

/// Trang chủ (tab): **header co giãn theo cuộn** — vuốt lên thì ẩn lời chào + thu
/// nhỏ nút capture (có haptic) TRƯỚC, rồi mới cuộn danh sách thẻ theo ngày; vuốt
/// xuống thì ngược lại.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<Color> _cardColors = <Color>[
    Color(0xFFC9AD92), // tan
    Color(0xFFCBA29B), // hồng đất
    Color(0xFFA9B79D), // xanh rêu
    Color(0xFF9FB0C0), // xanh xám
    Color(0xFFBBA6BE), // tím khói
  ];

  final ScrollController _sc = ScrollController();
  double _range = 1; // khoảng co của header (maxExtent - minExtent)
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onScroll);
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  /// Haptic khi header vừa collapse xong (vuốt lên) / vừa bung ra (vuốt xuống).
  void _onScroll() {
    if (_range <= 0) return;
    final collapsed = (_sc.offset / _range).clamp(0.0, 1.0) > 0.55;
    if (collapsed != _collapsed) {
      _collapsed = collapsed;
      collapsed ? WonderHaptics.selection() : WonderHaptics.tick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = CollectionRepository();
    final entries = repo.discoveryEntries();
    final discoveries = entries.length;
    final ringSize = (MediaQuery.sizeOf(context).width * 0.62).clamp(
      190.0,
      260.0,
    );
    final maxExt = ringSize + 156;
    final minExt = ringSize * 0.42 + 22;
    _range = maxExt - minExt;

    final byDay = <String, List<JournalEntry>>{};
    for (final e in entries) {
      final d = e.discoveredAt;
      (byDay['${d.year}.${d.month}.${d.day}'] ??= <JournalEntry>[]).add(e);
    }
    final days = byDay.values.toList();

    void openCamera() => context.push('/camera');
    // Hâm nóng ống kính KHI ĐÃ CẤP QUYỀN — không bật dialog xin quyền lạc ngữ
    // cảnh trên trang chủ; lần đầu (chưa cấp) để màn camera xin, đúng ngữ cảnh.
    void prewarm() => CameraWarmup.instance.prewarmIfGranted();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        controller: _sc,
        slivers: <Widget>[
          SliverPersistentHeader(
            pinned: false,
            delegate: _HomeHeader(
              maxExt: maxExt,
              minExt: minExt,
              ringSize: ringSize,
              discoveries: discoveries,
              onSecret: () => showDevPanel(context),
              onPressStart: prewarm,
              onCapture: openCamera,
            ),
          ),
          if (days.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                WonderTokens.tabBarClearance + 24,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  Text(
                    'Nhật kí khám phá',
                    style: WonderType.display.copyWith(
                      color: WonderColors.textStrong,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < days.length; i++) ...<Widget>[
                    _JournalDayFrame(
                      entries: days[i],
                      color: _cardColors[i % _cardColors.length],
                      onOpen: () => context.push(
                        '/day',
                        extra: DayGroup(
                          days[i],
                          _cardColors[i % _cardColors.length],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ]),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(height: WonderTokens.tabBarClearance),
            ),
        ],
      ),
    );
  }
}

/// Header co giãn: lời chào (mờ dần) ở trên + nút capture (thu nhỏ dần) ở dưới.
class _HomeHeader extends SliverPersistentHeaderDelegate {
  final double maxExt;
  final double minExt;
  final double ringSize;
  final int discoveries;
  final VoidCallback onSecret;
  final VoidCallback onPressStart;
  final VoidCallback onCapture;

  _HomeHeader({
    required this.maxExt,
    required this.minExt,
    required this.ringSize,
    required this.discoveries,
    required this.onSecret,
    required this.onPressStart,
    required this.onCapture,
  });

  @override
  double get maxExtent => maxExt;
  @override
  double get minExtent => minExt;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final range = maxExt - minExt;
    final p = range <= 0 ? 0.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final gOpacity = (1 - p * 1.6).clamp(0.0, 1.0);
    final ringScale = 1 - 0.58 * p; // 1 → 0.42

    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: IgnorePointer(
                  ignoring: gOpacity < 0.5,
                  child: Opacity(
                    opacity: gOpacity,
                    child: _Greeting(
                      discoveries: discoveries,
                      onSecret: onSecret,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ApertureCaptureButton(
                  size: ringSize * ringScale,
                  onPressStart: onPressStart,
                  onCapture: onCapture,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeader old) =>
      discoveries != old.discoveries ||
      maxExt != old.maxExt ||
      minExt != old.minExt ||
      ringSize != old.ringSize;
}

/// Lời chào theo buổi + số món đã soi. Nhấn giữ ngày = Dev panel (ẩn).
class _Greeting extends StatelessWidget {
  final int discoveries;
  final VoidCallback onSecret;

  const _Greeting({required this.discoveries, required this.onSecret});

  @override
  Widget build(BuildContext context) {
    final now = vnNow();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: onSecret,
          child: Text(
            '${now.day} tháng ${now.month}',
            style: WonderType.body.copyWith(
              color: WonderColors.textSoft,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _greeting(now.hour),
          textAlign: TextAlign.center,
          style: WonderType.display.copyWith(
            color: WonderColors.textStrong,
            fontSize: 34,
            fontWeight: FontWeight.w600,
            height: 1.05,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          discoveries == 0
              ? 'Chạm vòng tròn để soi đồ vật'
              : 'Tuyệt vời! Bé đã soi $discoveries món đồ rồi!',
          textAlign: TextAlign.center,
          style: WonderType.body.copyWith(
            color: WonderColors.textSoft,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  String _greeting(int hour) {
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 14) return 'Chào buổi trưa';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

class _DayLabel extends StatelessWidget {
  final DateTime day;

  const _DayLabel({required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Text(
        '${day.day} tháng ${day.month}',
        style: WonderType.body.copyWith(
          color: WonderColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }
}

class _JournalDayFrame extends StatelessWidget {
  final List<JournalEntry> entries;
  final Color color;
  final VoidCallback onOpen;

  const _JournalDayFrame({
    required this.entries,
    required this.color,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final d = entries.first.discoveredAt;
    return Pressable(
      onTap: onOpen,
      haptic: false,
      semanticLabel: 'Mở nhật ký ngày ${d.day} tháng ${d.month}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: WonderColors.textStrong.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DayLabel(day: d),
              const SizedBox(height: 6),
              _DayCard(entries: entries, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ một ngày: nền màu dịu bo tròn + thumbnail cutout. Chạm cả thẻ → mở màn
/// chi tiết ([DayDetailView], route `/day`); mỗi vật bọc [Hero] để **bay** sang
/// sticker lớn ở màn chi tiết (và bay ngược về khi thoát).
class _DayCard extends StatelessWidget {
  static const double _stickerSpacing = 4;

  final List<JournalEntry> entries;
  final Color color;

  const _DayCard({required this.entries, required this.color});

  @override
  Widget build(BuildContext context) {
    final d = entries.first.discoveredAt;
    final show = entries.take(3).toList();
    return Stack(
      // Clip.none: quầng bóng (glow) của nền thẻ tràn ra ngoài không bị cắt.
      clipBehavior: Clip.none,
      children: <Widget>[
        // Nền thẻ = Hero: khi mở, phóng to thành nền màn chi tiết (thu về khi
        // thoát). Là sibling của các avatar Hero (Flutter cấm Hero lồng Hero).
        Positioned.fill(
          child: Hero(
            tag: dayCardHeroTag(d),
            createRectTween: dayLinearRectTween,
            flightShuttleBuilder: dayCardFlightShuttle(color),
            child: _DayCardSurface(color: color),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: _stickerSpacing,
              runSpacing: _stickerSpacing,
              children: <Widget>[
                for (var j = 0; j < show.length; j++)
                  _HomeStickerPreview(
                    entry: show[j],
                    index: j,
                    tilt: dayStickerTilt(j),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeStickerPreview extends StatelessWidget {
  final JournalEntry entry;
  final int index;
  final double tilt;

  const _HomeStickerPreview({
    required this.entry,
    required this.index,
    required this.tilt,
  });

  @override
  Widget build(BuildContext context) {
    final item = StickerItem(
      id: entry.id,
      name: entry.name,
      emoji: entry.emoji,
    );
    return SizedBox(
      width: kHomePreviewStickerCardWidth,
      height: kHomePreviewStickerCardHeight,
      child: Hero(
        tag: dayObjectHeroTag(entry.id),
        createRectTween: dayLinearRectTween,
        flightShuttleBuilder: objectStickerFlightShuttleBuilder(
          item: item,
          tilt: tilt,
          homePreviewIndex: index,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: HomeStickerPreviewTile(item: item, index: index, tilt: tilt),
        ),
      ),
    );
  }
}

class _DayCardSurface extends StatelessWidget {
  final Color color;

  const _DayCardSurface({required this.color});

  static const double _radius = 26;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(_radius);
    return GlassSurface(
      tone: GlassTone.light,
      // Native UIGlassEffect hiện vẫn render dạng capsule trong vài bounds rộng.
      // Card nhật kí cần bo góc chữ nhật ổn định, nên dùng recipe Flutter glass.
      native: false,
      radius: _radius,
      padding: EdgeInsets.zero,
      tint: color,
      tintOpacity: 0.16,
      blur: 18,
      shadows: <BoxShadow>[
        BoxShadow(
          color: WonderColors.textStrong.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                color.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.12),
                WonderColors.sky.withValues(alpha: 0.08),
              ],
              stops: const <double>[0.0, 0.58, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
