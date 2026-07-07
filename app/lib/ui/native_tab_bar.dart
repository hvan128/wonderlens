import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'phosphor_compat.dart';

/// Thanh tab **NATIVE của iOS** (`UITabBar` qua PlatformView) — iOS 26 tự có
/// Liquid Glass + chỉ báo chọn tab morph "giọt nước" mượt. Icon dùng **chính bộ
/// icon của app** (render ra PNG rồi đưa native, native tint + morph như thường).
/// Chạm tab native → [onSelect]; [index] đổi từ Flutter đẩy xuống native.
class NativeTabBar extends StatefulWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const NativeTabBar({super.key, required this.index, required this.onSelect});

  @override
  State<NativeTabBar> createState() => _NativeTabBarState();
}

class _NativeTabBarState extends State<NativeTabBar> {
  static const MethodChannel _channel = MethodChannel('wonderlens/tabbar');
  static const List<(IconData, String)> _tabs = <(IconData, String)>[
    (PhosphorIconsBold.houseSimple, 'Trang chủ'),
    (PhosphorIconsBold.grid, 'Rương'),
    (PhosphorIconsBold.user, 'Hồ sơ'),
  ];

  Map<String, dynamic>? _params;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_handle);
    _prepare();
  }

  @override
  void didUpdateWidget(NativeTabBar old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _channel.invokeMethod('setIndex', widget.index).catchError((_) {});
    }
  }

  Future<dynamic> _handle(MethodCall call) async {
    if (call.method == 'onSelect') widget.onSelect(call.arguments as int);
    return null;
  }

  Future<void> _prepare() async {
    final icons = <Uint8List>[
      for (final t in _tabs) await _renderIcon(t.$1),
    ];
    if (!mounted) return;
    setState(() {
      _params = <String, dynamic>{
        'index': widget.index,
        'icons': icons,
        'labels': <String>[for (final t in _tabs) t.$2],
      };
    });
  }

  /// Vẽ glyph icon (font của app) ra PNG đen-trên-trong; native đặt template để
  /// tự tô màu theo trạng thái chọn. Canvas VUÔNG có padding + đo đúng kích thước
  /// glyph (height 1.0) để KHÔNG bị cắt (crop làm icon méo/mặt buồn).
  Future<Uint8List> _renderIcon(IconData icon) async {
    const double glyph = 64;
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: glyph,
          height: 1.0,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: const Color(0xFF000000),
        ),
      ),
    )..layout();
    // Cạnh = glyph lớn nhất + đệm; đủ để chứa trọn, không cắt.
    final double side = (glyph + 20).ceilToDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    tp.paint(canvas, Offset((side - tp.width) / 2, (side - tp.height) / 2));
    final image = await recorder.endRecording().toImage(side.toInt(), side.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS || _params == null) {
      return const SizedBox.shrink();
    }
    return UiKitView(
      viewType: 'wonder_native_tabbar',
      creationParams: _params,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
