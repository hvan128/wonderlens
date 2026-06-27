import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../data/hero_catalog.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Bộ sưu tập khám phá')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LevelCard(count: count, total: total),
          const SizedBox(height: 16),
          Text('Huy hiệu vật liệu', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in allMaterials)
                _MaterialBadge(material: m, earned: badges.contains(m)),
            ],
          ),
          const SizedBox(height: 20),
          Text('Đồ vật đã khám phá ($count/$total)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final h in heroCatalog)
                _ObjectCell(item: h, found: discovered.contains(h.id)),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.go('/camera'),
            child: const Text('Đi khám phá tiếp 🚀'),
          ),
        ],
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
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cấp độ của bạn', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(levelTitle(count),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(count >= total
                ? 'Bạn đã khám phá hết — tuyệt vời! 🏆'
                : 'Khám phá $total đồ vật để lên bậc thầy!'),
          ],
        ),
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
    final theme = Theme.of(context);
    return Chip(
      avatar: Text(earned ? '🏅' : '🔒'),
      label: Text(material),
      backgroundColor:
          earned ? theme.colorScheme.secondaryContainer : theme.disabledColor.withValues(alpha: 0.08),
    );
  }
}

class _ObjectCell extends StatelessWidget {
  final HeroItem item;
  final bool found;
  const _ObjectCell({required this.item, required this.found});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: found ? null : theme.disabledColor.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: found ? 1 : 0.35,
              child: Text(found ? item.emoji : '❓',
                  style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 6),
            Text(
              found ? item.name : '???',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
