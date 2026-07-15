import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/app_settings.dart';
import '../data/capture_store.dart';
import '../data/collection_repository.dart';
import '../data/content_repository.dart';
import '../data/hero_catalog.dart';
import '../models/object_content.dart';
import '../services/camera_warmup.dart';
import '../services/photo_library_service.dart';
import '../ui/ui.dart';
import '../widgets/object_item_actions.dart';
import '../widgets/object_sticker_grid.dart';
import '../widgets/share_sheet.dart';
import '../widgets/sticker_physics_field.dart';

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

  /// Mode thử nghiệm "Thả rơi": bật trọng lực cho toàn bộ sticker rơi–nảy.
  /// Mặc định false = lưới xếp gọn như cũ, kéo thả đổi chỗ tự do.
  bool _gravity = false;

  /// Tăng 1 mỗi lần bấm "Xếp gọn" → ép đưa mọi sticker về lại lưới.
  int _tidyEpoch = 0;

  /// Bố cục sticker đã lưu từ phiên trước (chuẩn hoá) — đọc 1 lần, khôi phục
  /// đúng chỗ lúc rời đi. Mode luôn khởi động ở "xếp gọn" (không bật trọng lực).
  final Map<String, Offset> _savedLayout = AppSettings.chestStickerLayout;

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
      onShare: () => unawaited(_shareItem(item)),
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

  /// Mở bảng chia sẻ thẻ hành trình của vật. Hero lấy content asset đầy đủ qua
  /// [ContentRepository]; vật AI-live dựng lại từ nhật ký ([JournalEntry]).
  Future<void> _shareItem(StickerItem item) async {
    ObjectContent? content;
    if (heroById(item.id) != null) {
      content = await ContentRepository().load(item.id);
    } else {
      final journal = _repo.journalEntries();
      final idx = journal.indexWhere((e) => e.id == item.id);
      if (idx >= 0) content = journal[idx].toContent();
    }
    if (!mounted || content == null) return;
    await showDiscoveryShareSheet(context, content);
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
      // Header chiếm dải trên; hồ bóng dựng trần ngay dưới nó.
      const double fieldTopInset = 96;
      const double captureSize = 92;
      const double captureBottomInset = WonderTokens.tabBarClearance + 6;
      // Sàn = mép trên thanh tab native (cao 49 + vùng an toàn đáy).
      final double tabBarTopInset = 49 + MediaQuery.paddingOf(context).bottom;

      final Widget field = items.isEmpty
          ? Padding(
              padding: EdgeInsets.only(top: fieldTopInset + 24),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Chưa có vật nào — soi vài món để lấp đầy rương nhé!',
                    textAlign: TextAlign.center,
                    style: WonderType.body.copyWith(
                      color: WonderColors.textSoft,
                    ),
                  ),
                ),
              ),
            )
          : StickerPhysicsField(
              items: items,
              onTap: openTap,
              onLongPress: (id) =>
                  _showItemActions(items.firstWhere((item) => item.id == id)),
              topInset: fieldTopInset,
              bottomInset: tabBarTopInset,
              captureBottomInset: captureBottomInset,
              captureSize: captureSize,
              gravity: _gravity,
              tidyEpoch: _tidyEpoch,
              initialLayout: _savedLayout,
              onLayoutChanged: AppSettings.setChestStickerLayout,
            );

      return SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            // Hồ bóng full-screen (tự chừa header/tab bar bằng inset).
            Positioned.fill(child: field),
            // Header nổi trên hồ bóng + nút "Thả rơi".
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                        ],
                      ),
                    ),
                    if (items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 8),
                        child: _ChestModeButton(
                          gravity: _gravity,
                          onTap: () => setState(() {
                            if (_gravity) {
                              _gravity = false;
                              _tidyEpoch++;
                            } else {
                              _gravity = true;
                            }
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Aperture chụp nổi ở đáy (trên thanh tab) — như ảnh mẫu.
            Positioned(
              left: 0,
              right: 0,
              bottom: captureBottomInset,
              child: Center(
                child: ApertureCaptureButton(
                  size: captureSize,
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

/// Nút chuyển mode Rương. Mặc định hiện **"Thả rơi"** (bật trọng lực thử
/// nghiệm); khi đang thả rơi thì hiện **"Xếp gọn"** để dồn sticker về lưới cũ.
/// Tông mật ong ấm (cùng thế giới thẻ giấy thô), không dùng emoji làm icon.
class _ChestModeButton extends StatelessWidget {
  final bool gravity;
  final VoidCallback onTap;

  const _ChestModeButton({required this.gravity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = gravity ? 'Xếp gọn' : 'Thả rơi';
    final icon = gravity
        ? PhosphorIconsBold.grid
        : PhosphorIconsBold.arrowDown;
    return Pressable(
      onTap: () {
        WonderHaptics.selection();
        onTap();
      },
      haptic: false,
      semanticLabel: gravity
          ? 'Xếp sticker về lưới'
          : 'Thả rơi toàn bộ sticker (thử nghiệm)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: WonderGradients.honey,
          borderRadius: BorderRadius.circular(WonderTokens.pill),
          boxShadow: WonderShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PhosphorIcon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: WonderType.textButton.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
