import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:wonderlens/data/subscription_repository.dart';
import 'package:wonderlens/screens/subscription_screen.dart';

void main() {
  late _MemBox box;

  setUp(() {
    box = _MemBox();
    SubscriptionRepository.debugSetBox(box);
  });

  tearDown(() {
    SubscriptionRepository.debugSetBox(null);
  });

  test('activateMock bật Plus và restore đọc lại được', () async {
    expect(SubscriptionRepository.state.value.isPremium, isFalse);

    await SubscriptionRepository().activateMock('wonderlens_plus_yearly_mock');

    expect(SubscriptionRepository.state.value.isPremium, isTrue);
    expect(await SubscriptionRepository().restore(), isTrue);
  });

  testWidgets('paywall bật Plus sau parental gate', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SubscriptionScreen()));
    await tester.pump();

    expect(find.text('Nâng cấp WonderLens Plus'), findsOneWidget);

    await tester.tap(find.text('Bắt đầu dùng thử 3 ngày'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Dành cho phụ huynh'),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(SubscriptionRepository.state.value.isPremium, isTrue);
    expect(find.text('Bạn đã sẵn sàng'), findsOneWidget);
  });
}

class _MemBox extends Fake implements Box {
  final Map<dynamic, dynamic> _data = <dynamic, dynamic>{};

  @override
  Future<void> put(dynamic key, dynamic value) async {
    _data[key] = value;
  }

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _data[key] ?? defaultValue;
}
