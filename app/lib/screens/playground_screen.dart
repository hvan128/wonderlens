import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../data/content_repository.dart';
import '../models/object_content.dart';
import '../ui/ui.dart';

/// "Sân chơi" (A1 / TASK-021): hub gom mọi trò chơi — tab đầu của bottom-nav.
///
/// Nhiệm vụ & Thẻ vật liệu mở thẳng (không cần vật). Đố vui & Ghép ngược cần một
/// vật đã khám phá **có** trò đó → chọn vật phù hợp đầu tiên; nếu chưa có thì gợi ý
/// khám phá trước (không "cụt", không crash).
class PlaygroundScreen extends StatelessWidget {
  const PlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = <Widget>[
      _GameCard(
        emoji: '🗺️',
        title: 'Nhiệm vụ',
        subtitle: 'Thử thách khám phá',
        accent: WonderColors.spark,
        onTap: () => context.push('/missions'),
      ),
      _GameCard(
        emoji: '🃏',
        title: 'Thẻ vật liệu',
        subtitle: 'Mạng lưới sưu tầm',
        accent: WonderColors.mint,
        onTap: () => context.push('/material-cards'),
      ),
      _GameCard(
        emoji: '❓',
        title: 'Đố vui',
        subtitle: 'Trả lời & nhận sao',
        accent: WonderColors.grape,
        onTap: () => _launchForGame(
          context,
          hasGame: (c) => c.quiz.isNotEmpty,
          route: '/quiz',
          emptyHint: 'Hãy khám phá một đồ vật trước để chơi đố vui nhé!',
        ),
      ),
      _GameCard(
        emoji: '🧩',
        title: 'Ghép ngược',
        subtitle: 'Lắp lại từ nguyên liệu',
        accent: WonderColors.sky,
        onTap: () => _launchForGame(
          context,
          hasGame: (c) => c.assembly != null,
          route: '/assembly',
          emptyHint:
              'Khám phá bút bi, bút chì, giấy A4 hay chai nhựa để chơi ghép ngược nhé!',
        ),
      ),
    ];

    return WonderScaffold(
      header: const WonderHeader(
        title: 'Sân chơi',
        subtitle: 'Chọn một trò để chơi nhé!',
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.02,
        children: <Widget>[
          for (var i = 0; i < games.length; i++)
            games[i]
                .animate(delay: (i * 70).ms)
                .fadeIn(duration: WonderTokens.durBase)
                .scaleXY(
                  begin: 0.9,
                  end: 1,
                  curve: WonderTokens.curveEmphasized,
                ),
        ],
      ),
    );
  }

  /// Tìm vật đã khám phá đầu tiên **có** trò [hasGame] rồi mở [route]; nếu chưa
  /// có vật phù hợp → hiện gợi ý nhẹ nhàng thay vì mở màn "đang chuẩn bị".
  Future<void> _launchForGame(
    BuildContext context, {
    required bool Function(ObjectContent) hasGame,
    required String route,
    required String emptyHint,
  }) async {
    final repo = ContentRepository();
    final discovered = CollectionRepository().discoveredIds();
    ObjectContent? pick;
    for (final id in discovered) {
      final c = await repo.load(id);
      if (c != null && hasGame(c)) {
        pick = c;
        break;
      }
    }
    if (!context.mounted) return;
    if (pick == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(emptyHint)));
      return;
    }
    context.push(route, extra: pick);
  }
}

class _GameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _GameCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      tone: GlassTone.light,
      radius: WonderTokens.radiusLg,
      padding: const EdgeInsets.all(16),
      shadows: WonderShadows.soft,
      onTap: onTap,
      semanticLabel: title,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: WonderType.display(
              color: WonderColors.textStrong,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: WonderType.body(
              color: WonderColors.textSoft,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
