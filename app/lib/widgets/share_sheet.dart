import 'package:flutter/material.dart';

import '../models/object_content.dart';
import '../services/share_service.dart';
import 'share_card.dart';

/// Mở bảng xem trước một lần khám phá (màn Hành trình).
Future<void> showDiscoveryShareSheet(
  BuildContext context,
  ObjectContent content,
) {
  return _showSharePreview(
    context,
    card: ShareCard(content: content),
    onShare: (key, origin) => ShareService.shareDiscovery(
      boundaryKey: key,
      content: content,
      origin: origin,
    ),
  );
}

/// Mở bảng xem trước thẻ khoe bộ sưu tập (màn Bộ sưu tập).
Future<void> showCollectionShareSheet(
  BuildContext context, {
  required String levelTitle,
  required int discoveredCount,
  required int totalCount,
  required List<String> earnedMaterials,
  required List<String> discoveredEmojis,
}) {
  return _showSharePreview(
    context,
    card: CollectionShareCard(
      levelTitle: levelTitle,
      discoveredCount: discoveredCount,
      totalCount: totalCount,
      earnedMaterials: earnedMaterials,
      discoveredEmojis: discoveredEmojis,
    ),
    onShare: (key, origin) => ShareService.shareCollection(
      boundaryKey: key,
      levelTitle: levelTitle,
      discoveredCount: discoveredCount,
      totalCount: totalCount,
      earnedCount: earnedMaterials.length,
      origin: origin,
    ),
  );
}

/// Bảng xem trước chung: dựng [card] trong RepaintBoundary, bấm nút thì gọi
/// [onShare] với key boundary + vị trí (để neo popover trên iPad).
Future<void> _showSharePreview(
  BuildContext context, {
  required Widget card,
  required Future<void> Function(GlobalKey boundaryKey, Rect? origin) onShare,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SharePreview(card: card, onShare: onShare),
  );
}

class _SharePreview extends StatefulWidget {
  final Widget card;
  final Future<void> Function(GlobalKey boundaryKey, Rect? origin) onShare;

  const _SharePreview({required this.card, required this.onShare});

  @override
  State<_SharePreview> createState() => _SharePreviewState();
}

class _SharePreviewState extends State<_SharePreview> {
  final _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    // Vị trí neo popover share sheet trên iPad: dùng khung của sheet.
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    try {
      await widget.onShare(_cardKey, origin);
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
        Navigator.of(context).maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: RepaintBoundary(key: _cardKey, child: widget.card),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: kShareCardWidth,
              child: FilledButton.icon(
                onPressed: _sharing ? null : _share,
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(_sharing ? 'Đang chuẩn bị…' : 'Chia sẻ ngay'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed:
                  _sharing ? null : () => Navigator.of(context).maybePop(),
              child: const Text('Để sau'),
            ),
          ],
        ),
      ),
    );
  }
}
