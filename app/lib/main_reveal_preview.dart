import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/capture_store.dart';
import 'models/object_content.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Entry dev-only để xem nhanh màn "sticker reveal" (Phase A) mà không cần camera:
///
///   flutter run -t lib/main_reveal_preview.dart
///
/// Nạp một cutout mẫu (ảnh otter trong suốt) vào CaptureStore rồi mở /reveal với
/// content mẫu. KHÔNG dùng cho build phát hành.
const _demo = ObjectContent(
  id: 'demo_reveal',
  name: 'Điện thoại',
  emoji: '📱',
  materialBadge: 'Nhựa & kim loại',
  stages: <Stage>[],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CaptureStore.init();
  final data = await rootBundle.load('assets/images/mascot/otter_idle.png');
  await CaptureStore.instance.save('demo_reveal', data.buffer.asUint8List());
  runApp(const _RevealPreviewApp());
}

class _RevealPreviewApp extends StatefulWidget {
  const _RevealPreviewApp();

  @override
  State<_RevealPreviewApp> createState() => _RevealPreviewAppState();
}

class _RevealPreviewAppState extends State<_RevealPreviewApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appRouter.push('/reveal', extra: _demo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
