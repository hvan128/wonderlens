import 'package:flutter/material.dart';

import '../data/collection_repository.dart';
import '../data/hero_catalog.dart';
import '../ui/ui.dart';
import '../widgets/dev_panel.dart';

/// Tab Hồ sơ: tóm tắt thành tích của bé — cấp độ, số món đã soi, huy hiệu vật
/// liệu — + thông tin app. Nhấn giữ dòng phiên bản = Dev panel.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CollectionRepository();
    final discovered = repo.discoveredIds().toSet();
    final journal = repo.journalEntries();
    final badges = repo.badges();
    final total = discovered.length + journal.length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          WonderTokens.tabBarClearance + 24,
        ),
        children: <Widget>[
          Text(
            'Hồ sơ của bé',
            style: WonderType.display.copyWith(
              color: WonderColors.textStrong,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 16),
          GlassSurface(
            tone: GlassTone.light,
            padding: const EdgeInsets.all(18),
            shadows: WonderShadows.card,
            child: Row(
              children: <Widget>[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: WonderGradients.badge,
                    boxShadow: WonderShadows.glow(WonderColors.teal,
                        opacity: 0.4),
                  ),
                  child: const Center(
                    child: PhosphorIcon(
                      PhosphorIconsFill.trophy,
                      size: 30,
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
                        levelTitle(discovered.length),
                        style: WonderType.title.copyWith(
                          color: WonderColors.textStrong,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        total == 0
                            ? 'Chưa soi món nào — bắt đầu nào!'
                            : 'Đã soi $total món đồ',
                        style: WonderType.body.copyWith(
                          color: WonderColors.textSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Huy hiệu siêu chất liệu',
            style: WonderType.heading.copyWith(color: WonderColors.textStrong),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final m in allMaterials)
                _Badge(material: m, earned: badges.contains(m)),
            ],
          ),
          const SizedBox(height: 28),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: () => showDevPanel(context),
              child: Text(
                'WonderLens · phiên bản demo',
                style: WonderType.caption.copyWith(
                  color: WonderColors.textSoft.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String material;
  final bool earned;

  const _Badge({required this.material, required this.earned});

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
