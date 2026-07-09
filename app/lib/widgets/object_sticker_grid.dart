import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../ui/ui.dart';
import 'object_avatar.dart';

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

  const ObjectSticker({
    super.key,
    required this.item,
    required this.heroTag,
    required this.onTap,
    this.onLongPress,
    this.diameter = 132,
    this.tilt = 0,
    this.labelWidth = 150,
    this.isOpener = false,
    this.flightEndTilt,
    this.labelInHero = true,
  });

  Widget _avatar({required bool shadow, double? tiltOverride}) =>
      Transform.rotate(
        angle: tiltOverride ?? tilt,
        child: ObjectAvatar(
          objectId: item.id,
          emoji: item.emoji,
          diameter: diameter,
          emojiSize: diameter * 0.48,
          glowOpacity: 0.16,
          sticker: true,
          stickerShadow: shadow,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final endTilt = flightEndTilt ?? tilt;
    final hero = Hero(
      tag: heroTag,
      createRectTween: stickerLinearRectTween,
      flightShuttleBuilder:
          (flightContext, animation, direction, fromContext, toContext) {
            return Material(
              type: MaterialType.transparency,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  // animation.value: 0 = phía route dưới, 1 = phía route được
                  // push (cả push lẫn pop) → lerp góc là khớp cả hai chiều.
                  final t = lerpDouble(tilt, endTilt, animation.value)!;
                  return FittedBox(
                    fit: BoxFit.contain,
                    // shadow=false khi bay: blur trong overlay dễ nháy đen
                    // (Impeller) và blur lại mỗi frame tốn GPU.
                    child: labelInHero
                        ? StickerTile(
                            item: item,
                            diameter: diameter,
                            tilt: t,
                            labelWidth: labelWidth,
                            labelFactor: stickerLabelFactor(
                              direction,
                              animation.value,
                              isOpener,
                            ),
                            shadow: false,
                          )
                        : _avatar(shadow: false, tiltOverride: t),
                  );
                },
              ),
            );
          },
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
    );
  }
}
