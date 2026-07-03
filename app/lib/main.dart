import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_settings.dart';
import 'data/capture_store.dart';
import 'data/collection_repository.dart';
import 'data/material_catalog.dart';
import 'data/mission_repository.dart';
import 'data/streak_repository.dart';
import 'router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CollectionRepository.init(); // khởi tạo Hive (initFlutter) + box sưu tập
  await AppSettings.init();
  await CaptureStore.init();
  // Nền game (Trục C/D): nạp mạng lưới vật liệu + nhiệm vụ (offline, bundled).
  await MaterialCatalog.init();
  await MissionRepository.init(); // mở box 'wonderlens_progress' (sau Hive init)
  await StreakRepository.init(); // chuỗi ngày khám phá — box 'wonderlens_streak'
  runApp(const ProviderScope(child: WonderLensApp()));
}

class WonderLensApp extends StatelessWidget {
  const WonderLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WonderLens',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
