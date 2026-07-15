import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../ui/ui.dart';
import 'object_avatar.dart';

/// Size chung cho object cutout trong các ô sticker nhỏ như Nhật kí và Rương.
const double kObjectStickerDisplayDiameter = 112;
const double kObjectStickerLargeDiameter = 132;

/// Size của sticker preview trong thẻ nhật kí ở Home. Hero thu từ màn nhật kí
/// về thẻ phải kết thúc đúng ở size này để không snap resize ở frame cuối.
const double kHomePreviewStickerDiameter = 82;
const double kHomePreviewStickerCardWidth = 94;
const double kHomePreviewStickerCardHeight = 116;
const double kHomePreviewStickerCardRadius = 18;

const List<Color> kHomePreviewStickerCardTints = <Color>[
  Color(0xFFCFC3AE),
  Color(0xFFD98A45),
  Color(0xFFE0AE5B),
  Color(0xFFD8503A),
  Color(0xFFDCC9A8),
];

Color homePreviewStickerCardTint(int index) =>
    kHomePreviewStickerCardTints[index % kHomePreviewStickerCardTints.length];

double objectStickerVisualScale(String objectId) => switch (objectId) {
  'ball_pen' => 2.70,
  'battery_aa' => 3.00,
  'paper_a4' => 1.88,
  'paper_clip' => 2.53,
  'pencil' => 2.10,
  'plastic_bottle' => 1.54,
  'sticky_note' => 3.00,
  _ => 1,
};

double objectHomePreviewVisualScale(String objectId) => switch (objectId) {
  'paper_cup' => 0.76,
  'ball_pen' => 1.80,
  'battery_aa' => 2.00,
  'paper_a4' => 1.25,
  'paper_clip' => 1.68,
  'pencil' => 1.40,
  'plastic_bottle' => 1.02,
  'sticky_note' => 2.00,
  _ => 1,
};

/// Tiến trình 0 = preview Home, 1 = sticker lớn trong màn nhật kí.
double objectHomeFlightDiameter(double detailDiameter, double progress) {
  final t = progress.clamp(0.0, 1.0).toDouble();
  return lerpDouble(kHomePreviewStickerDiameter, detailDiameter, t)!;
}

/// Tiến trình 0 = preview Home, 1 = sticker lớn trong màn nhật kí.
double objectHomeFlightVisualScale(String objectId, double progress) {
  final t = progress.clamp(0.0, 1.0).toDouble();
  return lerpDouble(
    objectHomePreviewVisualScale(objectId),
    objectStickerVisualScale(objectId),
    t,
  )!;
}

Offset objectStickerVisualOffset(String objectId) => switch (objectId) {
  'ball_pen' => const Offset(-0.012, -0.196),
  'battery_aa' => const Offset(-0.007, -0.177),
  'paper_a4' => const Offset(0.021, -0.030),
  'paper_clip' => const Offset(0.002, -0.057),
  'pencil' => const Offset(-0.010, -0.144),
  'plastic_bottle' => const Offset(0.001, -0.042),
  'sticky_note' => const Offset(-0.002, -0.003),
  _ => Offset.zero,
};

/// Một vật để bày dạng sticker (id để mở lại, tên + emoji để hiển thị).
class StickerItem {
  final String id;
  final String name;
  final String emoji;

  const StickerItem({
    required this.id,
    required this.name,
    required this.emoji,
  });
}

/// Góc nghiêng sticker theo vị trí — xoay vòng bộ góc mẫu chung [WonderTilt]
/// để mọi thẻ trong app nghiêng cùng một "chữ ký". Tất định theo index nên góc
/// khớp nhau khi Hero bay (không giật góc).
double stickerTilt(int index) => WonderTilt.at(index);

/// Đường bay Hero **thẳng** (thay cung mặc định) → chuyển động trực tiếp, êm.
RectTween stickerLinearRectTween(Rect? begin, Rect? end) =>
    RectTween(begin: begin, end: end);

/// Độ hiện của tem trong lúc Hero bay. Tem đầy (1) khi ĐANG TỚI ô có tem này;
/// mờ + co nhanh ở nhịp ĐẦU khi ĐANG RỜI đi về phía "đầu kia" chỉ có cutout
/// (thẻ ngày / cover timeline) → không giật kích thước lúc bàn giao.
///
/// [isOpener] = true: ô là NƠI BẤM để mở (Rương) → rời đi lúc push (→ màn mới),
/// tới lúc pop (quay về). false: ô là NỘI DUNG màn được mở (nhật ký) → tới lúc
/// push, rời đi lúc pop.
double stickerLabelFactor(
  HeroFlightDirection direction,
  double v,
  bool isOpener,
) {
  if (isOpener) {
    // Đầu kia (cover timeline) là cutout VUÔNG trần → tem chỉ tồn tại khi ở
    // GẦN phía Rương (v nhỏ), cả đi lẫn về. Nếu giữ tem suốt chuyến, FittedBox
    // ép cụm cao vào khung vuông → vật chỉ còn nửa trên, nhìn như bị cắt.
    return ((0.18 - v) / 0.18).clamp(0.0, 1.0);
  }
  // Nhật ký ngày: đang TỚI lưới (push) → tem đầy ngay từ đầu (yêu cầu UX);
  // đang RỜI về thẻ (pop) → tem tắt nhanh ở nhịp đầu.
  if (direction == HeroFlightDirection.push) return 1.0;
  return ((v - 0.82) / 0.18).clamp(0.0, 1.0); // pop rời: 1 ở v=1 → 0 ở v=0.82
}

/// Tem tên vật kiểu die-cut: **nền trắng ôm theo viền chữ** (vẽ chữ bằng nét
/// trắng dày phía sau) + chữ đậm màu tối phía trên + bóng đổ mềm → như miếng dán.
class StickerLabel extends StatelessWidget {
  final String text;

  const StickerLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final base = WonderType.display.copyWith(
      fontSize: 25,
      fontWeight: FontWeight.w800,
      height: 1.08,
    );
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Text(
          text,
          textAlign: TextAlign.center,
          style: base.copyWith(
            shadows: const <Shadow>[
              Shadow(
                color: Color(0x2E000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 15
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round
              ..color = Colors.white,
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: base.copyWith(color: WonderColors.textStrong),
        ),
      ],
    );
  }
}

class HomeKraftStickerCard extends StatelessWidget {
  final Color tint;
  final double shadowOpacity;

  const HomeKraftStickerCard({
    super.key,
    required this.tint,
    this.shadowOpacity = 0.16,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kHomePreviewStickerCardRadius),
        boxShadow: <BoxShadow>[
          if (shadowOpacity > 0)
            BoxShadow(
              color: WonderColors.textStrong.withValues(alpha: shadowOpacity),
              blurRadius: 16,
              offset: const Offset(0, 9),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kHomePreviewStickerCardRadius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              'assets/images/kraft_paper.png',
              fit: BoxFit.cover,
              color: tint,
              colorBlendMode: BlendMode.multiply,
              errorBuilder: (context, error, stack) => ColoredBox(color: tint),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0x22FFFFFF),
                    Color(0x00FFFFFF),
                    Color(0x1A000000),
                  ],
                  stops: <double>[0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeStickerPreviewTile extends StatelessWidget {
  final StickerItem item;
  final int index;
  final double tilt;
  final bool avatarShadow;
  final double cardShadowOpacity;

  const HomeStickerPreviewTile({
    super.key,
    required this.item,
    required this.index,
    required this.tilt,
    this.avatarShadow = true,
    this.cardShadowOpacity = 0.16,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kHomePreviewStickerCardWidth,
      height: kHomePreviewStickerCardHeight,
      child: Transform.rotate(
        angle: tilt,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(
              child: HomeKraftStickerCard(
                tint: homePreviewStickerCardTint(index),
                shadowOpacity: cardShadowOpacity,
              ),
            ),
            ObjectAvatar(
              objectId: item.id,
              emoji: item.emoji,
              diameter: kHomePreviewStickerDiameter,
              emojiSize: kHomePreviewStickerDiameter * 0.48,
              glowOpacity: 0.12,
              sticker: true,
              stickerBorderFactor: 0.03,
              stickerVisualScale: objectHomePreviewVisualScale(item.id),
              stickerVisualOffset: objectStickerVisualOffset(item.id),
              stickerShadow: avatarShadow,
            ),
          ],
        ),
      ),
    );
  }
}

/// Nội dung một ô: sticker (nghiêng) + tem tên (width CỐ ĐỊNH để xuống dòng nhất
/// quán, không nhảy dòng khi FittedBox scale lúc bay). [labelFactor] điều khiển
/// độ hiện + CO cả rộng lẫn cao của tem (khi về 0 ô co đúng hình vuông sticker →
/// khớp cutout ở đầu kia, không khựng lúc bàn giao Hero).
class StickerTile extends StatelessWidget {
  final StickerItem item;
  final double diameter;
  final double tilt;
  final double labelWidth;
  final double labelFactor;
  final double? visualScale;
  final Offset? visualOffset;

  /// false khi render trong Hero overlay lúc bay — tắt bóng blur của sticker
  /// (nguồn nháy đen 1 frame trên Impeller + blur lại mỗi frame tốn GPU).
  final bool shadow;

  const StickerTile({
    super.key,
    required this.item,
    this.diameter = 132,
    this.tilt = 0,
    this.labelWidth = 150,
    this.labelFactor = 1,
    this.visualScale,
    this.visualOffset,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Transform.rotate(
          angle: tilt,
          child: ObjectAvatar(
            objectId: item.id,
            emoji: item.emoji,
            diameter: diameter,
            emojiSize: diameter * 0.48,
            glowOpacity: 0.16,
            sticker: true,
            stickerVisualScale:
                visualScale ?? objectStickerVisualScale(item.id),
            stickerVisualOffset:
                visualOffset ?? objectStickerVisualOffset(item.id),
            stickerShadow: shadow,
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          heightFactor: labelFactor,
          widthFactor: labelFactor,
          child: Opacity(
            opacity: labelFactor,
            child: Transform.translate(
              offset: const Offset(0, -12),
              child: SizedBox(
                width: labelWidth,
                child: StickerLabel(item.name),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Vật phẩm + tem có **hiệu ứng morph** (Hero): chạm → sticker (kèm tem) bay sang
/// đích cùng [heroTag] (màn chi tiết / lịch sử), thoát → bay ngược về. Lúc bay:
/// render ở kích thước tự nhiên rồi SCALE đều bằng FittedBox → chữ layout một lần
/// (không nhảy dòng/méo), tem mờ+co đúng lúc để khớp cutout ở đầu kia.
class ObjectSticker extends StatelessWidget {
  final StickerItem item;
  final String heroTag;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double diameter;
  final double tilt;
  final double labelWidth;
  final bool isOpener;

  /// Góc nghiêng ở ĐẦU KIA của chuyến bay — phía route ĐƯỢC PUSH (animation
  /// value = 1). Shuttle lerp góc [tilt] → [flightEndTilt] theo tiến trình →
  /// không snap góc lúc bàn giao. Mặc định = [tilt] (hai đầu cùng góc, vd thẻ
  /// ngày ↔ màn chi tiết). Rương → cover timeline (thẳng đứng): truyền 0.
  final double? flightEndTilt;

  /// true (mặc định): tem nằm TRONG Hero, bay cùng sticker — dùng khi đầu kia
  /// cũng là tile cùng tỉ lệ (thẻ ngày ↔ màn chi tiết ngày).
  /// false: tem đứng lại trong route, Hero CHỈ chứa sticker VUÔNG — dùng khi đầu
  /// kia là cutout vuông trần (Rương ↔ cover timeline): chuyến bay vuông↔vuông
  /// không đổi tỉ lệ nên vật không bao giờ bị tem ép co/che ("cắt mất nửa").
  final bool labelInHero;
  final int? homePreviewIndex;

  const ObjectSticker({
    super.key,
    required this.item,
    required this.heroTag,
    required this.onTap,
    this.onLongPress,
    this.diameter = kObjectStickerLargeDiameter,
    this.tilt = 0,
    this.labelWidth = 150,
    this.isOpener = false,
    this.flightEndTilt,
    this.labelInHero = true,
    this.homePreviewIndex,
  });

  Widget _avatar({
    required bool shadow,
    double? tiltOverride,
    double? diameterOverride,
    double? visualScaleOverride,
    Offset? visualOffsetOverride,
  }) {
    final d = diameterOverride ?? diameter;
    return Transform.rotate(
      angle: tiltOverride ?? tilt,
      child: ObjectAvatar(
        objectId: item.id,
        emoji: item.emoji,
        diameter: d,
        emojiSize: d * 0.48,
        glowOpacity: 0.16,
        sticker: true,
        stickerVisualScale:
            visualScaleOverride ?? objectStickerVisualScale(item.id),
        stickerVisualOffset:
            visualOffsetOverride ?? objectStickerVisualOffset(item.id),
        stickerShadow: shadow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hero = Hero(
      tag: heroTag,
      createRectTween: stickerLinearRectTween,
      flightShuttleBuilder: objectStickerFlightShuttleBuilder(
        item: item,
        diameter: diameter,
        tilt: tilt,
        labelWidth: labelWidth,
        isOpener: isOpener,
        flightEndTilt: flightEndTilt,
        labelInHero: labelInHero,
        homePreviewIndex: homePreviewIndex,
      ),
      child: labelInHero
          ? StickerTile(
              item: item,
              diameter: diameter,
              tilt: tilt,
              labelWidth: labelWidth,
            )
          : _avatar(shadow: true),
    );

    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      haptic: false,
      semanticLabel: 'Mở lại hành trình ${item.name}',
      child: labelInHero
          ? hero
          // Tem NGOÀI Hero: đứng lại trong route khi sticker bay (mờ theo
          // transition của route), chờ sẵn khi sticker đáp về.
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                hero,
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: SizedBox(
                    width: labelWidth,
                    child: StickerLabel(item.name),
                  ),
                ),
              ],
            ),
    );
  }
}

HeroFlightShuttleBuilder objectStickerFlightShuttleBuilder({
  required StickerItem item,
  double diameter = kObjectStickerLargeDiameter,
  double tilt = 0,
  double labelWidth = 150,
  bool isOpener = false,
  double? flightEndTilt,
  bool labelInHero = true,
  int? homePreviewIndex,
}) {
  return (flightContext, animation, direction, fromContext, toContext) {
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          // animation.value: 0 = phía route dưới, 1 = phía route được push
          // (cả push lẫn pop) → lerp góc là khớp cả hai chiều.
          final progress = animation.value;
          final previewIndex = homePreviewIndex;
          final homePreview = !isOpener && previewIndex != null;
          final endTilt = flightEndTilt ?? tilt;
          final t = lerpDouble(tilt, endTilt, progress)!;
          final flightDiameter = homePreview
              ? objectHomeFlightDiameter(diameter, progress)
              : diameter;
          final flightVisualScale = homePreview
              ? objectHomeFlightVisualScale(item.id, progress)
              : objectStickerVisualScale(item.id);
          final flightVisualOffset = objectStickerVisualOffset(item.id);
          final labelFactor = stickerLabelFactor(direction, progress, isOpener);

          final detailFlight = FittedBox(
            fit: BoxFit.contain,
            // shadow=false khi bay: blur trong overlay dễ nháy đen (Impeller)
            // và blur lại mỗi frame tốn GPU.
            child: labelInHero
                ? StickerTile(
                    item: item,
                    diameter: flightDiameter,
                    tilt: t,
                    labelWidth: labelWidth,
                    labelFactor: labelFactor,
                    visualScale: flightVisualScale,
                    visualOffset: flightVisualOffset,
                    shadow: false,
                  )
                : Transform.rotate(
                    angle: t,
                    child: ObjectAvatar(
                      objectId: item.id,
                      emoji: item.emoji,
                      diameter: flightDiameter,
                      emojiSize: flightDiameter * 0.48,
                      glowOpacity: 0.16,
                      sticker: true,
                      stickerVisualScale: flightVisualScale,
                      stickerVisualOffset: flightVisualOffset,
                      stickerShadow: false,
                    ),
                  ),
          );

          if (!homePreview) return detailFlight;

          final homeFactor = ((0.20 - progress) / 0.20)
              .clamp(0.0, 1.0)
              .toDouble();
          if (homeFactor <= 0) return detailFlight;

          final homeTile = HomeStickerPreviewTile(
            item: item,
            index: previewIndex,
            tilt: stickerTilt(previewIndex),
            avatarShadow: true,
            cardShadowOpacity: 0.16,
          );

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              Opacity(opacity: homeFactor, child: homeTile),
              Opacity(opacity: 1 - homeFactor, child: detailFlight),
            ],
          );
        },
      ),
    );
  };
}

/// Lưới sticker **hai cột so le** (cột phải hạ xuống một nhịp) cho cảm giác dán
/// tay. Mỗi ô là [ObjectSticker] có morph Hero. Caller cấp [heroTag] + [isOpener]
/// theo màn (nhật ký ngày ↔ thẻ; Rương ↔ lịch sử). Đặt trong một scroll view.
class StickerStaggeredGrid extends StatelessWidget {
  final List<StickerItem> items;
  final void Function(String id) onTap;
  final void Function(String id)? onLongPress;
  final String Function(String id) heroTag;
  final bool isOpener;
  final double diameter;

  /// Xem [ObjectSticker.flightEndTilt] — góc ở đầu kia của chuyến bay Hero.
  final double? flightEndTilt;

  /// Xem [ObjectSticker.labelInHero] — tem bay cùng sticker hay đứng lại route.
  final bool labelInHero;

  const StickerStaggeredGrid({
    super.key,
    required this.items,
    required this.onTap,
    this.onLongPress,
    required this.heroTag,
    this.isOpener = false,
    this.diameter = 132,
    this.flightEndTilt,
    this.labelInHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final tile = Padding(
        padding: const EdgeInsets.only(bottom: 34),
        child: ObjectSticker(
          item: item,
          diameter: diameter,
          tilt: stickerTilt(i),
          heroTag: heroTag(item.id),
          isOpener: isOpener,
          flightEndTilt: flightEndTilt,
          labelInHero: labelInHero,
          homePreviewIndex: isOpener ? null : i,
          onTap: () => onTap(item.id),
          onLongPress: onLongPress == null ? null : () => onLongPress!(item.id),
        ),
      );
      (i.isEven ? left : right).add(tile);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: left),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[const SizedBox(height: 46), ...right],
          ),
        ),
      ],
    );
  }
}

/// Tag Hero để một vật **bay** giữa Rương và màn lịch sử (cover timeline). Riêng
/// biệt với tag ở thẻ ngày (`day-obj-…`) để không đụng nhau.
String collectionObjectHeroTag(String objectId) => 'collection-obj-$objectId';

/// Lưới vật trong **Rương**: sticker + tem (style màn nhật ký), 2 cột so le, chạm
/// → morph bay sang màn lịch sử ([collectionObjectHeroTag] khớp cover timeline).
class ObjectStickerGrid extends StatelessWidget {
  final List<StickerItem> items;
  final void Function(String id) onTap;
  final void Function(String id)? onLongPress;

  const ObjectStickerGrid({
    super.key,
    required this.items,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return StickerStaggeredGrid(
      items: items,
      onTap: onTap,
      onLongPress: onLongPress,
      heroTag: collectionObjectHeroTag,
      isOpener: true,
      // Cover timeline đứng THẲNG → lerp góc nghiêng về 0 lúc bay, không snap.
      flightEndTilt: 0,
      // Đầu kia là cutout vuông trần → tem đứng lại, chỉ sticker vuông bay
      // (vuông↔vuông, không đổi tỉ lệ → vật không bị ép co/che lúc bay).
      labelInHero: false,
      diameter: kObjectStickerDisplayDiameter,
    );
  }
}
