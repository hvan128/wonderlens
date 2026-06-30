import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../data/content_repository.dart';
import '../data/hero_catalog.dart';
import '../ui/ui.dart';
import '../widgets/object_avatar.dart';
import '../widgets/share_sheet.dart';

/// Bộ sưu tập khám phá: lưới 8 vật (mờ nếu chưa quét), huy hiệu vật liệu, cấp độ.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CollectionRepository();
    final discovered = repo.discoveredIds().toSet();
    final badges = repo.badges();
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

    void share() => showCollectionShareSheet(
      context,
      levelTitle: levelTitle(count),
      discoveredCount: count,
      totalCount: total,
      earnedMaterials: earnedMaterials,
      discoveredEmojis: discoveredEmojis,
    );

    return WonderScaffold(
      header: WonderHeader(
        title: 'Bộ sưu tập',
        subtitle: 'Đã khám phá $count/$total',
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/camera'),
        actions: <WonderHeaderAction>[
          if (count > 0)
            WonderHeaderAction(
              icon: PhosphorIconsBold.shareNetwork,
              tooltip: 'Khoe bộ sưu tập',
              onTap: share,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          _LevelCard(count: count, total: total)
              .animate()
              .fadeIn(duration: WonderTokens.durBase)
              .slideY(begin: 0.12, end: 0),
          if (count > 0) ...<Widget>[
            const SizedBox(height: 12),
            WonderButton(
              label: 'Khoe bộ sưu tập',
              icon: PhosphorIconsBold.shareNetwork,
              gradient: const LinearGradient(
                colors: <Color>[WonderColors.grape, WonderColors.indigo],
              ),
              onTap: share,
            ),
          ],
          const SizedBox(height: 22),
          const _SectionTitle('Huy hiệu vật liệu'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final m in allMaterials)
                _MaterialBadge(material: m, earned: badges.contains(m)),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle('Đồ vật đã khám phá ($count/$total)'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: <Widget>[
              for (var i = 0; i < heroCatalog.length; i++)
                _ObjectCell(
                  item: heroCatalog[i],
                  found: discovered.contains(heroCatalog[i].id),
                  onTap: discovered.contains(heroCatalog[i].id)
                      ? () => _openHeroJourney(context, heroCatalog[i].id)
                      : null,
                )
                    .animate(delay: (i * 60).ms)
                    .fadeIn(duration: WonderTokens.durBase)
                    .scaleXY(
                        begin: 0.86, end: 1, curve: WonderTokens.curveEmphasized),
            ],
          ),
          const SizedBox(height: 24),
          WonderButton(
            label: 'Đi khám phá tiếp',
            icon: PhosphorIconsBold.magnifyingGlass,
            trailingIcon: PhosphorIconsBold.arrowRight,
            onTap: () => context.go('/camera'),
          ),
        ],
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: WonderType.display(
        color: WonderColors.textStrong,
        fontSize: 17,
        fontWeight: FontWeight.w700,
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
                  boxShadow: WonderShadows.glow(WonderColors.teal, opacity: 0.4),
                ),
                child: const Center(
                  child: PhosphorIcon(PhosphorIconsFill.trophy,
                      size: 24, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Cấp độ của bạn',
                      style: WonderType.body(
                        color: WonderColors.textSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      levelTitle(count),
                      style: WonderType.display(
                        color: WonderColors.textStrong,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
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
                ? 'Bạn đã khám phá hết — tuyệt vời!'
                : 'Khám phá $total đồ vật để lên bậc thầy!',
            style: WonderType.body(
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(WonderTokens.pill),
      child: Stack(
        children: <Widget>[
          Container(
            height: 14,
            color: WonderColors.teal.withValues(alpha: 0.14),
          ),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: 14,
              decoration: const BoxDecoration(gradient: WonderGradients.cta),
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
        border: Border.all(color: color.withValues(alpha: earned ? 0.45 : 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PhosphorIcon(
            earned ? PhosphorIconsFill.medal : PhosphorIconsBold.lockSimple,
            size: 16,
            color: earned ? const Color(0xFFE08A00) : WonderColors.textSoft,
          ),
          const SizedBox(width: 7),
          Text(
            material,
            style: WonderType.body(
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

class _ObjectCell extends StatelessWidget {
  final HeroItem item;
  final bool found;
  final VoidCallback? onTap;
  const _ObjectCell({required this.item, required this.found, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: found ? 'Xem hành trình ${item.name}' : null,
      child: GlassSurface(
        tone: GlassTone.light,
        radius: WonderTokens.radiusMd,
        padding: const EdgeInsets.all(8),
        tintOpacity: found ? null : 0.34,
        shadows: WonderShadows.soft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (found)
              ObjectAvatar(
                objectId: item.id,
                emoji: item.emoji,
                diameter: 54,
                emojiSize: 38,
                glowOpacity: 0.3,
              )
            else
              PhosphorIcon(
                PhosphorIconsBold.lockSimple,
                size: 32,
                color: WonderColors.textSoft.withValues(alpha: 0.55),
              ),
            const SizedBox(height: 6),
            Text(
              found ? item.name : '???',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WonderType.body(
                color: found
                    ? WonderColors.textStrong
                    : WonderColors.textSoft.withValues(alpha: 0.7),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
