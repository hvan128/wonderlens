import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/capture_store.dart';
import '../models/object_content.dart';
import '../theme/wonder_tokens.dart';
import '../theme/wonder_typography.dart';
import '../ui/wonder_progress.dart';

/// Khung thẻ chia sẻ chung: nền tím kỳ diệu + vệt spotlight + thương hiệu
/// WonderLens ở đỉnh + tagline ở chân. Bề rộng cố định → chụp PNG luôn gọn, nét.
///
/// Lưu ý: thẻ này được render để chụp PNG (RepaintBoundary.toImage) nên KHÔNG
/// dùng GlassSurface/BackdropFilter (backdrop không chụp được vào ảnh) — chỉ
/// dùng gradient đặc để PNG ra đúng như xem trước.
const double kShareCardWidth = 340;

class _WonderCardShell extends StatelessWidget {
  final List<Widget> children;
  const _WonderCardShell({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kShareCardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[WonderColors.wonderDeep, WonderColors.ink],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: WonderColors.wonder.withValues(alpha: 0.30),
            blurRadius: 36,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: <Widget>[
            // Vệt sáng "spotlight" tím dịu ở đỉnh cho khối có chiều sâu.
            Positioned(
              top: -90,
              left: -30,
              right: -30,
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: <Color>[
                      WonderColors.violet.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _Brand(),
                  const SizedBox(height: 18),
                  ...children,
                  const SizedBox(height: 22),
                  const _Tagline(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ chia sẻ một lần khám phá: ẢNH THẬT (cutout) của vật + tên + hành trình.
class ShareCard extends StatelessWidget {
  final ObjectContent content;

  static const int _maxStages = 6;
  static const double width = kShareCardWidth;

  const ShareCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final stages = content.stages;
    final shown =
        stages.length > _maxStages ? stages.sublist(0, _maxStages) : stages;
    final hiddenCount = stages.length - shown.length;

    return _WonderCardShell(
      children: <Widget>[
        Center(child: _HeroPhoto(objectId: content.id, emoji: content.emoji)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            content.name,
            textAlign: TextAlign.center,
            style: WonderType.display(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              if (content.materialBadge.isNotEmpty)
                _Pill(
                  icon: Symbols.science,
                  text: content.materialBadge,
                  // Màu pill theo mã màu vật liệu → đồng bộ huy hiệu bộ sưu tập.
                  color: WonderColors.material(content.materialBadge),
                ),
              if (content.source == 'live')
                const _Pill(
                  icon: Symbols.auto_awesome,
                  text: 'Khám phá vui (AI)',
                  color: WonderColors.sunny,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _Divider(),
        const SizedBox(height: 16),
        const _Label(icon: Symbols.timeline, text: 'HÀNH TRÌNH TẠO RA'),
        const SizedBox(height: 12),
        for (var i = 0; i < shown.length; i++)
          _StageRow(index: i, title: shown[i].title),
        if (hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 2),
            child: Text(
              '… và $hiddenCount chặng nữa',
              style: WonderType.body(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
}

/// Thẻ chia sẻ thành tích bộ sưu tập: cấp độ + tiến độ + huy hiệu + đồ vật.
class CollectionShareCard extends StatelessWidget {
  final String levelTitle;
  final int discoveredCount;
  final int totalCount;
  final List<String> earnedMaterials;
  final List<String> discoveredEmojis;

  static const double width = kShareCardWidth;

  const CollectionShareCard({
    super.key,
    required this.levelTitle,
    required this.discoveredCount,
    required this.totalCount,
    required this.earnedMaterials,
    required this.discoveredEmojis,
  });

  @override
  Widget build(BuildContext context) {
    final complete = totalCount > 0 && discoveredCount >= totalCount;
    final lockedCount = (totalCount - discoveredCount).clamp(0, totalCount);
    final value = totalCount == 0 ? 0.0 : discoveredCount / totalCount;

    return _WonderCardShell(
      children: <Widget>[
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: WonderGradients.badge,
              boxShadow: WonderShadows.glow(WonderColors.wonder, opacity: 0.5),
            ),
            child: Icon(
              complete ? Symbols.trophy : Symbols.science,
              size: 52,
              color: Colors.white,
              fill: 1,
              weight: 600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            levelTitle,
            textAlign: TextAlign.center,
            style: WonderType.display(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Đã khám phá $discoveredCount/$totalCount đồ vật',
            style: WonderType.body(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Chụp PNG tức thời → tắt animation để fill luôn đúng giá trị thật.
        WonderProgressBar(value: value, onDark: true, animate: Duration.zero),
        const SizedBox(height: 20),
        const _Divider(),
        const SizedBox(height: 16),
        if (earnedMaterials.isNotEmpty) ...<Widget>[
          const _Label(
              icon: Symbols.workspace_premium, text: 'HUY HIỆU VẬT LIỆU'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final m in earnedMaterials)
                _Pill(
                  icon: Symbols.workspace_premium,
                  text: m,
                  color: WonderColors.sunny,
                ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        const _Label(icon: Symbols.grid_view, text: 'ĐỒ VẬT ĐÃ SƯU TẦM'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final e in discoveredEmojis)
              _MiniTile(child: Text(e, style: const TextStyle(fontSize: 26))),
            for (var i = 0; i < lockedCount; i++)
              _MiniTile(
                child: Icon(
                  Symbols.lock,
                  size: 22,
                  color: Colors.white.withValues(alpha: 0.4),
                  fill: 1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Khung ảnh thật của vật: cutout (tách nền) trên nền sáng dịu trong khung bo
/// góc + viền sáng + glow. Chưa có ảnh → rớt về emoji trên gradient thương hiệu.
class _HeroPhoto extends StatelessWidget {
  final String objectId;
  final String emoji;
  const _HeroPhoto({required this.objectId, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final file = CaptureStore.instance.fileFor(objectId);
    const size = 158.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: file != null
            ? const RadialGradient(
                colors: <Color>[Colors.white, WonderColors.wonderSoft],
              )
            : WonderGradients.badge,
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.92), width: 3),
        boxShadow: WonderShadows.glow(WonderColors.wonder, opacity: 0.55),
      ),
      child: file != null
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Image.file(
                file,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 70))),
              ),
            )
          : Center(child: Text(emoji, style: const TextStyle(fontSize: 78))),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: WonderGradients.cta,
          ),
          child: const Icon(Symbols.travel_explore,
              size: 20, color: Colors.white, fill: 1, weight: 600),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'WonderLens',
                style: WonderType.display(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Khám phá khoa học cho bé',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WonderType.body(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Quét đồ vật • Nghe kể chuyện • Sưu tầm huy hiệu',
        textAlign: TextAlign.center,
        style: WonderType.body(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Label({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: WonderColors.mint, fill: 1, weight: 600),
        const SizedBox(width: 7),
        Text(
          text,
          style: WonderType.display(
            color: WonderColors.mint,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.white.withValues(alpha: 0.12));
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Pill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: color, fill: 1, weight: 600),
          const SizedBox(width: 6),
          Text(
            text,
            style: WonderType.body(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô vuông nhỏ bo góc bọc emoji/icon đồ vật trong lưới "đã sưu tầm".
class _MiniTile extends StatelessWidget {
  final Widget child;
  const _MiniTile({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class _StageRow extends StatelessWidget {
  final int index;
  final String title;
  const _StageRow({required this.index, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: WonderGradients.cta,
            ),
            child: Text(
              '${index + 1}',
              style: WonderType.display(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                title,
                style: WonderType.body(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
