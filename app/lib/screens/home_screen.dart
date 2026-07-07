import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../services/camera_warmup.dart';
import '../ui/ui.dart';
import '../widgets/dev_panel.dart';
import '../widgets/object_avatar.dart';

/// Trang chủ (tab): lời chào + **vòng khẩu độ = nút chụp** ở giữa + khu tháng
/// với các **thẻ theo ngày** (mỗi ngày một màu dịu) kèm thumbnail vật đã soi.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Màu thẻ theo ngày (dịu, xoay vòng theo thứ tự).
  static const List<Color> _cardColors = <Color>[
    Color(0xFFC9AD92), // tan
    Color(0xFFCBA29B), // hồng đất
    Color(0xFFA9B79D), // xanh rêu
    Color(0xFF9FB0C0), // xanh xám
    Color(0xFFBBA6BE), // tím khói
  ];

  @override
  Widget build(BuildContext context) {
    final repo = CollectionRepository();
    final journal = repo.journalEntries();
    final discoveries = repo.discoveredIds().length + journal.length;
    final ringSize = (MediaQuery.sizeOf(context).width * 0.62).clamp(190.0, 260.0);

    // Gom vật theo NGÀY (mới nhất trước).
    final byDay = <String, List<JournalEntry>>{};
    for (final e in journal) {
      final d = e.discoveredAt;
      (byDay['${d.year}.${d.month}.${d.day}'] ??= <JournalEntry>[]).add(e);
    }
    final days = byDay.values.toList();

    void openCamera() => context.push('/camera');
    void prewarm() => CameraWarmup.instance.prewarm();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          22,
          8,
          22,
          WonderTokens.tabBarClearance + 24,
        ),
        children: <Widget>[
          const SizedBox(height: 8),
          _Greeting(
            discoveries: discoveries,
            onSecret: () => showDevPanel(context),
          ),
          const SizedBox(height: 26),
          Center(
            child: ApertureCaptureButton(
              size: ringSize,
              onPressStart: prewarm,
              onCapture: openCamera,
            ),
          ),
          const SizedBox(height: 34),
          if (days.isNotEmpty) ...<Widget>[
            Text(
              'Tháng ${journal.first.discoveredAt.month}',
              style: WonderType.display.copyWith(
                color: WonderColors.textStrong,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < days.length; i++) ...<Widget>[
              _DayCard(
                entries: days[i],
                color: _cardColors[i % _cardColors.length],
                onOpen: (e) =>
                    context.push('/timeline', extra: e.toContent()),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }
}

/// Lời chào theo buổi + số món đã soi. Nhấn giữ ngày = Dev panel (ẩn).
class _Greeting extends StatelessWidget {
  final int discoveries;
  final VoidCallback onSecret;

  const _Greeting({required this.discoveries, required this.onSecret});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: onSecret,
          child: Text(
            '${now.day} tháng ${now.month}',
            style: WonderType.caption.copyWith(
              color: WonderColors.textSoft,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _greeting(now.hour),
          textAlign: TextAlign.center,
          style: WonderType.display.copyWith(
            color: WonderColors.textStrong,
            fontSize: 34,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          discoveries == 0
              ? 'Chạm vòng tròn để soi đồ vật'
              : 'Tuyệt vời! Bé đã soi $discoveries món đồ rồi!',
          textAlign: TextAlign.center,
          style: WonderType.body.copyWith(color: WonderColors.textSoft),
        ),
      ],
    );
  }

  String _greeting(int hour) {
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 14) return 'Chào buổi trưa';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

/// Thẻ một ngày: nền màu dịu bo tròn lớn + ngày + số vật + thumbnail cutout.
class _DayCard extends StatelessWidget {
  final List<JournalEntry> entries;
  final Color color;
  final void Function(JournalEntry) onOpen;

  const _DayCard({
    required this.entries,
    required this.color,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final d = entries.first.discoveredAt;
    final show = entries.take(4).toList();
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${d.day} tháng ${d.month}',
            style: WonderType.display.copyWith(
              color: WonderColors.textStrong,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${entries.length} vật',
            style: WonderType.body.copyWith(
              color: WonderColors.textStrong.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              for (final e in show)
                Pressable(
                  onTap: () => onOpen(e),
                  semanticLabel: 'Mở lại hành trình ${e.name}',
                  child: ObjectAvatar(
                    objectId: e.id,
                    emoji: e.emoji,
                    diameter: 66,
                    emojiSize: 34,
                    glowOpacity: 0.16,
                    sticker: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
