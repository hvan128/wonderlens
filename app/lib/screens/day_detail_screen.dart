import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/capture_store.dart';
import '../data/collection_repository.dart';
import '../services/photo_library_service.dart';
import '../ui/ui.dart';
import '../widgets/object_item_actions.dart';
import '../widgets/object_sticker_grid.dart';

/// Dữ liệu cho route `/day` (go_router `extra`): nhóm vật của một ngày + màu thẻ
/// nguồn (để nền màn chi tiết morph từ đúng màu thẻ đó).
class DayGroup {
  final List<JournalEntry> entries;
  final Color color;
  const DayGroup(this.entries, this.color);
}

/// Tag Hero để mỗi vật **bay** từ thẻ ngày (trang chủ) sang màn chi tiết và
/// ngược lại khi thoát. Mỗi id chỉ xuất hiện một lần (dedup) nên tag là duy nhất.
String dayObjectHeroTag(String objectId) => 'day-obj-$objectId';

/// Tag Hero cho **nền thẻ** — thẻ phóng to thành màn full (và thu ngược lại).
/// Duy nhất theo ngày.
String dayCardHeroTag(DateTime d) => 'day-card-${d.year}-${d.month}-${d.day}';

/// Góc nghiêng sticker trên thẻ ngày — DÙNG CHUNG công thức với component chung
/// ([stickerTilt]) để góc khớp nhau khi Hero bay (không giật góc).
double dayStickerTilt(int index) => stickerTilt(index);

/// Shuttle cho Hero nền thẻ: trong lúc bay, morph **màu** (màu thẻ → nền sáng) và
/// **bo góc** (26 → 0) theo tiến trình → thẻ phóng to mượt thành màn full. Dùng
/// chung cho cả thẻ (nguồn) và màn chi tiết (đích) để hai bên khớp shuttle.
HeroFlightShuttleBuilder dayCardFlightShuttle(Color cardColor) {
  return (flightContext, animation, direction, fromContext, toContext) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value; // 0 = thẻ, 1 = màn full
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(cardColor, WonderBackground.base, t),
            borderRadius: BorderRadius.circular(lerpDouble(26, 0, t)!),
          ),
        );
      },
    );
  };
}

/// Đường bay Hero **thẳng** cho nền thẻ — dùng chung [stickerLinearRectTween].
RectTween dayLinearRectTween(Rect? begin, Rect? end) =>
    stickerLinearRectTween(begin, end);

/// Màn **chi tiết một ngày** (route `/day`) — chạm thẻ ngày ở trang chủ mở màn
/// này: nền + tiêu đề mờ dần hiện ra, còn từng vật **bay** (Hero) từ vị trí trên
/// thẻ vào lưới. Thoát → các vật bay ngược về thẻ.
///
/// Bố cục: tiêu đề ngày lớn + số vật, các vật dạng **sticker die-cut** rải hai
/// cột so le trên nền chấm bi, nút vòng khẩu độ ở đáy để soi thêm. Chạm một
/// sticker → mở lại hành trình của vật đó.
class DayDetailView extends StatefulWidget {
  final List<JournalEntry> entries;

  /// Màu thẻ nguồn — để nền morph (Hero) phóng to từ đúng màu thẻ đó.
  final Color color;

  /// Thoát về trang chủ.
  final VoidCallback onClose;

  /// Soi vật mới (mở camera).
  final VoidCallback onCapture;

  /// Mở lại hành trình của một vật.
  final void Function(JournalEntry) onOpenEntry;

  const DayDetailView({
    super.key,
    required this.entries,
    required this.color,
    required this.onClose,
    required this.onCapture,
    required this.onOpenEntry,
  });

  @override
  State<DayDetailView> createState() => _DayDetailViewState();
}

class _DayDetailViewState extends State<DayDetailView> {
  late List<JournalEntry> _entries;
  final CollectionRepository _repo = CollectionRepository();
  final PhotoLibraryService _photoLibrary = PhotoLibraryService();

  @override
  void initState() {
    super.initState();
    _entries = List<JournalEntry>.of(widget.entries);
  }

  @override
  void didUpdateWidget(covariant DayDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _entries = List<JournalEntry>.of(widget.entries);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showItemActions(String id) {
    WonderHaptics.primary();
    final entry = _entries.firstWhere((e) => e.id == id);
    final item = StickerItem(
      id: entry.id,
      name: entry.name,
      emoji: entry.emoji,
    );
    final saved = _repo.containsObject(id);
    showObjectItemActionsSheet<void>(
      context: context,
      item: item,
      saved: saved,
      onSave: (key) => _saveStickerToPhotos(item, key),
      onDelete: saved
          ? () {
              final removed = _repo.remove(id);
              unawaited(CaptureStore.instance.delete(id));
              if (mounted) {
                setState(() => _entries.removeWhere((e) => e.id == id));
              }
              _showMessage(
                removed
                    ? 'Đã xóa ${entry.name} khỏi rương'
                    : 'Không tìm thấy ${entry.name} trong rương',
              );
              if (mounted && _entries.isEmpty) widget.onClose();
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
    if (_entries.isEmpty) return const SizedBox.shrink();

    final d = _entries.first.discoveredAt;
    // Material trong suốt: cấp ngữ cảnh text cho route (thiếu Material →
    // Flutter vẽ gạch chân vàng "thiếu Material").
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Nền = Hero **cùng tag với thẻ**: khi mở, thẻ phóng to thành nền full
          // (morph màu thẻ → nền sáng, bo góc 26 → 0 qua shuttle); khi thoát, thu
          // ngược về thẻ. Ở trạng thái nghỉ, đây là nền base đặc của màn chi tiết.
          Positioned.fill(
            child: Hero(
              tag: dayCardHeroTag(d),
              createRectTween: dayLinearRectTween,
              flightShuttleBuilder: dayCardFlightShuttle(widget.color),
              child: const ColoredBox(color: WonderBackground.base),
            ),
          ),
          // Lưới chấm + nội dung (mờ dần vào theo transition của route). paintBase
          // = false để nền base do Hero phía dưới lo (không đè mất phần morph).
          WonderBackground(
            paintBase: false,
            child: SafeArea(
              child: Stack(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: WonderBackButton(onTap: widget.onClose),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${d.day} tháng ${d.month}',
                              style: WonderType.display.copyWith(
                                color: WonderColors.textStrong,
                                fontSize: 34,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_entries.length} vật',
                              style: WonderType.body.copyWith(
                                color: WonderColors.textSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          // Chừa đáy rộng để hàng cuối cuộn lên TRÊN nút vòng nổi.
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 128),
                          // Component chung (sticker + tem): vật là NỘI DUNG màn
                          // được mở nên isOpener=false; tag khớp avatar trên thẻ.
                          child: StickerStaggeredGrid(
                            items: <StickerItem>[
                              for (final e in _entries)
                                StickerItem(
                                  id: e.id,
                                  name: e.name,
                                  emoji: e.emoji,
                                ),
                            ],
                            onTap: (id) => widget.onOpenEntry(
                              _entries.firstWhere((e) => e.id == id),
                            ),
                            onLongPress: _showItemActions,
                            heroTag: dayObjectHeroTag,
                            isOpener: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Nút vòng NỔI (nền trong suốt) — không chiếm dải cắt mất chỗ hiện
                  // vật; vùng quanh nút không chặn chạm nên vẫn cuộn/mở vật phía sau.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    child: Center(
                      child: ApertureCaptureButton(
                        size: 84,
                        showGuide: false,
                        animateOnTap: false,
                        onCapture: widget.onCapture,
                        semanticLabel: 'Soi vật mới',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
