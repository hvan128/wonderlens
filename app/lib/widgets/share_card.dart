import 'package:flutter/material.dart';
import '../ui/phosphor_compat.dart';

import '../data/capture_store.dart';
import '../models/object_content.dart';
import '../theme/wonder_tokens.dart';
import '../ui/wonder_logo.dart';

/// Khung thẻ chia sẻ chung: nền tối sang trọng + vệt spotlight + thương hiệu
/// WonderLens ở đỉnh + tagline ở chân. Bề rộng cố định → chụp PNG luôn gọn, nét.
///
/// Lưu ý: thẻ này được render để chụp PNG (RepaintBoundary.toImage) nên KHÔNG
/// dùng BackdropFilter/glass (backdrop không chụp được) — chỉ gradient đặc.
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
          colors: <Color>[Color(0xFF15405A), Color(0xFF0B1220)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: WonderColors.teal.withValues(alpha: 0.30),
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
            // Vệt sáng "spotlight" dịu ở đỉnh cho khối có chiều sâu.
            Positioned(
              top: -90,
              left: -30,
              right: -30,
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: <Color>[
                      WonderColors.teal.withValues(alpha: 0.28),
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
    final shown = stages.length > _maxStages
        ? stages.sublist(0, _maxStages)
        : stages;
    final hiddenCount = stages.length - shown.length;

    return _WonderCardShell(
      children: <Widget>[
        Center(
          child: _HeroPhoto(objectId: content.id, emoji: content.emoji),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            content.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
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
                  icon: PhosphorIconsFill.flask,
                  text: content.materialBadge,
                  color: WonderColors.teal,
                ),
              if (content.source == 'live')
                const _Pill(
                  icon: PhosphorIconsFill.sparkle,
                  text: 'AI kể chuyện vui',
                  color: WonderColors.sunny,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _Divider(),
        const SizedBox(height: 16),
        const _Label(
          icon: PhosphorIconsBold.journey,
          text: 'HÀNH TRÌNH KHOA HỌC',
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < shown.length; i++)
          _StageRow(index: i, title: shown[i].title),
        if (hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 2),
            child: Text(
              '… và $hiddenCount manh mối nữa',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

/// Thẻ chia sẻ thành tích bộ sưu tập: cấp độ + tiến độ + huy hiệu + đồ vật.
/// TÔNG GIẤY ẤM (khung [_KraftCardShell]) — cùng thế giới với cụm thẻ giấy thô
/// của màn Hồ sơ, điểm nhấn mật ong thay teal; chữ mực tối trên nền giấy.
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
    final inkFaint = WonderColors.textStrong.withValues(alpha: 0.10);

    return _KraftCardShell(
      children: <Widget>[
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: WonderGradients.honey,
              boxShadow: WonderShadows.glow(WonderColors.sunny, opacity: 0.5),
            ),
            child: PhosphorIcon(
              complete ? PhosphorIconsFill.trophy : PhosphorIconsFill.flask,
              size: 52,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            levelTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WonderColors.textStrong,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Đã mở khóa $discoveredCount/$totalCount đồ vật',
            style: const TextStyle(
              color: WonderColors.textSoft,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ProgressBar(value: value),
        const SizedBox(height: 20),
        _Divider(color: inkFaint),
        const SizedBox(height: 16),
        if (earnedMaterials.isNotEmpty) ...<Widget>[
          const _Label(
            icon: PhosphorIconsFill.medal,
            text: 'HUY HIỆU CHẤT LIỆU',
            color: WonderColors.sunnyDeep,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final m in earnedMaterials)
                _Pill(
                  icon: PhosphorIconsFill.medal,
                  text: m,
                  color: WonderColors.sunnyDeep,
                  textColor: WonderColors.textStrong,
                ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        const _Label(
          icon: PhosphorIconsBold.grid,
          text: 'ĐỒ VẬT ĐÃ MỞ KHÓA',
          color: WonderColors.sunnyDeep,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (var i = 0; i < discoveredEmojis.length; i++)
              _KraftMiniTile(
                index: i,
                child: Text(
                  discoveredEmojis[i],
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            for (var i = 0; i < lockedCount; i++)
              _KraftMiniTile(
                index: discoveredEmojis.length + i,
                locked: true,
                child: PhosphorIcon(
                  PhosphorIconsBold.lockSimple,
                  size: 22,
                  color: WonderColors.textSoft.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Khung thẻ khoe tông GIẤY ẤM: kraft texture nhuộm be sáng (thiếu asset →
/// màu đặc), chữ mực tối. Cũng render để chụp PNG nên chỉ dùng ảnh + màu đặc,
/// không glass/backdrop.
class _KraftCardShell extends StatelessWidget {
  final List<Widget> children;
  const _KraftCardShell({required this.children});

  static const Color _paperTint = Color(0xFFF3E9D2);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kShareCardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: <Widget>[
            // Texture phủ 55% trên màu giấy đặc: thẻ khoe to + sáng hơn thẻ
            // cụm Hồ sơ nhiều nên đốm kraft nguyên cường độ trông như vết bẩn.
            Positioned.fill(
              child: ColoredBox(
                color: _paperTint,
                child: Opacity(
                  opacity: 0.55,
                  child: Image.asset(
                    'assets/images/kraft_paper.png',
                    fit: BoxFit.cover,
                    color: _paperTint,
                    colorBlendMode: BlendMode.multiply,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
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
                  const _KraftBrand(),
                  const SizedBox(height: 18),
                  ...children,
                  const SizedBox(height: 22),
                  const _KraftTagline(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thương hiệu trên nền giấy: logo khẩu độ pastel (tĩnh) + tên mực tối.
class _KraftBrand extends StatelessWidget {
  const _KraftBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const WonderLogo(size: 36, spin: false),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'WonderLens',
                style: TextStyle(
                  color: WonderColors.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Khoa học vui cho bé tò mò',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: WonderColors.textSoft.withValues(alpha: 0.9),
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

class _KraftTagline extends StatelessWidget {
  const _KraftTagline();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Soi đồ vật • Mở manh mối • Gom huy hiệu',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: WonderColors.textSoft,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Ô vật trong lưới "đã sưu tầm" bản giấy ấm: thẻ giấy mini nhuộm màu theo
/// bảng cụm thẻ Hồ sơ, nghiêng theo bộ góc chung [WonderTilt] → vọng lại kệ
/// trưng bày. Khoá = ô mực mờ + ổ khoá (vẫn nghiêng cho đều nhịp).
class _KraftMiniTile extends StatelessWidget {
  final int index;
  final bool locked;
  final Widget child;

  const _KraftMiniTile({
    required this.index,
    required this.child,
    this.locked = false,
  });

  /// Màu giấy cụm thẻ Hồ sơ (tan · cam · mật · đỏ · be).
  static const List<Color> _tints = <Color>[
    Color(0xFFCFC3AE),
    Color(0xFFD98A45),
    Color(0xFFE0AE5B),
    Color(0xFFD8503A),
    Color(0xFFDCC9A8),
  ];

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: WonderTilt.at(index),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: locked
              ? WonderColors.textStrong.withValues(alpha: 0.06)
              : _tints[index % _tints.length],
          borderRadius: BorderRadius.circular(12),
          border: locked
              ? Border.all(
                  color: WonderColors.textStrong.withValues(alpha: 0.12),
                )
              : null,
          boxShadow: locked
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: child,
      ),
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
                colors: <Color>[Color(0xFFFFFFFF), Color(0xFFD9EEF4)],
              )
            : WonderGradients.badge,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
          width: 3,
        ),
        boxShadow: WonderShadows.glow(WonderColors.teal, opacity: 0.55),
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
                  child: Text(emoji, style: const TextStyle(fontSize: 70)),
                ),
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
          child: const PhosphorIcon(
            PhosphorIconsDuotone.binoculars,
            size: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'WonderLens',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Khoa học vui cho bé tò mò',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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
        'Soi đồ vật • Mở manh mối • Gom huy hiệu',
        textAlign: TextAlign.center,
        style: TextStyle(
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

  /// Màu chữ+icon: mint trên khung tối, sunnyDeep trên khung giấy ấm.
  final Color color;

  const _Label({
    required this.icon,
    required this.text,
    this.color = WonderColors.mint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        PhosphorIcon(icon, size: 16, color: color),
        const SizedBox(width: 7),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  /// Trắng mờ trên khung tối, mực mờ trên khung giấy ấm.
  final Color? color;
  const _Divider({this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: color ?? Colors.white.withValues(alpha: 0.12),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value; // 0..1
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    // Tông giấy ấm (chỉ CollectionShareCard dùng): rãnh mực mờ + mật ong.
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 12,
        color: WonderColors.textStrong.withValues(alpha: 0.10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: const BoxDecoration(gradient: WonderGradients.honey),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  /// Màu chữ: trắng trên khung tối, mực tối trên khung giấy ấm.
  final Color textColor;

  const _Pill({
    required this.icon,
    required this.text,
    required this.color,
    this.textColor = Colors.white,
  });

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
          PhosphorIcon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                title,
                style: const TextStyle(
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
