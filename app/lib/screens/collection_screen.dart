import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/capture_store.dart';
import '../data/collection_repository.dart';
import '../data/content_repository.dart';
import '../data/hero_catalog.dart';
import '../services/camera_warmup.dart';
import '../services/photo_library_service.dart';
import '../ui/ui.dart';
import '../widgets/object_item_actions.dart';
import '../widgets/object_sticker_grid.dart';

/// Rương khám phá: **chỉ danh sách vật** dạng sticker (2 cột + tên die-cut) trên
/// nền chấm, aperture chụp nổi ở đáy — như ảnh mẫu. Thành tích/huy hiệu nằm ở
/// tab Hồ sơ. Dùng cả tab trong [MainShell] ([inShell]) lẫn push riêng (có back).
class CollectionScreen extends StatefulWidget {
  final bool inShell;

  const CollectionScreen({super.key, this.inShell = false});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final CollectionRepository _repo = CollectionRepository();
  final PhotoLibraryService _photoLibrary = PhotoLibraryService();

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showItemActions(StickerItem item) {
    WonderHaptics.primary();
    final saved = _repo.containsObject(item.id);
    showObjectItemActionsSheet<void>(
      context: context,
      item: item,
      saved: saved,
      onSave: (key) => _saveStickerToPhotos(item, key),
      onDelete: saved
          ? () {
              final removed = _repo.remove(item.id);
              unawaited(CaptureStore.instance.delete(item.id));
              if (mounted) setState(() {});
              _showMessage(
                removed
                    ? 'Đã xóa ${item.name} khỏi rương'
                    : 'Không tìm thấy ${item.name} trong rương',
              );
            }
          : null,
    );
  }

  Future<void> _saveStickerToPhotos(StickerItem item, GlobalKey key) async {
    try {
      final result = await _photoLibrary.saveStickerCard(
        boundaryKey: key,
        objectId: item.id,
        objectName: item.name,
      );
      if (!result.hadImage) {
        _showMessage('Chưa chuẩn bị được ảnh ${item.name} để lưu');
      } else if (result.saved) {
        _showMessage('Đã lưu ${item.name} vào Ảnh');
      } else {
        _showMessage('Chưa lưu được ảnh ${item.name}');
      }
    } on PlatformException catch (e) {
      if (e.code == 'permission_denied') {
        _showMessage('Máy chưa cho phép WonderLens lưu vào Ảnh');
      } else {
        _showMessage('Chưa lưu được ảnh ${item.name}');
      }
    } catch (_) {
      _showMessage('Chưa lưu được ảnh ${item.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final discovered = _repo.discoveredIds().toSet();
    final journal = _repo.journalEntries();
    final items = <StickerItem>[
      for (final h in heroCatalog)
        if (discovered.contains(h.id))
          StickerItem(id: h.id, name: h.name, emoji: h.emoji),
      for (final e in journal)
        StickerItem(id: e.id, name: e.name, emoji: e.emoji),
    ];

    void openTap(String id) {
      if (heroById(id) != null) {
        _openHeroJourney(context, id);
      } else {
        _openJournalJourney(context, journal.firstWhere((e) => e.id == id));
      }
    }

    final Widget grid = items.isEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(
              'Chưa có vật nào — soi vài món để lấp đầy rương nhé!',
              textAlign: TextAlign.center,
              style: WonderType.body.copyWith(color: WonderColors.textSoft),
            ),
          )
        : ObjectStickerGrid(
            items: items,
            onTap: openTap,
            onLongPress: (id) =>
                _showItemActions(items.firstWhere((item) => item.id == id)),
          );

    if (widget.inShell) {
      return SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Rương của bé',
                    style: WonderType.display.copyWith(
                      color: WonderColors.textStrong,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${items.length} vật đã sưu tầm',
                    style: WonderType.body.copyWith(
                      color: WonderColors.textSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(
                        top: 4,
                        bottom: WonderTokens.tabBarClearance + 120,
                      ),
                      children: <Widget>[grid],
                    ),
                  ),
                ],
              ),
            ),
            // Aperture chụp nổi ở đáy (trên thanh tab) — như ảnh mẫu.
            Positioned(
              left: 0,
              right: 0,
              bottom: WonderTokens.tabBarClearance + 6,
              child: Center(
                child: ApertureCaptureButton(
                  size: 92,
                  // Chỉ hâm nóng khi đã cấp quyền — không bật dialog lạc chỗ.
                  onPressStart: () => CameraWarmup.instance.prewarmIfGranted(),
                  onCapture: () => context.push('/camera'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return WonderScaffold(
      header: WonderHeader(
        title: 'Rương khám phá',
        subtitle: '${items.length} vật đã sưu tầm',
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/camera'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: <Widget>[grid],
      ),
    );
  }
}

/// Mở lại hành trình vật hero (nội dung đóng gói offline, load tức thì + cache).
Future<void> _openHeroJourney(BuildContext context, String id) async {
  final content = await ContentRepository().load(id);
  if (!context.mounted || content == null) return;
  context.push('/timeline', extra: content);
}

/// Mở lại hành trình vật AI-live từ nhật ký (offline, ảnh chặng đã cache theo id).
void _openJournalJourney(BuildContext context, JournalEntry entry) {
  context.push('/timeline', extra: entry.toContent());
}
