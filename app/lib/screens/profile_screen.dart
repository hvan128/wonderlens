import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/app_settings.dart';
import '../data/collection_repository.dart';
import '../data/content_repository.dart';
import '../data/hero_catalog.dart';
import '../data/subscription_repository.dart';
import '../services/mission_notification_service.dart';
import '../ui/ui.dart';
import '../widgets/dev_panel.dart';
import '../widgets/legal_links.dart';
import '../widgets/object_avatar.dart';
import '../widgets/share_sheet.dart';

/// Tab Hồ sơ — bố cục theo ảnh mẫu: cụm 5 thẻ giấy thô nghiêng ([WonderTilt])
/// bày vật bé đã soi nổi THẲNG trên nền chấm (không khung, không ảnh nền),
/// dưới là cấp độ (chữ lớn giữa màn) + số món + nút "Khoe thành tích" + huy
/// hiệu chất liệu. Chạm thẻ có vật → mở lại hành trình vật đó. Nhấn giữ dòng
/// phiên bản = Dev panel (ẩn).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CollectionRepository();
    final discovered = repo.discoveredIds().toSet();
    final journal = repo.journalEntries();
    final badges = repo.badges();
    final total = discovered.length + journal.length;
    final heroCount = discovered.length;
    final earnedMaterials = [
      for (final m in allMaterials)
        if (badges.contains(m)) m,
    ];
    final discoveredEmojis = [
      for (final h in heroCatalog)
        if (discovered.contains(h.id)) h.emoji,
    ];
    // Vật bày trên cụm thẻ (hero đã soi trước, rồi tới AI-live), tối đa 5 slot.
    final showcase = <({String id, String name, String emoji})>[
      for (final h in heroCatalog)
        if (discovered.contains(h.id)) (id: h.id, name: h.name, emoji: h.emoji),
      for (final e in journal) (id: e.id, name: e.name, emoji: e.emoji),
    ].take(5).toList();

    // Mở lại hành trình một vật trên thẻ (nội dung offline, như Rương).
    Future<void> openItem(String id) async {
      if (heroById(id) != null) {
        final content = await ContentRepository().load(id);
        if (!context.mounted || content == null) return;
        await context.push('/timeline', extra: content);
        return;
      }
      await context.push(
        '/timeline',
        extra: journal.firstWhere((e) => e.id == id).toContent(),
      );
    }

    void share() => showCollectionShareSheet(
      context,
      levelTitle: levelTitle(heroCount),
      discoveredCount: heroCount,
      totalCount: heroCatalog.length,
      earnedMaterials: earnedMaterials,
      discoveredEmojis: discoveredEmojis,
    );

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
          const _ProfileHeader(),
          const SizedBox(height: 14),
          const _SettingsSection(),
          const SizedBox(height: 30),
          Text(
            'Thành tích khám phá',
            style: WonderType.title.copyWith(
              color: WonderColors.textStrong,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Những món bé đã soi sẽ nằm lại ở đây.',
            style: WonderType.caption.copyWith(color: WonderColors.textSoft),
          ),
          const SizedBox(height: 16),
          _ShowcaseCluster(items: showcase, onOpen: openItem),
          const SizedBox(height: 30),
          Text(
            levelTitle(heroCount),
            textAlign: TextAlign.center,
            style: WonderType.display.copyWith(
              color: WonderColors.textStrong,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'Chưa soi món nào - bắt đầu nào!'
                : 'Đã soi $total món đồ',
            textAlign: TextAlign.center,
            style: WonderType.body.copyWith(
              color: WonderColors.textSoft,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            label: total == 0 ? 'Soi món đầu tiên' : 'Khoe thành tích',
            icon: total == 0
                ? PhosphorIconsBold.camera
                : PhosphorIconsBold.shareNetwork,
            onTap: total == 0 ? () => context.push('/camera') : share,
          ),
          const SizedBox(height: 24),
          _MaterialBadgeShelf(badges: badges),
          const SizedBox(height: 24),
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
          const SizedBox(height: 10),
          const LegalLinks(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Cài đặt',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: WonderType.title.copyWith(color: WonderColors.textSoft),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  Future<void> _setReminderEnabled(BuildContext context, bool value) async {
    WonderHaptics.selection();
    final ok = await MissionNotificationService.instance.setRemindersEnabled(
      value,
    );
    if (!context.mounted) return;
    if (!ok && value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa bật được thông báo. Phụ huynh có thể thử lại sau.',
          ),
        ),
      );
    }
  }

  Future<void> _scheduleTestReminder(BuildContext context) async {
    WonderHaptics.warning();
    final ok = await MissionNotificationService.instance
        .scheduleDebugTestReminder();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã đặt nhắc thử sau 10 giây.'
              : 'Chưa bật được thông báo. Phụ huynh có thể thử lại sau.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.missionRemindersEnabled,
      builder: (context, remindersEnabled, _) {
        return ValueListenableBuilder<SubscriptionState>(
          valueListenable: SubscriptionRepository.state,
          builder: (context, plusState, _) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(WonderTokens.radiusLg),
                border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: WonderColors.textStrong.withValues(alpha: 0.07),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(WonderTokens.radiusLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _SettingsTile(
                      icon: remindersEnabled
                          ? PhosphorIconsFill.notification
                          : PhosphorIconsBold.notification,
                      title: 'Nhắc khám phá',
                      semanticLabel: remindersEnabled
                          ? 'Tắt nhắc khám phá'
                          : 'Bật nhắc khám phá',
                      onTap: () =>
                          _setReminderEnabled(context, !remindersEnabled),
                      onLongPress: () => _scheduleTestReminder(context),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            remindersEnabled ? 'Bật' : 'Tắt',
                            style: WonderType.label.copyWith(
                              color: remindersEnabled
                                  ? WonderColors.tealDeep
                                  : WonderColors.textSoft.withValues(
                                      alpha: 0.58,
                                    ),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Transform.scale(
                            scale: 0.78,
                            child: Switch.adaptive(
                              value: remindersEnabled,
                              activeThumbColor: Colors.white,
                              activeTrackColor: WonderColors.sunny,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: WonderColors.textSoft
                                  .withValues(alpha: 0.20),
                              onChanged: (value) =>
                                  _setReminderEnabled(context, value),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: plusState.isPremium
                          ? PhosphorIconsFill.checkCircle
                          : PhosphorIconsFill.sparkle,
                      title: 'WonderLens Plus',
                      semanticLabel: 'Mở WonderLens Plus',
                      onTap: () => context.push('/subscription'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _plusStatus(plusState),
                            style: WonderType.label.copyWith(
                              color: plusState.isPremium
                                  ? WonderColors.sunnyDeep
                                  : WonderColors.textSoft.withValues(
                                      alpha: 0.58,
                                    ),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          PhosphorIcon(
                            PhosphorIconsBold.caretRight,
                            color: WonderColors.textSoft.withValues(
                              alpha: 0.42,
                            ),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _plusStatus(SubscriptionState state) {
    if (!state.isPremium) return 'Chưa bật';
    return state.source == 'store' ? 'Store' : 'Đang bật';
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String semanticLabel;
  final Widget trailing;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.semanticLabel,
    required this.trailing,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: WonderColors.sunny.withValues(alpha: 0.10),
        highlightColor: WonderColors.sunny.withValues(alpha: 0.06),
        child: Semantics(
          button: true,
          label: semanticLabel,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 14, 6),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 30,
                    height: 40,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: PhosphorIcon(
                        icon,
                        color: WonderColors.textStrong,
                        size: 23,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WonderType.heading.copyWith(
                        color: WonderColors.textStrong,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 54, right: 18),
      child: Divider(
        height: 1,
        thickness: 1,
        color: WonderColors.textSoft.withValues(alpha: 0.10),
      ),
    );
  }
}

class _MaterialBadgeShelf extends StatelessWidget {
  final Set<String> badges;

  const _MaterialBadgeShelf({required this.badges});

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    Widget shelf = GlassSurface(
      tone: GlassTone.light,
      blur: 8,
      tintOpacity: 0.42,
      radius: WonderTokens.radiusXl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      shadows: <BoxShadow>[
        BoxShadow(
          color: WonderColors.tealDeep.withValues(alpha: 0.09),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Huy hiệu siêu chất liệu',
                  style: WonderType.heading.copyWith(
                    color: WonderColors.textStrong,
                  ),
                ),
              ),
              Text(
                '${badges.length}/${allMaterials.length}',
                style: WonderType.label.copyWith(color: WonderColors.textSoft),
              ),
            ],
          ),
          const SizedBox(height: WonderTokens.space12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final m in allMaterials)
                Expanded(
                  child: _MaterialMedallion(
                    material: m,
                    earned: badges.contains(m),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (!reduce) {
      shelf = shelf
          .animate(delay: 160.ms)
          .fadeIn(duration: WonderTokens.durBase)
          .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
    }
    return shelf;
  }
}

/// Cụm 5 thẻ giấy thô nghiêng bày vật — bố cục ĐO từ ảnh mẫu (3 thẻ trên,
/// 2 thẻ dưới), góc nghiêng lấy từ bộ chung [WonderTilt] (cùng thứ tự slot).
/// Thẻ nổi thẳng trên nền chấm, không khung. Slot chưa có vật = thẻ trống với
/// đĩa trắng mờ "chỗ chờ dán" — không bịa vật; đủ vật thì chạm thẻ mở lại
/// hành trình.
class _ShowcaseCluster extends StatelessWidget {
  final List<({String id, String name, String emoji})> items;
  final Future<void> Function(String id) onOpen;

  const _ShowcaseCluster({required this.items, required this.onOpen});

  /// Mỗi slot: [cx, cy (chuẩn hoá), scale]. Card xoay quanh tâm nên vật ở tâm
  /// luôn hở.
  static const List<List<double>> _slots = <List<double>>[
    <double>[0.23, 0.33, 1.00],
    <double>[0.50, 0.30, 1.03],
    <double>[0.77, 0.34, 0.99],
    <double>[0.38, 0.70, 1.02],
    <double>[0.62, 0.71, 0.98],
  ];

  /// Màu giấy ấm mỗi card (tan · cam · mật · đỏ · be) — theo ảnh mẫu.
  static const List<Color> _tints = <Color>[
    Color(0xFFCFC3AE),
    Color(0xFFD98A45),
    Color(0xFFE0AE5B),
    Color(0xFFD8503A),
    Color(0xFFDCC9A8),
  ];

  /// Thứ tự VẼ (sau đè trước) theo ảnh mẫu: kem → vàng → be → đỏ → CAM —
  /// thẻ cam giữa nằm TRÊN cùng, đỏ đè be; khác hẳn vẽ tuần tự 0..4 (hai thẻ
  /// dưới luôn đè hết hàng trên) vốn làm cụm trông xếp lớp máy móc.
  static const List<int> _paintOrder = <int>[0, 2, 4, 3, 1];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.30,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          return Stack(
            // Clip.none: góc thẻ xoay + bóng đổ tràn nhẹ ra ngoài không bị cắt.
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(painter: _ShowcaseBackdropPainter()),
              ),
              for (final i in _paintOrder) _placedCard(context, i, w, h),
            ],
          );
        },
      ),
    );
  }

  /// Đặt một thẻ vào slot: bề rộng theo scale, xoay quanh tâm theo góc chung.
  Widget _placedCard(BuildContext context, int i, double w, double h) {
    final slot = _slots[i];
    final cardW = w * 0.30 * slot[2];
    final cardH = cardW * 1.30;
    final item = i < items.length ? items[i] : null;
    final card = _KraftCard(
      tint: _tints[i % _tints.length],
      child: item == null
          ? const _EmptyStickerSpot()
          : Center(
              child: LayoutBuilder(
                builder: (context, c) => ObjectAvatar(
                  objectId: item.id,
                  emoji: item.emoji,
                  diameter: c.maxWidth * 0.63,
                  emojiSize: c.maxWidth * 0.44,
                  glowOpacity: 0.12,
                  sticker: true,
                  stickerBorderFactor: 0.03,
                ),
              ),
            ),
    );
    Widget body = Transform.rotate(
      angle: WonderTilt.at(i),
      child: item == null
          ? card
          : Pressable(
              onTap: () => onOpen(item.id),
              haptic: false,
              semanticLabel: 'Mở lại hành trình ${item.name}',
              child: card,
            ),
    );
    if (!reduceMotionOf(context)) {
      body = body
          .animate(delay: (i * 55).ms)
          .fadeIn(duration: WonderTokens.durBase)
          .scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1, 1),
            curve: Curves.easeOutBack,
          );
    }
    return Positioned(
      left: slot[0] * w - cardW / 2,
      top: slot[1] * h - cardH / 2,
      width: cardW,
      height: cardH,
      child: body,
    );
  }
}

/// Thẻ giấy thô nhuộm màu: texture × tint (multiply, thiếu asset → màu đặc) +
/// sheen nhẹ trên–tối dưới. Bóng đổ dịu vì nằm trên nền sáng.
class _KraftCard extends StatelessWidget {
  final Color tint;
  final Widget child;

  const _KraftCard({required this.tint, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: WonderColors.textStrong.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.82),
            blurRadius: 7,
            offset: const Offset(-3, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
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
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.2,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _ShowcaseBackdropPainter extends CustomPainter {
  const _ShowcaseBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glowRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.50),
      width: size.width * 0.92,
      height: size.height * 0.92,
    );
    final glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          WonderColors.sunny.withValues(alpha: 0.18),
          WonderColors.coral.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const <double>[0.0, 0.54, 1.0],
      ).createShader(glowRect);
    canvas.drawOval(glowRect, glow);

    final shadowRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.79),
      width: size.width * 0.58,
      height: size.height * 0.16,
    );
    final shadow = Paint()
      ..color = WonderColors.textStrong.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(shadowRect, shadow);
  }

  @override
  bool shouldRepaint(covariant _ShowcaseBackdropPainter oldDelegate) => false;
}

/// Đĩa trắng mờ "chỗ chờ dán sticker" cho slot chưa có vật.
class _EmptyStickerSpot extends StatelessWidget {
  const _EmptyStickerSpot();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.55,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 2,
                  ),
                ),
              ),
              Center(
                child: PhosphorIcon(
                  PhosphorIconsBold.camera,
                  size: 20,
                  color: WonderColors.textSoft.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Huy hiệu chất liệu dạng medallion: đĩa tròn (đạt = gradient huy hiệu + quầng
/// sáng + icon huân chương; chưa đạt = đĩa mờ + ổ khoá) với tên chất liệu bên
/// dưới — bốn cái xếp một hàng đều nhau, đọc như tủ huy chương thay vì chip.
class _MaterialMedallion extends StatelessWidget {
  final String material;
  final bool earned;

  const _MaterialMedallion({required this.material, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 66,
          height: 66,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: Container(
                  decoration: earned
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: WonderGradients.honey,
                          boxShadow: WonderShadows.glow(
                            WonderColors.sunny,
                            opacity: 0.35,
                          ),
                        )
                      : BoxDecoration(
                          shape: BoxShape.circle,
                          color: WonderColors.textSoft.withValues(alpha: 0.10),
                          border: Border.all(
                            color: WonderColors.textSoft.withValues(
                              alpha: 0.24,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: earned
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.30),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: earned ? 0.58 : 0.38,
                        ),
                      ),
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        earned
                            ? PhosphorIconsFill.medal
                            : PhosphorIconsBold.lockSimple,
                        size: 25,
                        color: earned ? Colors.white : WonderColors.textSoft,
                      ),
                    ),
                  ),
                ),
              ),
              if (earned)
                const Positioned(
                  right: -1,
                  top: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: WonderColors.paper,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: PhosphorIcon(
                        PhosphorIconsFill.checkCircle,
                        size: 17,
                        color: WonderColors.sunnyDeep,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          material,
          textAlign: TextAlign.center,
          style: WonderType.label.copyWith(
            fontSize: 13,
            color: earned ? WonderColors.textStrong : WonderColors.textSoft,
          ),
        ),
      ],
    );
  }
}
