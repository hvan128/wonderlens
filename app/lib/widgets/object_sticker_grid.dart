import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/ui.dart';
import 'object_avatar.dart';

/// Một vật để bày dạng sticker (id để mở lại, tên + emoji để hiển thị).
class StickerItem {
  final String id;
  final String name;
  final String emoji;

  const StickerItem({required this.id, required this.name, required this.emoji});
}

/// Lưới vật bày **freestyle**: chia cột nhưng jitter vị trí + xoay nhẹ (tất định
/// theo index) → cảm giác dán sticker. Mỗi vật = ảnh cutout viền trắng
/// ([ObjectAvatar] sticker) + **tên die-cut** (chữ navy viền trắng theo nét).
/// Mỗi ô bọc [RepaintBoundary] để cuộn/kéo mượt.
class ObjectStickerGrid extends StatelessWidget {
  final List<StickerItem> items;
  final void Function(String id) onTap;
  final int columns;
  final double cellHeight;
  final double sticker;

  const ObjectStickerGrid({
    super.key,
    required this.items,
    required this.onTap,
    this.columns = 2,
    this.cellHeight = 188,
    this.sticker = 106,
  });

  double _rand(int i, double salt) {
    final v = math.sin((i + 1) * salt) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / columns;
        final rows = (items.length / columns).ceil();
        return SizedBox(
          height: rows * cellHeight + 12,
          child: Stack(
            children: <Widget>[
              for (var i = 0; i < items.length; i++) _placed(i, cellW),
            ],
          ),
        );
      },
    );
  }

  Widget _placed(int i, double cellW) {
    final col = i % columns;
    final row = i ~/ columns;
    final jx = (_rand(i, 12.9898) * 2 - 1) * cellW * 0.06;
    final jy = (_rand(i, 78.233) * 2 - 1) * cellHeight * 0.05;
    final angle = (_rand(i, 3.14159) * 2 - 1) * 0.13; // ±~7.5°
    final item = items[i];

    return Positioned(
      left: col * cellW + jx,
      top: row * cellHeight + jy,
      width: cellW,
      height: cellHeight,
      child: RepaintBoundary(
        child: Pressable(
          onTap: () => onTap(item.id),
          semanticLabel: 'Mở lại hành trình ${item.name}',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Transform.rotate(
                angle: angle,
                child: ObjectAvatar(
                  objectId: item.id,
                  emoji: item.emoji,
                  diameter: sticker,
                  emojiSize: sticker * 0.5,
                  glowOpacity: 0.16,
                  sticker: true,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: _NameTag(item.name, maxWidth: cellW - 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tên die-cut theo nét chữ: 2 lớp Text chồng khít — stroke trắng mập (join
/// tròn) + fill navy. Không hộp bo góc.
class _NameTag extends StatelessWidget {
  final String name;
  final double maxWidth;

  const _NameTag(this.name, {required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final base = WonderType.heading.copyWith(
      fontSize: 15.5,
      height: 1.05,
      letterSpacing: 0.2,
    );
    Widget layer(TextStyle style) => Text(
      name,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          layer(
            base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 7
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..color = Colors.white,
              shadows: <Shadow>[
                Shadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          layer(base.copyWith(color: WonderColors.textStrong)),
        ],
      ),
    );
  }
}
