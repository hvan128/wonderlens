import 'package:flutter/material.dart';
import '../ui/phosphor_compat.dart';

import '../data/capture_store.dart';
import '../models/object_content.dart';
import '../theme/wonder_tokens.dart';
import '../ui/wonder_logo.dart';

/// Bề rộng cố định → chụp PNG luôn gọn, nét.
///
/// Lưu ý: các thẻ share render để chụp PNG (RepaintBoundary.toImage) nên KHÔNG
/// dùng BackdropFilter/glass (backdrop không chụp được) — chỉ gradient đặc + ảnh.
const double kShareCardWidth = 340;

/// Nền giấy ấm cho lõi thẻ bài.
const Color _kPaper = Color(0xFFFBF6EA);

/// "Hệ" chất liệu — như element của Pokémon. Phân loại [materialBadge] tự do
/// ("Nhựa + Mực", "Thép không gỉ"…) về 5 nhóm + màu điểm nhấn + 3 chỉ số phái
/// sinh (0..5: thân thiện · bền · phổ biến). Vật lạ → hệ mặc định (teal).
class _MaterialType {
  final String label;
  final Color accent;
  final int eco;
  final int durable;
  final int common;
  const _MaterialType(
    this.label,
    this.accent,
    this.eco,
    this.durable,
    this.common,
  );
}

_MaterialType _materialTypeOf(String badge) {
  final b = badge.toLowerCase();
  if (b.contains('giấy')) {
    return const _MaterialType('Giấy', Color(0xFFB88A2E), 4, 2, 5);
  }
  if (b.contains('nhựa')) {
    return const _MaterialType('Nhựa', Color(0xFF0E97AC), 1, 3, 5);
  }
  if (b.contains('thép') || b.contains('inox') || b.contains('kim loại')) {
    return const _MaterialType('Kim loại', Color(0xFF566B82), 2, 5, 3);
  }
  if (b.contains('gỗ') || b.contains('tre')) {
    return const _MaterialType('Gỗ · Tre', Color(0xFF8A5A2B), 4, 3, 3);
  }
  if (b.contains('cao su')) {
    return const _MaterialType('Cao su', Color(0xFFC0512E), 2, 4, 2);
  }
  return _MaterialType(
    badge.isEmpty ? 'Vật liệu' : badge,
    WonderColors.tealDeep,
    3,
    3,
    3,
  );
}

/// Loại bỏ emoji/ký hiệu khỏi chuỗi để thẻ khoe sạch (chỉ dùng icon Iconsax).
String _plain(String s) => s
    .replaceAll(
      RegExp(
        r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE00}-\u{FE0F}\u{200D}\u{1F1E6}-\u{1F1FF}]',
        unicode: true,
      ),
      '',
    )
    .trim();

/// Thẻ chia sẻ một lần khám phá — kiểu **thẻ bài sưu tầm** (Pokémon): khung vàng
/// mật + lõi giấy ấm. Chất liệu là "hệ" (màu + chỉ số), hành trình hình thành là
/// chuỗi tiến hoá (ảnh từng chặng), lịch sử là dòng chú giải. Điểm nhấn đổi theo
/// hệ; icon lấy từ bộ Iconsax (shim), logo là ảnh thật.
class ShareCard extends StatelessWidget {
  final ObjectContent content;

  static const int _maxStages = 4;
  static const double width = kShareCardWidth;

  const ShareCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final type = _materialTypeOf(content.materialBadge);
    final accent = type.accent;
    final stages = content.stages;
    final evo = stages.length > _maxStages
        ? stages.sublist(0, _maxStages)
        : stages;
    final history = (content.history ?? '').trim();

    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFE7A6),
            WonderColors.sunny,
            WonderColors.sunnyDeep,
            Color(0xFFB96E00),
          ],
          stops: <double>[0.0, 0.32, 0.78, 1.0],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 34,
            spreadRadius: -10,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            gradient: const RadialGradient(
              center: Alignment(0, -0.9),
              radius: 1.25,
              colors: <Color>[Color(0xFFFFFDF6), _kPaper],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _PokeHeader(
                  name: content.name,
                  type: type,
                  rarity: stages.length,
                ),
                const SizedBox(height: 11),
                _PokeBody(content: content, type: type),
                const SizedBox(height: 13),
                _SectionHeader(
                  icon: PhosphorIconsBold.journey,
                  text: 'HÀNH TRÌNH HÌNH THÀNH',
                  accent: accent,
                ),
                const SizedBox(height: 8),
                _EvolutionChain(stages: evo, accent: accent),
                if (history.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _HistoryFlavor(text: history, accent: accent),
                ],
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: WonderColors.textStrong.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 10),
                _PokeFooter(source: content.source, accent: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Đầu thẻ: tên (Baloo) + huy hiệu hệ bên trái; dải sao "độ hiếm" (= số chặng
/// hành trình) bên phải.
class _PokeHeader extends StatelessWidget {
  final String name;
  final _MaterialType type;
  final int rarity;

  const _PokeHeader({
    required this.name,
    required this.type,
    required this.rarity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Baloo 2',
                  color: WonderColors.textStrong,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              _TypeBadge(type: type),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _RarityStars(count: rarity),
      ],
    );
  }
}

/// Huy hiệu "hệ" — icon phân tích chất liệu + tên hệ, nhuộm theo màu hệ.
class _TypeBadge extends StatelessWidget {
  final _MaterialType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final accent = type.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 4, 10, 4),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.16),
          Colors.white,
        ),
        borderRadius: BorderRadius.circular(WonderTokens.pill),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PhosphorIcon(PhosphorIconsFill.flask, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            'Hệ ${type.label}',
            style: TextStyle(
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.82),
                WonderColors.textStrong,
              ),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dải 5 sao độ hiếm — số sao sáng = số chặng của hành trình.
class _RarityStars extends StatelessWidget {
  final int count;
  const _RarityStars({required this.count});

  @override
  Widget build(BuildContext context) {
    final filled = count.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 1.5),
            child: PhosphorIcon(
              PhosphorIconsFill.star,
              size: 12,
              color: i < filled
                  ? WonderColors.sunnyDeep
                  : WonderColors.textStrong.withValues(alpha: 0.16),
            ),
          ),
      ],
    );
  }
}

/// Thân thẻ 2 cột: cửa sổ ảnh (trái) + bảng chỉ số (phải), cao bằng nhau.
class _PokeBody extends StatelessWidget {
  final ObjectContent content;
  final _MaterialType type;

  const _PokeBody({required this.content, required this.type});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: 105,
            child: _HeroWindow(objectId: content.id, accent: type.accent),
          ),
          const SizedBox(width: 11),
          Expanded(
            flex: 100,
            child: _StatsPanel(
              type: type,
              stageCount: content.stages.length,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cửa sổ ảnh vật (ảnh bé chụp) trong khung vàng + nền sáng dịu; sao hero góc
/// trên, nhãn "Ảnh của bé" góc dưới. Chưa có ảnh → icon ảnh nhạt (không emoji).
class _HeroWindow extends StatelessWidget {
  final String objectId;
  final Color accent;

  const _HeroWindow({required this.objectId, required this.accent});

  @override
  Widget build(BuildContext context) {
    final file = CaptureStore.instance.fileFor(objectId);
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFE7A6), WonderColors.sunnyDeep],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: WonderColors.sunnyDeep.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: -6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 1.2,
                  colors: <Color>[
                    Color(0xFFFFFFFF),
                    Color(0xFFDDEFF4),
                    Color(0xFFC3E4EC),
                  ],
                  stops: <double>[0.0, 0.62, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: file != null
                  ? Image.file(
                      file,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => _fallback(),
                    )
                  : _fallback(),
            ),
            Positioned(
              right: 7,
              top: 6,
              child: Container(
                width: 23,
                height: 23,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(7)),
                  gradient: WonderGradients.badge,
                ),
                child: const PhosphorIcon(
                  PhosphorIconsFill.star,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
            if (file != null)
              Positioned(
                left: 7,
                bottom: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(WonderTokens.pill),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PhosphorIcon(
                        PhosphorIconsFill.image,
                        size: 11,
                        color: WonderColors.tealDeep,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Ảnh của bé',
                        style: TextStyle(
                          color: WonderColors.textStrong,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Center(
    child: PhosphorIcon(
      PhosphorIconsFill.image,
      size: 52,
      color: accent.withValues(alpha: 0.45),
    ),
  );
}

/// Bảng chỉ số kiểu thẻ bài: 3 trục (thân thiện · bền · phổ biến) dạng pip 5
/// nấc, phái sinh theo hệ; chân bảng ghi chất liệu + số chặng.
class _StatsPanel extends StatelessWidget {
  final _MaterialType type;
  final int stageCount;

  const _StatsPanel({required this.type, required this.stageCount});

  @override
  Widget build(BuildContext context) {
    final accent = type.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.07),
          const Color(0xFFFFFDF6),
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StatRow(
            icon: PhosphorIconsFill.tree,
            label: 'Thân thiện',
            value: type.eco,
            accent: accent,
          ),
          const SizedBox(height: 9),
          _StatRow(
            icon: PhosphorIconsFill.shield,
            label: 'Độ bền',
            value: type.durable,
            accent: accent,
          ),
          const SizedBox(height: 9),
          _StatRow(
            icon: PhosphorIconsFill.repeat,
            label: 'Phổ biến',
            value: type.common,
            accent: accent,
          ),
          const SizedBox(height: 9),
          Container(
            height: 1,
            color: WonderColors.textStrong.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Chất liệu ',
                    style: TextStyle(
                      color: WonderColors.textSoft,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: type.label,
                        style: const TextStyle(color: WonderColors.textStrong),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text.rich(
                TextSpan(
                  text: '$stageCount',
                  style: const TextStyle(
                    color: WonderColors.textStrong,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                  children: const <TextSpan>[
                    TextSpan(
                      text: ' chặng',
                      style: TextStyle(color: WonderColors.textSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color accent;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        PhosphorIcon(icon, size: 14, color: accent),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: WonderColors.textStrong,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _Pips(value: value, accent: accent),
      ],
    );
  }
}

/// 5 ô vuông nhỏ; số ô sáng = giá trị chỉ số.
class _Pips extends StatelessWidget {
  final int value;
  final Color accent;

  const _Pips({required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i < value
                    ? accent
                    : WonderColors.textStrong.withValues(alpha: 0.14),
              ),
            ),
          ),
      ],
    );
  }
}

/// Nhãn mục kiểu thẻ bài: icon + chữ HOA + gạch mờ dần theo màu hệ.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;

  const _SectionHeader({
    required this.icon,
    required this.text,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        PhosphorIcon(icon, size: 14, color: accent),
        const SizedBox(width: 7),
        Text(
          text,
          style: TextStyle(
            color: accent,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: <Color>[
                  accent.withValues(alpha: 0.4),
                  accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chuỗi tiến hoá: ảnh từng chặng (illustration) nối bằng mũi tên; thiếu ảnh →
/// ô số thứ tự. Nhãn dưới là tên chặng đã bỏ emoji.
class _EvolutionChain extends StatelessWidget {
  final List<Stage> stages;
  final Color accent;

  const _EvolutionChain({required this.stages, required this.accent});

  @override
  Widget build(BuildContext context) {
    final row = <Widget>[];
    for (var i = 0; i < stages.length; i++) {
      if (i > 0) {
        row.add(
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: PhosphorIcon(
              PhosphorIconsBold.caretRight,
              size: 13,
              color: accent.withValues(alpha: 0.7),
            ),
          ),
        );
      }
      row.add(
        Expanded(child: _EvoStep(stage: stages[i], index: i, accent: accent)),
      );
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: row);
  }
}

class _EvoStep extends StatelessWidget {
  final Stage stage;
  final int index;
  final Color accent;

  const _EvoStep({
    required this.stage,
    required this.index,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final illustration = stage.illustration;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
              width: 2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: WonderColors.sunnyDeep.withValues(alpha: 0.25),
                blurRadius: 6,
                spreadRadius: -3,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: (illustration != null && illustration.isNotEmpty)
              ? Image.asset(
                  illustration,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => _numTile(),
                )
              : _numTile(),
        ),
        const SizedBox(height: 4),
        Text(
          _plain(stage.title),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: WonderColors.textSoft,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _numTile() => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          accent,
          Color.alphaBlend(Colors.black.withValues(alpha: 0.25), accent),
        ],
      ),
    ),
    child: Center(
      child: Text(
        '${index + 1}',
        style: const TextStyle(
          fontFamily: 'Baloo 2',
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

/// Hộp "Lịch sử" — dòng chú giải nghiêng, viền trái theo màu hệ.
class _HistoryFlavor extends StatelessWidget {
  final String text;
  final Color accent;

  const _HistoryFlavor({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            accent.withValues(alpha: 0.08),
            const Color(0xFFFFFDF6),
          ),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 3, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 12, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          PhosphorIcon(
                            PhosphorIconsBold.books,
                            size: 12,
                            color: accent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'LỊCH SỬ',
                            style: TextStyle(
                              color: accent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF3A4A63),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          height: 1.42,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chân thẻ: logo thật + thương hiệu (trái) · nguồn nội dung (phải).
class _PokeFooter extends StatelessWidget {
  final String source;
  final Color accent;

  const _PokeFooter({required this.source, required this.accent});

  @override
  Widget build(BuildContext context) {
    final live = source == 'live';
    return Row(
      children: <Widget>[
        Image.asset(
          'assets/images/brand_logo.png',
          width: 26,
          height: 26,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: WonderGradients.cta,
            ),
            child: const PhosphorIcon(
              PhosphorIconsDuotone.binoculars,
              size: 15,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'WonderLens',
                style: TextStyle(
                  fontFamily: 'Baloo 2',
                  color: WonderColors.textStrong,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Khoa học vui cho bé tò mò',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: WonderColors.textSoft,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PhosphorIcon(
              live ? PhosphorIconsFill.sparkle : PhosphorIconsFill.sealCheck,
              size: 12,
              color: accent,
            ),
            const SizedBox(width: 5),
            Text(
              live ? 'AI kể chuyện' : 'Curated',
              style: const TextStyle(
                color: WonderColors.textSoft,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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

