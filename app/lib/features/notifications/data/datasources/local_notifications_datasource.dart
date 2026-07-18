import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around flutter_local_notifications: init, exact scheduling
/// with inexact fallback (FR-036), tap stream, cold start details.
@lazySingleton
class LocalNotificationsDataSource {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  final StreamController<NotificationResponse> _taps = StreamController.broadcast();

  /// Warm-start notification taps and action buttons.
  Stream<NotificationResponse> get taps => _taps.stream;

  static const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    'timefocus_main',
    'TimeFocus',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const DarwinNotificationDetails _darwinDetails = DarwinNotificationDetails();

  static const NotificationDetails details = NotificationDetails(
    android: _androidDetails,
    iOS: _darwinDetails,
  );

  Future<void> init() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _taps.add,
    );
  }

  /// Payload that launched the app from terminated state, if any.
  Future<NotificationResponse?> launchDetails() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details?.notificationResponse;
    }
    return null;
  }

  /// Schedules exact with fallback to inexact when exact alarms are not
  /// permitted (FR-036).
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    final when = tz.TZDateTime.from(scheduledAt, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } on Exception catch (e) {
      logger.w('exact schedule failed, falling back to inexact', error: e);
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) => _plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: details,
    payload: payload,
  );

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelAll() => _plugin.cancelAll();
}
