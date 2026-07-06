import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../data/hero_catalog.dart';
import '../data/material_catalog.dart';
import '../models/wonder_material.dart';
import '../ui/ui.dart';

/// Màn "Thẻ vật liệu" (F-09 / TASK-008): lưới thẻ sưu tầm + mạng lưới.
///
/// Thẻ mở khi đã khám phá một vật dùng vật liệu đó (suy ra từ `discoveredIds`,
/// gồm cả chuỗi nguồn gốc). Chạm thẻ đã mở → xem chi tiết + các vật cùng vật liệu.
class MaterialCardsScreen extends StatelessWidget {
  const MaterialCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Guard: catalog nạp async lúc khởi động — nếu chưa sẵn sàng thì hiện
    // trạng thái chờ nhẹ thay vì crash (cùng cách Bộ sưu tập kiểm `isReady`).
    if (!MaterialCatalog.isReady) {
      return WonderScaffold(
        header: WonderHeader(
          title: 'Thẻ vật liệu',
          subtitle: 'Đang chuẩn bị...',
          showBack: true,
          onBack: () =>
              context.canPop() ? context.pop() : context.go('/collection'),
        ),
        body: const _CatalogWaitingState(),
      );
    }

    final discovered = CollectionRepository().discoveredIds().toSet();
    final catalog = MaterialCatalog.instance;
    final unlocked = catalog.unlockedCards(discovered);
    final all = catalog.all;
    final openCount = all.where((m) => unlocked.contains(m.id)).length;

    return WonderScaffold(
      header: WonderHeader(
        title: 'Thẻ vật liệu',
        subtitle: 'Đã mở $openCount/${all.length}',
        showBack: true,
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/collection'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.84,
        children: <Widget>[
          for (var i = 0; i < all.length; i++)
            _MaterialTile(
                  material: all[i],
                  unlocked: unlocked.contains(all[i].id),
                  foundCount: catalog
                      .objectsUsing(all[i].id)
                      .where(discovered.contains)
                      .length,
                  onTap: unlocked.contains(all[i].id)
                      ? () => _showDetail(context, all[i], discovered)
                      : null,
                )
                .animate(delay: (i * 55).ms)
                .fadeIn(duration: WonderTokens.durBase)
                .scaleXY(
                  begin: 0.86,
                  end: 1,
                  curve: WonderTokens.curveEmphasized,
                ),
        ],
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    WonderMaterial material,
    Set<String> discovered,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _MaterialDetailSheet(material: material, discovered: discovered),
    );
  }
}

/// Trạng thái chờ khi [MaterialCatalog] chưa nạp xong: Tia lơ lửng + một dòng
/// nhắn — nhẹ nhàng, không spinner, biến mất ngay khi mở lại màn.
class _CatalogWaitingState extends StatelessWidget {
  const _CatalogWaitingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WonderTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const TiaMascot(size: 72)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: -4,
                  end: 4,
                  duration: 2400.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: WonderTokens.space16),
            Text(
              'Kho thẻ đang được chuẩn bị, quay lại sau nhé!',
              textAlign: TextAlign.center,
              style: WonderType.body(
                color: WonderColors.textSoft,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: WonderTokens.durBase),
    );
  }
}

/// Màu gợi ý theo nhóm vật liệu (dùng token sẵn có để kế thừa theme khi đổi).
Color _categoryColor(String category) {
  switch (category) {
    case 'Giấy':
      return WonderColors.sky;
    case 'Nhựa':
      return WonderColors.grape;
    case 'Kim loại':
      return WonderColors.indigo;
    case 'Gỗ':
      return WonderColors.mint;
    case 'Thuỷ tinh':
      return WonderColors.cyan;
    default:
      return WonderColors.teal;
  }
}

class _MaterialTile extends StatelessWidget {
  final WonderMaterial material;
  final bool unlocked;
  final int foundCount;
  final VoidCallback? onTap;

  const _MaterialTile({
    required this.material,
    required this.unlocked,
    required this.foundCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(material.category);
    // Thẻ đã mở: viền màu category + glow nhẹ cùng màu (khối rõ kiểu Duolingo).
    // Thẻ khoá: giữ mờ nhưng vẫn có viền trung tính mảnh để thấy "khối".
    final border = Border.all(
      color: unlocked
          ? color.withValues(alpha: 0.6)
          : WonderColors.textFaint.withValues(alpha: 0.2),
      width: 1.5,
    );
    return Pressable(
      onTap: onTap,
      semanticLabel: unlocked ? 'Thẻ ${material.name}' : 'Thẻ chưa mở',
      child: Container(
        // Viền vẽ đè lên mép kính (foreground) để cùng scale khi bấm.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
          border: border,
        ),
        child: GlassSurface(
          tone: GlassTone.light,
          radius: WonderTokens.radiusMd,
          padding: const EdgeInsets.all(WonderTokens.space12),
          tintOpacity: unlocked ? null : 0.34,
          shadows: unlocked
              ? <BoxShadow>[
                  ...WonderShadows.soft,
                  ...WonderShadows.glow(color, opacity: 0.2),
                ]
              : WonderShadows.soft,
          child: _tileBody(color),
        ),
      ),
    );
  }

  Widget _tileBody(Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: unlocked ? 0.18 : 0.10),
            border: Border.all(
              color: color.withValues(alpha: unlocked ? 0.45 : 0.20),
            ),
          ),
          child: Center(
            child: unlocked
                ? Text(material.emoji, style: const TextStyle(fontSize: 30))
                : PhosphorIcon(
                    PhosphorIconsBold.lockSimple,
                    size: 26,
                    color: WonderColors.textSoft.withValues(alpha: 0.55),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          unlocked ? material.name : '???',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WonderType.display(
            color: unlocked
                ? WonderColors.textStrong
                : WonderColors.textSoft.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unlocked
              ? (material.isSource ? 'Vật liệu thô' : 'Đã chế biến')
              : 'Chưa khám phá',
          style: WonderType.body(
            color: WonderColors.textSoft,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (unlocked && foundCount > 0) ...<Widget>[
          const SizedBox(height: 6),
          WonderChip(
            label: 'Có trong $foundCount vật',
            icon: PhosphorIconsFill.sparkle,
            color: color,
            tone: GlassTone.light,
          ),
        ],
      ],
    );
  }
}

class _MaterialDetailSheet extends StatelessWidget {
  final WonderMaterial material;
  final Set<String> discovered;

  const _MaterialDetailSheet({
    required this.material,
    required this.discovered,
  });

  @override
  Widget build(BuildContext context) {
    final catalog = MaterialCatalog.instance;
    final color = _categoryColor(material.category);
    final chain = catalog.derivationChain(material.id);
    final users = catalog.objectsUsing(material.id);
    final foundUsers = users.where(discovered.contains).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.66,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          gradient: WonderGradients.canvas,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(WonderTokens.radiusXl),
          ),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: WonderColors.textSoft.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(WonderTokens.pill),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.18),
                    border: Border.all(color: color.withValues(alpha: 0.45)),
                  ),
                  child: Center(
                    child: Text(
                      material.emoji,
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        material.name,
                        style: WonderType.display(
                          color: WonderColors.textStrong,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      WonderChip(
                        label: material.category,
                        color: color,
                        tone: GlassTone.light,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (chain.length > 1) ...<Widget>[
              const SizedBox(height: 18),
              _SheetLabel('Hành trình tạo ra'),
              const SizedBox(height: 8),
              _DerivationChain(chain: chain),
            ],
            const SizedBox(height: 18),
            Text(
              material.blurb,
              style: WonderType.body(
                color: WonderColors.textStrong.withValues(alpha: 0.9),
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (material.funFacts.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              for (final fact in material.funFacts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: PhosphorIcon(
                          PhosphorIconsFill.sparkle,
                          size: 16,
                          color: WonderColors.sunny,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fact,
                          style: WonderType.body(
                            color: WonderColors.textStrong.withValues(
                              alpha: 0.82,
                            ),
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 16),
            _SheetLabel('Mạng lưới — có trong ${users.length} vật'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final id in users)
                  _NetworkObject(
                    item: heroById(id),
                    found: discovered.contains(id),
                  ),
              ],
            ),
            if (foundUsers < users.length) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Còn ${users.length - foundUsers} vật nữa đang chờ bạn khám phá!',
                style: WonderType.body(
                  color: WonderColors.textSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: WonderType.display(
      color: WonderColors.textStrong,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _DerivationChain extends StatelessWidget {
  final List<String> chain;
  const _DerivationChain({required this.chain});

  @override
  Widget build(BuildContext context) {
    final catalog = MaterialCatalog.instance;
    final nodes = <Widget>[];
    for (var i = 0; i < chain.length; i++) {
      if (i > 0) {
        nodes.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: PhosphorIcon(
              PhosphorIconsBold.arrowRight,
              size: 16,
              color: WonderColors.textSoft,
            ),
          ),
        );
      }
      final m = catalog.byId(chain[i]);
      nodes.add(_ChainNode(material: m));
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 6,
      children: nodes,
    );
  }
}

class _ChainNode extends StatelessWidget {
  final WonderMaterial? material;
  const _ChainNode({required this.material});

  @override
  Widget build(BuildContext context) {
    final m = material;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(WonderTokens.radiusSm),
        border: Border.all(color: WonderColors.textSoft.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(m?.emoji ?? '✨', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            m?.name ?? '?',
            style: WonderType.body(
              color: WonderColors.textStrong,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkObject extends StatelessWidget {
  final HeroItem? item;
  final bool found;
  const _NetworkObject({required this.item, required this.found});

  @override
  Widget build(BuildContext context) {
    final it = item;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: found ? 0.6 : 0.32),
        borderRadius: BorderRadius.circular(WonderTokens.radiusSm),
        border: Border.all(
          color: WonderColors.textSoft.withValues(alpha: found ? 0.28 : 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (found)
            Text(it?.emoji ?? '✨', style: const TextStyle(fontSize: 18))
          else
            PhosphorIcon(
              PhosphorIconsBold.lockSimple,
              size: 15,
              color: WonderColors.textSoft.withValues(alpha: 0.55),
            ),
          const SizedBox(width: 8),
          Text(
            found ? (it?.name ?? '') : '???',
            style: WonderType.body(
              color: found
                  ? WonderColors.textStrong
                  : WonderColors.textSoft.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
