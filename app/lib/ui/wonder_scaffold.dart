import 'package:flutter/material.dart';

import 'wonder_background.dart';
import 'wonder_header.dart';

/// Vỏ trang dùng chung cho các màn nội dung: nền canvas (gradient + quầng màu) +
/// [WonderHeader] ghim trên cùng + body chiếm phần còn lại. Thay cho
/// `Scaffold(appBar: AppBar(...))` để toàn app dùng một header nhất quán.
///
/// [overlay] phủ lên trên toàn màn (vd confetti). [body] tự lo cuộn nếu cần.
class WonderScaffold extends StatelessWidget {
  final WonderHeader header;
  final Widget body;
  final Widget? overlay;

  /// Bọc nền canvas WonderBackground. Tắt khi màn đã tự dựng nền (vd camera).
  final bool background;

  const WonderScaffold({
    super.key,
    required this.header,
    required this.body,
    this.overlay,
    this.background = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          header,
          Expanded(child: body),
        ],
      ),
    );

    if (background) {
      content = WonderBackground(child: content);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: overlay == null
          ? content
          : Stack(children: <Widget>[content, overlay!]),
    );
  }
}
