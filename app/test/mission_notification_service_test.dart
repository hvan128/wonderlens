import 'package:flutter_test/flutter_test.dart';
import 'package:wonderlens/services/mission_notification_service.dart';

void main() {
  test('mission payload mở đúng hero object và fallback an toàn', () {
    final service = MissionNotificationService.instance;

    expect(service.objectIdFromPayload('mission:ball_pen'), 'ball_pen');
    expect(service.objectIdFromPayload('mission:not_a_hero'), 'paper_cup');
    expect(service.objectIdFromPayload('plain:ball_pen'), isNull);
    expect(service.objectIdFromPayload(null), isNull);
  });

  test('reminder delays khớp chiến lược phân phối', () {
    expect(MissionNotificationService.comebackDelay, const Duration(days: 2));
    expect(
      MissionNotificationService.debugTestDelay,
      const Duration(seconds: 10),
    );
  });
}
