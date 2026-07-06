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
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  /// Route đang tải nội dung (Đố vui / Ghép ngược) — thẻ tương ứng hiện spinner
  /// nhỏ thay icon và mọi tap lặp bị bỏ qua cho tới khi tải xong.
  String? _loadingRoute;

  @override
  Widget build(BuildContext context) {
    final games = <Widget>[
      _GameCard(
        icon: PhosphorIconsFill.mapTrifold,
        title: 'Nhiệm vụ',
        subtitle: 'Thử thách khám phá',
        // Honey thay spark: hết cảnh icon vàng trên nền vàng nhạt cùng tông.
        accent: WonderColors.honey,
        bgAlpha: 0.14,
        onTap: () => context.push('/missions'),
      ),
      _GameCard(
        icon: PhosphorIconsFill.cardsThree,
        title: 'Thẻ vật liệu',
        subtitle: 'Mạng lưới sưu tầm',
        accent: WonderColors.mint,
        onTap: () => context.push('/material-cards'),
      ),
      _GameCard(
        icon: PhosphorIconsFill.quiz,
        title: 'Đố vui',
        subtitle: 'Trả lời & nhận sao',
        accent: WonderColors.grape,
        busy: _loadingRoute == '/quiz',
        onTap: () => _launchForGame(
          hasGame: (c) => c.quiz.isNotEmpty,
          route: '/quiz',
          emptyHint: 'Hãy khám phá một đồ vật trước để chơi đố vui nhé!',
        ),
      ),
      _GameCard(
        icon: PhosphorIconsBold.puzzlePiece,
        title: 'Ghép ngược',
        subtitle: 'Lắp lại từ nguyên liệu',
        accent: WonderColors.sky,
        busy: _loadingRoute == '/assembly',
        onTap: () => _launchForGame(
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
      body: GridView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        // Chiều cao cố định thay vì aspect ratio (máy hẹp bị tràn đáy 12px):
        // padding 16×2 + icon 56 + gap 12 + title ~28 (Baloo 2 @17)
        // + gap 2 + subtitle 2 dòng ~36 (Nunito @13) ≈ 166 → 192 kèm dư an toàn.
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 192,
        ),
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
  /// Trong lúc tải, [_loadingRoute] khoá tap lặp và cho thẻ hiện spinner.
  Future<void> _launchForGame({
    required bool Function(ObjectContent) hasGame,
    required String route,
    required String emptyHint,
  }) async {
    if (_loadingRoute != null) return;
    setState(() => _loadingRoute = route);
    try {
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
      if (!mounted) return;
      if (pick == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(emptyHint)));
        return;
      }
      context.push(route, extra: pick);
    } finally {
      if (mounted) setState(() => _loadingRoute = null);
    }
  }
}

/// Sẫm hoá [accent] để icon nổi rõ trên vòng tròn nền nhạt cùng tông —
/// cùng công thức cạnh 3D của WonderButton (hạ lightness 0.16 trong HSL).
Color _inkOf(Color accent) {
  final hsl = HSLColor.fromColor(accent);
  return hsl.withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0)).toColor();
}

class _GameCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  /// Alpha của vòng tròn nền — accent ấm/đậm (honey) dùng mức thấp hơn 0.14.
  final double bgAlpha;

  /// Đang tải nội dung trò (async) → hiện spinner thay icon, khoá tap.
  final bool busy;

  const _GameCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.bgAlpha = 0.16,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    // Công thức chung cho cả 4 thẻ: nền = accent nhạt, icon = accent sẫm hoá
    // → luôn tương phản rõ, không còn icon nhạt trên nền nhạt.
    final ink = _inkOf(accent);
    return GlassSurface(
      tone: GlassTone.light,
      radius: WonderTokens.radiusLg,
      padding: const EdgeInsets.all(WonderTokens.space16),
      shadows: WonderShadows.soft,
      onTap: busy ? null : onTap,
      semanticLabel: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: bgAlpha),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(ink),
                      ),
                    )
                  : PhosphorIcon(icon, size: 30, color: ink),
            ),
          ),
          const SizedBox(height: WonderTokens.space12),
          Text(
            title,
            style: WonderType.display(
              color: WonderColors.textStrong,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: WonderTokens.space2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WonderType.body(
              color: WonderColors.textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
