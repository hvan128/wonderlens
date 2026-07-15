import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/app_settings.dart';
import '../data/hero_catalog.dart';
import '../data/onboarding_mission.dart';
import '../util/vn_time.dart';

typedef MissionOpenHandler = void Function(String objectId);

/// Local comeback reminder: sau khi phụ huynh bật, app đặt một notification sau
/// 2 ngày. Nếu app được mở lại trước đó, reminder được đặt lại từ đầu.
class MissionNotificationService {
  MissionNotificationService._();

  static final MissionNotificationService instance =
      MissionNotificationService._();

  static const int _comebackNotificationId = 1501;
  static const String _payloadPrefix = 'mission:';
  static const String _channelId = 'wonderlens_missions';
  static const String _channelName = 'Nhiệm vụ khám phá';
  static const String _channelDescription =
      'Nhắc phụ huynh cùng bé khám phá một vật quen thuộc.';
  static const Duration comebackDelay = Duration(days: 2);
  static const Duration debugTestDelay = Duration(seconds: 10);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  MissionOpenHandler? _onOpenMission;
  String? _initialMissionObjectId;
  bool _ready = false;

  Future<void> init({MissionOpenHandler? onOpenMission}) async {
    _onOpenMission = onOpenMission;
    _initTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _initialMissionObjectId = _objectIdFromPayload(
        launchDetails?.notificationResponse?.payload,
      );
    }

    _ready = true;
    if (AppSettings.missionRemindersEnabled.value) {
      await scheduleComebackReminder();
    }
  }

  void setOpenHandler(MissionOpenHandler handler) {
    _onOpenMission = handler;
    drainInitialMission();
  }

  void drainInitialMission() {
    final id = _initialMissionObjectId;
    if (id == null) return;
    _initialMissionObjectId = null;
    _openMission(id);
  }

  Future<bool> setRemindersEnabled(bool enabled) async {
    if (!enabled) {
      AppSettings.setMissionRemindersEnabled(false);
      await cancelComebackReminder();
      return true;
    }

    final granted = await requestPermission();
    if (!granted) return false;
    AppSettings.setMissionRemindersEnabled(true);
    await scheduleComebackReminder();
    return true;
  }

  /// Lối test ẩn trong Hồ sơ: xin quyền nếu cần rồi đặt notification thật sau
  /// vài giây. Không dùng cho lịch thật nên không ảnh hưởng chống-spam.
  Future<bool> scheduleDebugTestReminder() async {
    final granted = await requestPermission();
    if (!granted) return false;
    AppSettings.setMissionRemindersEnabled(true);
    await scheduleComebackReminder(delay: debugTestDelay);
    return true;
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;

    final androidResult = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final iosResult = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: true);

    // Platforms without runtime notification permission return null.
    return androidResult ?? iosResult ?? true;
  }

  Future<void> scheduleComebackReminder({
    Duration delay = comebackDelay,
  }) async {
    if (!_ready || !AppSettings.missionRemindersEnabled.value) return;

    final mission = OnboardingMission.forObjectId(_nextMissionObjectId());
    AppSettings.setMissionReminderObjectId(mission.objectId);

    await _plugin.cancel(id: _comebackNotificationId);
    await _plugin.zonedSchedule(
      id: _comebackNotificationId,
      title: mission.notificationTitle,
      body: mission.notificationBody,
      scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
      notificationDetails: _notificationDetails(),
      payload: '$_payloadPrefix${mission.objectId}',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelComebackReminder() =>
      _plugin.cancel(id: _comebackNotificationId);

  @visibleForTesting
  String? objectIdFromPayload(String? payload) => _objectIdFromPayload(payload);

  void _handleNotificationResponse(NotificationResponse response) {
    final objectId = _objectIdFromPayload(response.payload);
    if (objectId != null) _openMission(objectId);
  }

  void _openMission(String objectId) {
    final validId = heroById(objectId) == null ? 'paper_cup' : objectId;
    _onOpenMission?.call(validId);
  }

  String? _objectIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith(_payloadPrefix)) return null;
    final objectId = payload.substring(_payloadPrefix.length).trim();
    if (heroById(objectId) == null) return 'paper_cup';
    return objectId;
  }

  String _nextMissionObjectId() {
    final today = vnNow();
    final index =
        (today.year * 372 + today.month * 31 + today.day) % heroCatalog.length;
    return heroCatalog[index].id;
  }

  void _initTimezone() {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (e) {
      debugPrint('timezone init error: $e');
    }
  }

  NotificationDetails _notificationDetails() => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(
      threadIdentifier: 'wonderlens_missions',
      presentAlert: true,
      presentSound: true,
    ),
  );
}
