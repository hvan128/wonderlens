import 'package:flutter/material.dart';

import '../models/object_content.dart';
import '../theme/wonder_palette.dart';

/// Khung thẻ chia sẻ chung: nền tối kiểu liquid-glass + thương hiệu WonderLens ở
/// đỉnh + dòng tagline ở chân. Dùng chung cho thẻ khám phá lẫn thẻ bộ sưu tập để
/// giữ phong cách nhất quán. Bề rộng cố định → chụp PNG luôn gọn, đọc rõ.
const double kShareCardWidth = 340;

class _WonderCardShell extends StatelessWidget {
  final List<Widget> children;
  const _WonderCardShell({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kShareCardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF2A2150), Wonder.ink],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Wonder.teal.withValues(alpha: 0.30),
            blurRadius: 32,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _Brand(),
            const SizedBox(height: 18),
            ...children,
            const SizedBox(height: 22),
            Center(
              child: Text(
                'Quét đồ vật • Nghe kể chuyện • Sưu tầm huy hiệu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ chia sẻ một lần khám phá: emoji to + tên vật + tóm tắt các chặng hành trình.
class ShareCard extends StatelessWidget {
  final ObjectContent content;

  /// Số chặng tối đa in lên thẻ (giữ chiều cao hợp lý nếu hành trình dài).
  static const int _maxStages = 6;

  /// Bề rộng logic cố định của thẻ.
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
        Center(
          child: Text(content.emoji, style: const TextStyle(fontSize: 76)),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            content.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
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
                _Pill(text: '🏅 ${content.materialBadge}', color: Wonder.teal),
              if (content.source == 'live')
                const _Pill(text: '✨ Khám phá vui (AI)', color: Wonder.sunny),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _Divider(),
        const SizedBox(height: 16),
        const _Label('🗺️  HÀNH TRÌNH TẠO RA'),
        const SizedBox(height: 12),
        for (var i = 0; i < shown.length; i++)
          _StageRow(index: i, title: shown[i].title),
        if (hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 2),
            child: Text(
              '… và $hiddenCount chặng nữa',
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

/// Thẻ chia sẻ thành tích bộ sưu tập: cấp độ + tiến độ + huy hiệu + đồ vật đã sưu tầm.
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
          child: Text(complete ? '🏆' : '🔬', style: const TextStyle(fontSize: 72)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            levelTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Đã khám phá $discoveredCount/$totalCount đồ vật',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ProgressBar(value: value),
        const SizedBox(height: 20),
        const _Divider(),
        const SizedBox(height: 16),
        if (earnedMaterials.isNotEmpty) ...<Widget>[
          const _Label('🏅  HUY HIỆU VẬT LIỆU'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final m in earnedMaterials)
                _Pill(text: '🏅 $m', color: Wonder.teal),
            ],
          ),
          const SizedBox(height: 18),
        ],
        const _Label('🔍  ĐỒ VẬT ĐÃ SƯU TẦM'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final e in discoveredEmojis)
              Text(e, style: const TextStyle(fontSize: 30)),
            for (var i = 0; i < lockedCount; i++)
              Opacity(
                opacity: 0.3,
                child: Text('❓', style: const TextStyle(fontSize: 30)),
              ),
          ],
        ),
      ],
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
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: Wonder.cta,
          ),
          child: const Text('🔭', style: TextStyle(fontSize: 18)),
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
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Khám phá khoa học cho bé',
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Wonder.mint,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
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

class _ProgressBar extends StatelessWidget {
  final double value; // 0..1
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 12,
        color: Colors.white.withValues(alpha: 0.14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: const BoxDecoration(gradient: Wonder.cta),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
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
              gradient: Wonder.cta,
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
