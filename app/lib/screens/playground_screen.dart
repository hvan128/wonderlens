import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// Màn dev thử design system v2 (liquid glass): panel nổi kéo/resize, sheet
/// kính, nút/chip/icon button. KHÔNG nằm trong flow của bé — chỉ mở được từ
/// Dev panel qua `Navigator.push` (không đăng ký route).
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  /// Hình học của hai panel demo — controller sống trong State để giữ vị trí/
  /// kích thước khi setState, và dispose đúng vòng đời.
  final GlassPanelController _controlsPanel = GlassPanelController(
    position: const Offset(24, 80),
    size: const Size(300, 260),
  );
  final GlassPanelController _notesPanel = GlassPanelController(
    position: const Offset(60, 380),
    size: const Size(280, 200),
  );
  final GlassPanelController _mascotPanel = GlassPanelController(
    position: const Offset(28, 96),
    size: const Size(320, 360),
  );

  /// Panel "Ghi chú" còn hiển thị không — nút đóng trên thanh tiêu đề tắt nó.
  bool _showNotes = true;

  @override
  void dispose() {
    _controlsPanel.dispose();
    _notesPanel.dispose();
    _mascotPanel.dispose();
    super.dispose();
  }

  void _openSheet() {
    showGlassSheet<void>(
      context: context,
      title: 'Sheet kính',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Sheet nổi kiểu iOS 26: trượt vào bằng spring, kéo xuống quá 1/3 '
            'hoặc fling nhanh để đóng, nhẹ hơn thì nảy về chỗ.',
            style: WonderType.body.copyWith(color: WonderColors.textStrong),
          ),
          const SizedBox(height: WonderTokens.space16),
          GlassButton(
            label: 'Đóng sheet',
            onTap: () => Navigator.pop(sheetContext),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WonderScaffold(
      header: WonderHeader(
        title: 'Playground',
        subtitle: 'Design system v2',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: GlassPanelArea(
        // Nút nổi dưới đáy nằm ở lớp nền — panel kéo đè lên được (chấp nhận
        // cho màn dev).
        background: Stack(
          children: <Widget>[
            Positioned(
              left: WonderTokens.space24,
              right: WonderTokens.space24,
              bottom: WonderTokens.space24 +
                  MediaQuery.of(context).padding.bottom,
              child: GlassButton(
                label: 'Mở Glass Sheet',
                icon: PhosphorIconsFill.sparkle,
                onTap: _openSheet,
              ),
            ),
          ],
        ),
        panels: <GlassPanel>[
          GlassPanel(
            controller: _mascotPanel,
            title: 'Linh vật',
            icon: PhosphorIconsFill.sparkle,
            tone: GlassTone.light,
            child: const _MascotDemo(),
          ),
          GlassPanel(
            controller: _controlsPanel,
            title: 'Bảng điều khiển',
            icon: PhosphorIconsFill.sparkle,
            tone: GlassTone.light,
            child: const _ControlsDemo(),
          ),
          if (_showNotes)
            GlassPanel(
              controller: _notesPanel,
              title: 'Ghi chú',
              icon: PhosphorIconsBold.books,
              tone: GlassTone.dark,
              onClose: () => setState(() => _showNotes = false),
              child: const _NotesDemo(),
            ),
        ],
      ),
    );
  }
}

/// Nội dung panel "Bảng điều khiển": bộ component tương tác của design system.
/// Cuộn được để panel resize nhỏ vẫn không tràn.
class _ControlsDemo extends StatelessWidget {
  const _ControlsDemo();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          WonderButton(label: 'Nút chính', onTap: () {}),
          Row(
            children: <Widget>[
              WonderTextButton(label: 'Nút phụ', onTap: () {}),
              const Spacer(),
              GlassIconButton(
                icon: PhosphorIconsBold.flask,
                tone: GlassTone.light,
                size: 44,
                onTap: () {},
                semanticLabel: 'Nút kính demo',
              ),
            ],
          ),
          const SizedBox(height: WonderTokens.space8),
          const Wrap(
            spacing: WonderTokens.space8,
            runSpacing: WonderTokens.space8,
            children: <Widget>[
              WonderChip(
                label: 'Nhựa',
                icon: PhosphorIconsFill.flask,
                tone: GlassTone.light,
              ),
              WonderChip(
                label: 'AI',
                icon: PhosphorIconsFill.sparkle,
                tone: GlassTone.light,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Nội dung panel "Ghi chú" (tông tối, chữ trắng).
class _NotesDemo extends StatelessWidget {
  const _NotesDemo();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Panel kính tông tối: kéo bằng thanh tiêu đề, resize từ cạnh/góc, '
      'chạm là nổi lên trên cùng. Bấm nút x để ẩn panel này.',
      style: WonderType.body.copyWith(color: Colors.white),
    );
  }
}

/// Preview linh vật: đổi mood để xem Rái đổi pose + chuyển động thủ tục.
class _MascotDemo extends StatefulWidget {
  const _MascotDemo();

  @override
  State<_MascotDemo> createState() => _MascotDemoState();
}

class _MascotDemoState extends State<_MascotDemo> {
  MascotMood _mood = MascotMood.idle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(child: WonderMascot(mood: _mood, size: 150)),
          const SizedBox(height: WonderTokens.space8),
          Wrap(
            spacing: WonderTokens.space8,
            runSpacing: WonderTokens.space8,
            children: <Widget>[
              for (final m in MascotMood.values)
                ChoiceChip(
                  label: Text(m.name),
                  selected: _mood == m,
                  onSelected: (_) => setState(() => _mood = m),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
