import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../ui/ui.dart';
import '../widgets/dev_panel.dart';
import '../widgets/object_avatar.dart';

/// Trang chủ tối giản (thay màn onboarding): lời chào theo buổi + **vòng tròn
/// lớn CHÍNH LÀ nút mở màn chụp** (giữ tinh thần vòng của shutter) + nhật ký
/// các lần soi theo ngày, với lối tắt "Xem rương" để mở bộ sưu tập đầy đủ.
///
/// Không thanh tab dưới: vòng tròn ở giữa là hành động chính duy nhất, nhật ký
/// bên dưới là "đã làm được gì". Data đọc thẳng từ [CollectionRepository].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CollectionRepository();
    final journal = repo.journalEntries(); // mới nhất đứng đầu, có mốc thời gian
    final discoveries = repo.discoveredIds().length + journal.length;

    final ringSize = (MediaQuery.sizeOf(context).width * 0.6).clamp(184.0, 244.0);

    void openCamera() => context.push('/camera');
    void openCollection() => context.push('/collection');

    return Scaffold(
      body: WonderBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            children: <Widget>[
              _TopBar(
                onCollection: openCollection,
                onSecret: () => showDevPanel(context),
              ),
              const SizedBox(height: 14),
              _Greeting(discoveries: discoveries)
                  .animate()
                  .fadeIn(duration: WonderTokens.durSlow)
                  .slideY(begin: 0.1, end: 0, curve: WonderTokens.curveStandard),
              const SizedBox(height: 26),
              Center(
                child: ScanRingButton(
                  size: ringSize,
                  showGuide: true,
                  onTap: openCamera,
                  semanticLabel: 'Mở ống kính để soi đồ vật',
                ),
              )
                  .animate(delay: 120.ms)
                  .fadeIn(duration: WonderTokens.durSlow)
                  .scaleXY(
                    begin: 0.9,
                    end: 1,
                    curve: WonderTokens.curveEmphasized,
                  ),
              const SizedBox(height: 14),
              Text(
                'Chạm vòng tròn để soi đồ vật',
                textAlign: TextAlign.center,
                style: WonderType.body.copyWith(color: WonderColors.textSoft),
              ).animate(delay: 260.ms).fadeIn(),
              const SizedBox(height: 30),
              _SectionHeader(
                title: journal.isEmpty
                    ? 'Nhật ký của bé'
                    : 'Tháng ${journal.first.discoveredAt.month}',
                onSeeAll: openCollection,
              ).animate(delay: 320.ms).fadeIn(),
              const SizedBox(height: 12),
              ..._history(context, journal),
            ],
          ),
        ),
      ),
    );
  }

  /// Nhật ký soi theo NGÀY (mới → cũ). Chỉ vật AI-live có mốc thời gian thật
  /// nên lấy từ đó; vật hero curated (không mốc) xem trong "Rương". Rỗng →
  /// thẻ mời soi món đầu tiên. Không bịa dữ liệu.
  List<Widget> _history(BuildContext context, List<JournalEntry> journal) {
    if (journal.isEmpty) {
      return <Widget>[
        const _EmptyHistoryCard().animate(delay: 360.ms).fadeIn().slideY(
              begin: 0.1,
              end: 0,
              curve: WonderTokens.curveStandard,
            ),
      ];
    }

    // Gom theo ngày, giữ thứ tự gặp (journal đã mới-nhất-trước).
    final byDay = <String, List<JournalEntry>>{};
    for (final e in journal) {
      final d = e.discoveredAt;
      (byDay['${d.year}.${d.month}.${d.day}'] ??= <JournalEntry>[]).add(e);
    }

    final cards = <Widget>[];
    var i = 0;
    for (final entries in byDay.values) {
      if (i > 0) cards.add(const SizedBox(height: 12));
      cards.add(
        _DayCard(
          entries: entries,
          onOpen: () => context.push(
            '/timeline',
            extra: entries.first.toContent(),
          ),
        )
            .animate(delay: (360 + i * 70).ms)
            .fadeIn(duration: WonderTokens.durBase)
            .slideY(begin: 0.12, end: 0, curve: WonderTokens.curveStandard),
      );
      i++;
    }
    return cards;
  }
}

/// Thanh trên: pill thương hiệu (nhấn giữ = Dev panel) + nút mở rương bên phải.
class _TopBar extends StatelessWidget {
  final VoidCallback onCollection;
  final VoidCallback onSecret;

  const _TopBar({required this.onCollection, required this.onSecret});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: onSecret,
          child: GlassSurface(
            tone: GlassTone.light,
            radius: WonderTokens.pill,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            tintOpacity: 0.58,
            shadows: const <BoxShadow>[],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const WonderLogo(size: 24),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: <Color>[
                      WonderColors.tealDeep,
                      WonderColors.sky,
                      WonderColors.grape,
                    ],
                  ).createShader(rect),
                  child: Text(
                    'WonderLens',
                    style: WonderType.title.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        GlassIconButton(
          icon: PhosphorIconsBold.grid,
          tone: GlassTone.light,
          size: 46,
          semanticLabel: 'Rương khám phá',
          onTap: onCollection,
        ),
      ],
    ).animate().fadeIn(duration: WonderTokens.durSlow);
  }
}

/// Lời chào theo buổi + số món đã soi (đếm cả hero + vật AI).
class _Greeting extends StatelessWidget {
  final int discoveries;

  const _Greeting({required this.discoveries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          '${now.day} tháng ${now.month}',
          style: WonderType.caption.copyWith(
            color: WonderColors.textSoft,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _greeting(now.hour),
          textAlign: TextAlign.center,
          style: WonderType.display.copyWith(
            color: WonderColors.textStrong,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          discoveries == 0
              ? 'Cùng soi món đồ đầu tiên của bé nào!'
              : 'Tuyệt vời! Bé đã soi $discoveries món đồ rồi!',
          textAlign: TextAlign.center,
          style: WonderType.body.copyWith(color: WonderColors.textSoft),
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

/// Tiêu đề khu nhật ký + lối tắt "Xem rương".
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: WonderType.display.copyWith(
              color: WonderColors.textStrong,
              fontSize: 24,
            ),
          ),
        ),
        Pressable(
          onTap: onSeeAll,
          pressedScale: 0.96,
          semanticLabel: 'Xem rương khám phá',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Xem rương',
                  style: WonderType.textButton.copyWith(
                    color: WonderColors.tealDeep,
                  ),
                ),
                const SizedBox(width: 3),
                const PhosphorIcon(
                  PhosphorIconsBold.caretRight,
                  size: 15,
                  color: WonderColors.tealDeep,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Thẻ một ngày: ngày + số vật + chồng avatar (ảnh thật nếu đã lưu, không thì
/// emoji). Chạm mở lại hành trình của vật mới nhất trong ngày.
class _DayCard extends StatelessWidget {
  final List<JournalEntry> entries;
  final VoidCallback onOpen;

  const _DayCard({required this.entries, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final d = entries.first.discoveredAt;
    return Pressable(
      onTap: onOpen,
      semanticLabel: 'Xem lại ngày ${d.day} tháng ${d.month}',
      child: GlassSurface(
        tone: GlassTone.light,
        radius: WonderTokens.radiusLg,
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        shadows: WonderShadows.card,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${d.day} tháng ${d.month}',
                    style: WonderType.title.copyWith(
                      color: WonderColors.textStrong,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entries.length} vật đã soi',
                    style: WonderType.caption.copyWith(
                      color: WonderColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _AvatarStack(entries: entries),
          ],
        ),
      ),
    );
  }
}

/// Chồng avatar tối đa 3 vật + chip "+N" khi nhiều hơn.
class _AvatarStack extends StatelessWidget {
  final List<JournalEntry> entries;

  const _AvatarStack({required this.entries});

  static const double _d = 44;
  static const double _overlap = 28;

  @override
  Widget build(BuildContext context) {
    final show = entries.take(3).toList();
    final extra = entries.length - show.length;
    final slots = show.length + (extra > 0 ? 1 : 0);
    final width = _d + (slots - 1) * _overlap;

    return SizedBox(
      width: width,
      height: _d,
      child: Stack(
        children: <Widget>[
          for (var i = 0; i < show.length; i++)
            Positioned(
              left: i * _overlap,
              child: _ring(
                child: ObjectAvatar(
                  objectId: show[i].id,
                  emoji: show[i].emoji,
                  diameter: _d,
                  emojiSize: 22,
                  glowOpacity: 0.16,
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: show.length * _overlap,
              child: _ring(
                child: Container(
                  width: _d,
                  height: _d,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      '+$extra',
                      style: WonderType.label.copyWith(
                        color: WonderColors.tealDeep,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Viền trắng quanh mỗi avatar để tách lớp khi chồng lên nhau.
  Widget _ring({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Chưa có nhật ký → mời soi món đầu tiên (không bịa dữ liệu mẫu).
class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      tone: GlassTone.light,
      radius: WonderTokens.radiusLg,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      shadows: WonderShadows.soft,
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: WonderGradients.secondary,
            ),
            child: const Center(
              child: PhosphorIcon(
                PhosphorIconsFill.sparkle,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Nhật ký còn trống',
                  style: WonderType.heading.copyWith(
                    color: WonderColors.textStrong,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Chạm vòng tròn để soi món đầu tiên nhé!',
                  style: WonderType.caption.copyWith(
                    color: WonderColors.textSoft,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
