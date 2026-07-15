import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_settings.dart';
import 'data/capture_store.dart';
import 'data/collection_repository.dart';
import 'data/subscription_repository.dart';
import 'router.dart';
import 'services/mission_notification_service.dart';
import 'theme/app_theme.dart';
import 'ui/capture_dissolve.dart';
import 'ui/wonder_haptics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CollectionRepository.init();
  await AppSettings.init();
  await CaptureStore.init();
  await SubscriptionRepository.init();
  await WonderHaptics.init();
  await MissionNotificationService.instance.init(
    onOpenMission: (objectId) => appRouter.go('/onboarding/mission/$objectId'),
  );
  // Nạp sẵn shader tan biến để lúc bé chụp xong dựng hiệu ứng tức thì.
  await DissolveShader.ensureLoaded();
  runApp(const ProviderScope(child: WonderLensApp()));
}

class WonderLensApp extends StatefulWidget {
  const WonderLensApp({super.key});

  @override
  State<WonderLensApp> createState() => _WonderLensAppState();
}

class _WonderLensAppState extends State<WonderLensApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MissionNotificationService.instance.drainInitialMission();
      unawaited(MissionNotificationService.instance.scheduleComebackReminder());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(MissionNotificationService.instance.scheduleComebackReminder());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
