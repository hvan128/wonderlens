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
          if (count == 0) ...<Widget>[
            const SizedBox(height: 16),
            const _EmptyState(),
          ] else ...<Widget>[
            const SizedBox(height: 12),
            WonderButton(
              label: 'Khoe bộ sưu tập',
              icon: PhosphorIconsBold.shareNetwork,
              gradient: const LinearGradient(
                colors: <Color>[WonderColors.grape, WonderColors.indigo],
              ),
              onTap: share,
            ),
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
          ],
          const SizedBox(height: 24),
          _SectionTitle(
            count == 0
                ? 'Có $total điều chờ khám phá ✨'
                : 'Đồ vật đã khám phá ($count/$total)',
          ),
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
            label: count == 0 ? 'Bắt đầu quét đồ vật' : 'Đi khám phá tiếp',
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

/// Gợi ý cấp độ kế tiếp: còn bao nhiêu vật nữa để lên bậc sau. Ngưỡng đồng bộ
/// với [levelTitle] (collection_repository) để hai chỗ không lệch nhau.
String _nextLevelHint(int count, int total) {
  if (count >= total) return 'Bạn đã sưu tầm đủ bộ — tuyệt vời! 🎉';
  for (final t in const <int>[1, 3, 5]) {
    if (count < t) return 'Còn ${t - count} vật nữa → ${levelTitle(t)}';
  }
  return 'Còn ${total - count} vật nữa → ${levelTitle(total)}';
}

/// Emoji đại diện cho từng nhóm vật liệu (dùng cho huy hiệu đã mở khoá).
String _materialEmoji(String material) {
  switch (material) {
    case 'Giấy':
      return '📄';
    case 'Nhựa':
      return '🧴';
    case 'Kim loại':
      return '🔩';
    case 'Gỗ':
      return '🪵';
    default:
      return '🏅';
  }
}

/// Trạng thái rỗng: Tia dẫn dắt trẻ quét vật đầu tiên (thay cho lưới khoá trơ).
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      tone: GlassTone.light,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      shadows: WonderShadows.card,
      child: Column(
        children: <Widget>[
          const TiaMascot(size: 76)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -4, end: 4, duration: 2400.ms, curve: Curves.easeInOut),
          const SizedBox(height: 12),
          Text(
            'Bộ sưu tập còn trống!',
            style: WonderType.display(
              color: WonderColors.textStrong,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quét đồ vật đầu tiên để Tia kể chuyện nó ra đời và mở huy hiệu nhé!',
            textAlign: TextAlign.center,
            style: WonderType.body(
              color: WonderColors.textSoft,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
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
          Row(
            children: <Widget>[
              Expanded(child: _ProgressBar(value: progress)),
              const SizedBox(width: 10),
              Text(
                '$count/$total',
                style: WonderType.display(
                  color: WonderColors.wonder,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const PhosphorIcon(
                PhosphorIconsFill.sparkle,
                size: 15,
                color: WonderColors.spark,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _nextLevelHint(count, total),
                  style: WonderType.body(
                    color: WonderColors.textStrong.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
    // Mỗi vật liệu một màu riêng (Giấy/Nhựa/Kim loại/Gỗ) khi đã mở khoá.
    final color = earned ? WonderColors.material(material) : WonderColors.textSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: earned ? 0.22 : 0.1),
        borderRadius: BorderRadius.circular(WonderTokens.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: earned ? 0.6 : 0.25),
          width: earned ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Đã mở khoá: emoji vật liệu (dễ nhận, phân biệt Giấy/Gỗ rõ ràng).
          // Chưa: ổ khoá.
          if (earned)
            Text(_materialEmoji(material), style: const TextStyle(fontSize: 15))
          else
            PhosphorIcon(PhosphorIconsBold.lockSimple, size: 16, color: color),
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
