import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_settings.dart';
import 'data/capture_store.dart';
import 'data/content_repository.dart';
import 'models/object_content.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Entry dev-only xem nhanh Timeline full-screen theo chặng (Phase B):
///
///   flutter run -t lib/main_timeline_preview.dart
///
/// Nạp một vật hero (có chặng + ảnh + lịch sử) + cutout mẫu cho cover, dùng giọng
/// máy để tự đẩy chặng. KHÔNG dùng cho build phát hành.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CaptureStore.init();
  await AppSettings.init();
  AppSettings.useLiveApi = false; // preview: giọng máy on-device, khỏi cần proxy
  final content = await ContentRepository().load('paper_cup');
  if (content != null) {
    try {
      final data = await rootBundle.load('assets/images/mascot/otter_idle.png');
      await CaptureStore.instance.save(content.id, data.buffer.asUint8List());
    } catch (_) {}
  }
  runApp(_TimelinePreviewApp(content: content));
}

class _TimelinePreviewApp extends StatefulWidget {
  final ObjectContent? content;
  const _TimelinePreviewApp({required this.content});

  @override
  State<_TimelinePreviewApp> createState() => _TimelinePreviewAppState();
}

class _TimelinePreviewAppState extends State<_TimelinePreviewApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = widget.content;
      if (c != null) appRouter.push('/timeline', extra: c);
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
