import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/data/app_settings.dart';
import 'package:wonderlens/data/collection_repository.dart';
import 'package:wonderlens/data/subscription_repository.dart';
import 'package:wonderlens/screens/profile_screen.dart';

void main() {
  setUp(() {
    AppSettings.debugSetBox(null);
    AppSettings.missionRemindersEnabled.value = false;
    CollectionRepository.debugSetBox(null);
    SubscriptionRepository.debugSetBox(null);
  });

  tearDown(() {
    AppSettings.debugSetBox(null);
    CollectionRepository.debugSetBox(null);
    SubscriptionRepository.debugSetBox(null);
  });

  testWidgets('profile settings shows reminder and plus rows', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Nhắc khám phá'), findsOneWidget);
    expect(find.text('WonderLens Plus'), findsOneWidget);
    expect(find.text('Chưa bật'), findsOneWidget);
  });
}
