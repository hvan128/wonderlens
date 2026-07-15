import 'dart:async';

import 'package:flutter/material.dart';

import '../ui/ui.dart';
import 'object_avatar.dart';
import 'object_sticker_grid.dart';

typedef SaveStickerCard = Future<void> Function(GlobalKey boundaryKey);

/// Bottom sheet hành động khi nhấn giữ một vật phẩm trong rương/nhật ký.
Future<T?> showObjectItemActionsSheet<T>({
  required BuildContext context,
  required StickerItem item,
  required bool saved,
  SaveStickerCard? onSave,
  VoidCallback? onShare,
  VoidCallback? onDelete,
}) {
  return showGlassSheet<T>(
    context: context,
    title: 'Vật phẩm',
    builder: (_) => ObjectItemActions(
      item: item,
      saved: saved,
      onSave: onSave,
      onShare: onShare,
      onDelete: onDelete,
    ),
  );
}

class ObjectItemActions extends StatefulWidget {
  final StickerItem item;
  final bool saved;
  final SaveStickerCard? onSave;

  /// Mở bảng chia sẻ thẻ hành trình khoa học của vật (khoe lên mạng xã hội).
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const ObjectItemActions({
    super.key,
    required this.item,
    required this.saved,
    this.onSave,
    this.onShare,
    this.onDelete,
  });

  @override
  State<ObjectItemActions> createState() => _ObjectItemActionsState();
}

class _ObjectItemActionsState extends State<ObjectItemActions> {
  final GlobalKey _exportKey = GlobalKey();
  bool _saving = false;

  Future<void> _save() async {
    final onSave = widget.onSave;
    if (_saving || onSave == null) return;
    setState(() => _saving = true);
    await onSave(_exportKey);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            ObjectAvatar(
              objectId: widget.item.id,
              emoji: widget.item.emoji,
              diameter: 68,
              emojiSize: 34,
              glowOpacity: 0.14,
              sticker: true,
            ),
            const SizedBox(width: WonderTokens.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WonderType.heading.copyWith(
                      color: WonderColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.saved
                        ? 'Trong rương WonderLens'
                        : 'Từ nhật ký khám phá',
                    style: WonderType.caption.copyWith(
                      color: WonderColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: WonderTokens.space20),
        if (widget.onSave != null) ...<Widget>[
          Center(
            child: SizedBox(
              height: 220,
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(
                  key: _exportKey,
                  child: _PhotoStickerCard(item: widget.item),
                ),
              ),
            ),
          ),
          const SizedBox(height: WonderTokens.space16),
        ],
        if (widget.onShare != null) ...<Widget>[
          _ActionRow(
            icon: PhosphorIconsBold.shareNetwork,
            label: 'Khoe khám phá',
            subtitle: 'Chia sẻ thẻ hành trình khoa học của vật này.',
            onTap: () {
              Navigator.of(context).pop();
              widget.onShare!();
            },
          ),
          const SizedBox(height: WonderTokens.space8),
        ],
        if (widget.onSave != null)
          _ActionRow(
            icon: _saving
                ? PhosphorIconsBold.history
                : PhosphorIconsBold.saveAdd,
            label: _saving ? 'Đang lưu...' : 'Lưu vào Ảnh',
            subtitle: 'Lưu thẻ giấy có sticker và tên vào thư viện ảnh.',
            onTap: _saving ? null : () => unawaited(_save()),
          ),
        if (widget.onDelete != null) ...<Widget>[
          const SizedBox(height: WonderTokens.space8),
          _ActionRow(
            icon: PhosphorIconsBold.trash,
            label: 'Xóa khỏi rương',
            subtitle: 'Xóa vật này và ảnh sticker đã lưu trên máy.',
            color: WonderColors.coral,
            onTap: () {
              Navigator.of(context).pop();
              widget.onDelete!();
            },
          ),
        ],
      ],
    );
  }
}

class _PhotoStickerCard extends StatelessWidget {
  final StickerItem item;

  const _PhotoStickerCard({required this.item});

  static const double _width = 360;
  static const double _height = 420;
  static const Color _paperTint = Color(0xFFF3E3BE);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ColoredBox(
              color: _paperTint,
              child: Image.asset(
                'assets/images/kraft_paper.png',
                fit: BoxFit.cover,
                color: _paperTint,
                colorBlendMode: BlendMode.multiply,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0x33FFFFFF),
                    Color(0x00FFFFFF),
                    Color(0x18000000),
                  ],
                  stops: <double>[0.0, 0.52, 1.0],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.58),
                  width: 2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 34, 30, 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ObjectAvatar(
                    objectId: item.id,
                    emoji: item.emoji,
                    diameter: 230,
                    emojiSize: 108,
                    glowOpacity: 0.12,
                    sticker: true,
                    stickerBorderFactor: 0.045,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -12),
                    child: SizedBox(width: 290, child: StickerLabel(item.name)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.color = WonderColors.tealDeep,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.all(WonderTokens.space12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(icon, size: 22, color: color),
            ),
            const SizedBox(width: WonderTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: WonderType.body.copyWith(
                      color: WonderColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: WonderType.caption.copyWith(
                      color: WonderColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
