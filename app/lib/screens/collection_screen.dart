import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../data/content_repository.dart';
import '../data/hero_catalog.dart';
import '../ui/ui.dart';
import '../widgets/object_sticker_grid.dart';
import '../widgets/share_sheet.dart';

/// Bộ sưu tập khám phá: cấp độ + huy hiệu vật liệu + vật dạng sticker. Dùng cả
/// khi push riêng (có back) lẫn làm **tab Rương** trong [MainShell] ([inShell]).
class CollectionScreen extends StatelessWidget {
  /// true = làm tab trong shell (không back, không nền riêng, chừa đáy tab bar).
  final bool inShell;

  const CollectionScreen({super.key, this.inShell = false});

  @override
  Widget build(BuildContext context) {
    final repo = CollectionRepository();
    final discovered = repo.discoveredIds().toSet();
    final badges = repo.badges();
    final journal = repo.journalEntries();
    final count = discovered.length;
    final total = heroCatalog.length;
    final earnedMaterials = [
      for (final m in allMaterials)
        if (badges.contains(m)) m,
    ];
    final discoveredEmojis = [
      for (final h in heroCatalog)
        if (discovered.contains(h.id)) h.emoji,
    ];
    // Vật để bày sticker: hero đã mở khoá + vật AI (journal).
    final items = <StickerItem>[
      for (final h in heroCatalog)
        if (discovered.contains(h.id))
          StickerItem(id: h.id, name: h.name, emoji: h.emoji),
      for (final e in journal)
        StickerItem(id: e.id, name: e.name, emoji: e.emoji),
    ];

    void share() => showCollectionShareSheet(
      context,
      levelTitle: levelTitle(count),
      discoveredCount: count,
      totalCount: total,
      earnedMaterials: earnedMaterials,
      discoveredEmojis: discoveredEmojis,
    );

    final children = <Widget>[
      _LevelCard(count: count, total: total)
          .animate()
          .fadeIn(duration: WonderTokens.durBase)
          .slideY(begin: 0.12, end: 0),
      if (count > 0) ...<Widget>[
        const SizedBox(height: 12),
        WonderButton(
          label: 'Khoe thành tích',
          icon: PhosphorIconsBold.shareNetwork,
          gradient: WonderGradients.secondary,
          onTap: share,
        ),
      ],
      const SizedBox(height: 22),
      const _SectionTitle('Huy hiệu siêu chất liệu'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (var i = 0; i < allMaterials.length; i++)
            _MaterialBadge(
                  material: allMaterials[i],
                  earned: badges.contains(allMaterials[i]),
                )
                .animate(delay: (i * 50).ms)
                .fadeIn(duration: WonderTokens.durBase)
                .scaleXY(
                  begin: 0.9,
                  end: 1,
                  curve: WonderTokens.curveEmphasized,
                ),
        ],
      ),
      const SizedBox(height: 24),
      const _SectionTitle('Đồ vật của bé'),
      const SizedBox(height: 12),
      if (items.isEmpty)
        Text(
          'Chưa mở khoá vật nào — soi vài món để lấp đầy rương nhé!',
          style: WonderType.body.copyWith(color: WonderColors.textSoft),
        )
      else
        ObjectStickerGrid(
          items: items,
          columns: 3,
          cellHeight: 158,
          sticker: 88,
          onTap: (id) {
            if (heroById(id) != null) {
              _openHeroJourney(context, id);
            } else {
              _openJournalJourney(
                context,
                journal.firstWhere((e) => e.id == id),
              );
            }
          },
        ),
    ];

    // Tab Rương: không back, nền do shell lo, chừa đáy cho thanh tab.
    if (inShell) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Rương của bé',
                style: WonderType.display.copyWith(
                  color: WonderColors.textStrong,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                journal.isEmpty
                    ? 'Đã mở khoá $count/$total'
                    : 'Đã mở khoá $count/$total · ${journal.length} vật AI',
                style: WonderType.body.copyWith(color: WonderColors.textSoft),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    top: 4,
                    bottom: WonderTokens.tabBarClearance + 24,
                  ),
                  children: children,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WonderScaffold(
      header: WonderHeader(
        title: 'Rương khám phá',
        subtitle: journal.isEmpty
            ? 'Bé đã mở khóa $count/$total'
            : 'Bé đã mở khóa $count/$total · ${journal.length} vật AI',
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/camera'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: children,
      ),
    );
  }
}

/// Mở lại "hành trình" của một vật đã khám phá khi bấm vào ô trong bộ sưu tập.
/// Nội dung vật hero đóng gói sẵn (offline) nên load gần như tức thì + có cache.
Future<void> _openHeroJourney(BuildContext context, String id) async {
  final content = await ContentRepository().load(id);
  if (!context.mounted || content == null) return;
  context.push('/timeline', extra: content);
}

/// Mở lại hành trình vật AI-live từ nội dung đã lưu trong nhật ký — offline,
/// không gọi lại proxy (ảnh chặng đã cache theo id, xem JourneyImageService).
void _openJournalJourney(BuildContext context, JournalEntry entry) {
  context.push('/timeline', extra: entry.toContent());
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: WonderColors.textStrong,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int count;
  final int total;
  const _LevelCard({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : count / total;
    final done = count >= total;
    return GlassSurface(
      tone: GlassTone.light,
      padding: const EdgeInsets.all(18),
      shadows: WonderShadows.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: WonderGradients.badge,
                  boxShadow: WonderShadows.glow(
                    WonderColors.teal,
                    opacity: 0.4,
                  ),
                ),
                child: const Center(
                  child: PhosphorIcon(
                    PhosphorIconsFill.trophy,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Cấp độ của bé',
                      style: TextStyle(
                        color: WonderColors.textSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      levelTitle(count),
                      style: const TextStyle(
                        color: WonderColors.textStrong,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProgressBar(value: progress),
          const SizedBox(height: 8),
          Text(
            done
                ? 'Bé gom đủ bộ rồi - đỉnh quá!'
                : 'Mở đủ $total đồ vật để lên hạng bậc thầy!',
            style: TextStyle(
              color: WonderColors.textStrong.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    // Thanh cấp độ tự "lấp đầy" khi vào màn — thành tích nhìn thấy được,
    // không phải một vạch tĩnh có sẵn.
    return ClipRRect(
      borderRadius: BorderRadius.circular(WonderTokens.pill),
      child: Stack(
        children: <Widget>[
          Container(
            height: 14,
            color: WonderColors.teal.withValues(alpha: 0.14),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: WonderTokens.durSlow,
            curve: WonderTokens.curveStandard,
            builder: (context, animated, _) => FractionallySizedBox(
              widthFactor: animated,
              child: Container(
                height: 14,
                decoration: const BoxDecoration(gradient: WonderGradients.cta),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialBadge extends StatelessWidget {
  final String material;
  final bool earned;
  const _MaterialBadge({required this.material, required this.earned});

  @override
  Widget build(BuildContext context) {
    final color = earned ? WonderColors.sunny : WonderColors.textSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: earned ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(WonderTokens.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: earned ? 0.45 : 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PhosphorIcon(
            earned ? PhosphorIconsFill.medal : PhosphorIconsBold.lockSimple,
            size: 16,
            color: earned ? WonderColors.sunnyDeep : WonderColors.textSoft,
          ),
          const SizedBox(width: 7),
          Text(
            material,
            style: TextStyle(
              color: earned ? WonderColors.textStrong : WonderColors.textSoft,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

