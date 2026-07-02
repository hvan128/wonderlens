import 'package:flutter/material.dart';

import '../models/object_content.dart';
import '../services/share_service.dart';
import '../ui/ui.dart';
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
            const SizedBox(height: WonderTokens.space20),
            // Nút 3D thương hiệu; đang chia sẻ → khoá nút + đổi nhãn cho bé biết.
            SizedBox(
              width: kShareCardWidth,
              child: WonderButton(
                label: _sharing ? 'Đang chia sẻ…' : 'Chia sẻ ngay',
                icon: PhosphorIconsBold.shareNetwork,
                onTap: _sharing ? null : _share,
              ),
            ),
            const SizedBox(height: WonderTokens.space4),
            WonderTextButton(
              label: 'Để sau',
              color: Colors.white.withValues(alpha: 0.8),
              onTap: _sharing ? null : () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
