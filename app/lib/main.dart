import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_settings.dart';
import 'data/capture_store.dart';
import 'data/collection_repository.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'ui/capture_dissolve.dart';
import 'ui/wonder_haptics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CollectionRepository.init();
  await AppSettings.init();
  await CaptureStore.init();
  await WonderHaptics.init();
  // Nạp sẵn shader tan biến để lúc bé chụp xong dựng hiệu ứng tức thì.
  await DissolveShader.ensureLoaded();
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
