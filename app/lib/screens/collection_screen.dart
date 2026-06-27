import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/capture_store.dart';
import '../data/collection_repository.dart';
import '../data/content_repository.dart';
import '../data/hero_catalog.dart';
import '../models/journey_args.dart';
import '../ui/ui.dart';
import '../widgets/share_sheet.dart';

/// Màn 8 · Bộ sưu tập. Header tím + bộ lọc vật liệu + lưới 2 cột (mỗi ô mở được
/// là một phim 🎬, ô khoá "? ? ?"). Tabbar dưới có nút camera nổi. Bám `.s-coll`.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _content = ContentRepository();
  String _filter = 'Tất cả';
  int _tab = 0; // 0 = sưu tập, 1 = huy hiệu

  Future<void> _replay(String id) async {
    final content = await _content.load(id);
    if (!mounted || content == null) return;
    context.push(
      '/generating',
      extra: JourneyArgs(content: content, confident: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = CollectionRepository();
    final discovered = repo.discoveredIds().toSet();
    final badges = repo.badges();
    final count = discovered.length;
    final total = heroCatalog.length;
    final locked = (total - count).clamp(0, total);

    final earnedMaterials = <String>[
      for (final m in allMaterials)
        if (badges.contains(m)) m,
    ];
    final discoveredEmojis = <String>[
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

    final items = _filter == 'Tất cả'
        ? heroCatalog
        : heroCatalog.where((h) => h.material == _filter).toList();

    return Scaffold(
      backgroundColor: WonderColors.canvasTop,
      body: Column(
        children: <Widget>[
          _Header(count: count, total: total, locked: locked),
          Expanded(
            child: _tab == 0
                ? _CollectionTab(
                    items: items,
                    discovered: discovered,
                    filter: _filter,
                    onFilter: (f) => setState(() => _filter = f),
                    onOpen: _replay,
                  )
                : _BadgesTab(
                    count: count,
                    total: total,
                    badges: badges,
                    onShare: count > 0 ? share : null,
                  ),
          ),
          _TabBar(
            tab: _tab,
            onTab: (t) => setState(() => _tab = t),
            onCamera: () => context.go('/camera'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final int total;
  final int locked;
  const _Header({required this.count, required this.total, required this.locked});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[WonderColors.violet, WonderColors.indigoDeep],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Color(0x3A3A2A8C), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Bộ sưu tập của bé',
                      style: WonderType.display(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const PhosphorIcon(PhosphorIconsFill.trophy, size: 15, color: WonderColors.spark),
                        const SizedBox(width: 6),
                        Text(
                          '$count/$total',
                          style: WonderType.body(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              WonderProgressBar(
                value: total == 0 ? 0 : count / total,
                onDark: true,
                height: 9,
                gradient: const LinearGradient(
                  colors: <Color>[WonderColors.spark, WonderColors.mint],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                locked > 0
                    ? 'Mỗi vật là một đoạn phim — còn $locked phim bí ẩn đang chờ!'
                    : 'Bé đã sưu tầm đủ mọi đoạn phim — tuyệt vời!',
                style: WonderType.body(
                  color: const Color(0xFFEBE3FF),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionTab extends StatelessWidget {
  final List<HeroItem> items;
  final Set<String> discovered;
  final String filter;
  final ValueChanged<String> onFilter;
  final ValueChanged<String> onOpen;

  const _CollectionTab({
    required this.items,
    required this.discovered,
    required this.filter,
    required this.onFilter,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final filters = <String>['Tất cả', ...allMaterials];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _FilterChip(
              label: filters[i],
              active: filters[i] == filter,
              onTap: () => onFilter(filters[i]),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 26),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 13,
              crossAxisSpacing: 13,
              childAspectRatio: 0.92,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final found = discovered.contains(item.id);
              return _Cell(
                item: item,
                found: found,
                onTap: found ? () => onOpen(item.id) : null,
              )
                  .animate(delay: (i * 50).ms)
                  .fadeIn(duration: WonderTokens.durBase)
                  .scaleXY(begin: 0.88, end: 1, curve: WonderTokens.curveEmphasized);
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? WonderColors.wonder : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? WonderColors.wonder : WonderColors.wonderSoft,
          ),
          boxShadow: active
              ? WonderShadows.glow(WonderColors.wonder, opacity: 0.3)
              : null,
        ),
        child: Text(
          label,
          style: WonderType.body(
            color: active ? Colors.white : WonderColors.textSoft,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final HeroItem item;
  final bool found;
  final VoidCallback? onTap;
  const _Cell({required this.item, required this.found, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (!found) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE0D9F2),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Opacity(
              opacity: 0.32,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0, //
                  0.2126, 0.7152, 0.0722, 0, 0, //
                  0.2126, 0.7152, 0.0722, 0, 0, //
                  0, 0, 0, 1, 0, //
                ]),
                child: Text(item.emoji, style: const TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '? ? ?',
              style: WonderType.display(
                color: WonderColors.textFaint,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '🔒 Chưa mở',
              style: WonderType.body(
                color: WonderColors.textFaint,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    final matColor = WonderColors.material(item.material);
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Xem phim ${item.name}',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WonderColors.wonderSoft),
          boxShadow: WonderShadows.soft,
        ),
        child: Stack(
          children: <Widget>[
            const Positioned(
              top: 9,
              right: 9,
              child: Text('🎬', style: TextStyle(fontSize: 14)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _CellAvatar(objectId: item.id, emoji: item.emoji),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WonderType.display(
                        color: WonderColors.textStrong,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: matColor,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      item.material,
                      style: WonderType.body(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ảnh sản phẩm thật (cutout do trẻ chụp) cho ô đã mở; chưa có thì rớt về emoji
/// theo mockup. Tự cập nhật khi vừa lưu ảnh mới (CaptureStore.revision).
class _CellAvatar extends StatelessWidget {
  final String objectId;
  final String emoji;
  const _CellAvatar({required this.objectId, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CaptureStore.revision,
      builder: (context, _, _) {
        final file = CaptureStore.instance.fileFor(objectId);
        if (file == null) {
          return Text(emoji, style: const TextStyle(fontSize: 42));
        }
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: WonderShadows.glow(WonderColors.wonder, opacity: 0.25),
          ),
          child: ClipOval(
            child: Image.file(
              file,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stack) =>
                  Text(emoji, style: const TextStyle(fontSize: 42)),
            ),
          ),
        );
      },
    );
  }
}

class _BadgesTab extends StatelessWidget {
  final int count;
  final int total;
  final Set<String> badges;
  final VoidCallback? onShare;

  const _BadgesTab({
    required this.count,
    required this.total,
    required this.badges,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
      children: <Widget>[
        GlassSurface(
          tone: GlassTone.light,
          padding: const EdgeInsets.all(18),
          shadows: WonderShadows.card,
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: WonderGradients.badge,
                ),
                child: const Center(
                  child: PhosphorIcon(PhosphorIconsFill.trophy, size: 26, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Cấp độ của bé',
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
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Huy hiệu vật liệu',
          style: WonderType.display(
            color: WonderColors.textStrong,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (final m in allMaterials)
              _MaterialBadge(material: m, earned: badges.contains(m)),
          ],
        ),
        const SizedBox(height: 24),
        if (onShare != null)
          WonderButton(
            label: 'Khoe bộ sưu tập',
            icon: PhosphorIconsBold.shareNetwork,
            gradient: const LinearGradient(
              colors: <Color>[WonderColors.grape, WonderColors.indigoDeep],
            ),
            onTap: onShare,
          ),
        const SizedBox(height: 12),
        WonderButton(
          label: 'Đi khám phá tiếp',
          icon: PhosphorIconsBold.magnifyingGlass,
          trailingIcon: PhosphorIconsBold.arrowRight,
          onTap: () => context.go('/camera'),
        ),
      ],
    );
  }
}

class _MaterialBadge extends StatelessWidget {
  final String material;
  final bool earned;
  const _MaterialBadge({required this.material, required this.earned});

  @override
  Widget build(BuildContext context) {
    final color = earned ? WonderColors.material(material) : WonderColors.textSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: earned ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(WonderTokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: earned ? 0.5 : 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PhosphorIcon(
            earned ? PhosphorIconsFill.medal : PhosphorIconsBold.lockSimple,
            size: 16,
            color: earned ? color : WonderColors.textSoft,
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

class _TabBar extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onCamera;
  const _TabBar({required this.tab, required this.onTab, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: WonderColors.wonderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _TabItem(
                  icon: PhosphorIconsBold.gridFour,
                  label: 'Sưu tập',
                  active: tab == 0,
                  onTap: () => onTab(0),
                ),
              ),
              _CameraFab(onTap: onCamera),
              Expanded(
                child: _TabItem(
                  icon: PhosphorIconsFill.star,
                  label: 'Huy hiệu',
                  active: tab == 1,
                  onTap: () => onTab(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? WonderColors.wonder : WonderColors.textFaint;
    return Pressable(
      onTap: onTap,
      haptic: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          PhosphorIcon(icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: WonderType.body(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CameraFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Center(
        // Transform.translate không ảnh hưởng layout (vòng tròn vẫn full 56px),
        // chỉ vẽ nhô lên trên thanh tab — đúng hiệu ứng FAB nổi của mockup.
        child: Transform.translate(
          offset: const Offset(0, -22),
          child: Pressable(
            onTap: onTap,
            semanticLabel: 'Khám phá',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF7BE7D6), WonderColors.mint],
                ),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: WonderShadows.glow(WonderColors.mint, opacity: 0.5),
              ),
              child: const Center(
                child: PhosphorIcon(PhosphorIconsBold.camera, size: 25, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
