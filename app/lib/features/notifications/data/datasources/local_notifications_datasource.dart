import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/notifications/domain/usecases/handle_notification_tap_usecase.dart';
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around flutter_local_notifications: init, exact scheduling
/// with inexact fallback (FR-036), tap stream, cold start details.
@lazySingleton
class LocalNotificationsDataSource {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  final StreamController<NotificationResponse> _taps = StreamController.broadcast();

  /// Warm-start notification taps and action buttons.
  Stream<NotificationResponse> get taps => _taps.stream;

  /// iOS category for breakFinished, carrying the extendBreak action button.
  static const String breakFinishedCategoryId = 'breakFinished';

  Future<void> init() async {
    final initSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        notificationCategories: [
          DarwinNotificationCategory(
            breakFinishedCategoryId,
            actions: [
              // iOS categories are registered once at init and can't carry a
              // per-notification localized/minute-count label like Android's
              // AndroidNotificationAction does; kept static.
              DarwinNotificationAction.plain(
                extendBreakActionId,
                'Extend break',
                options: {DarwinNotificationActionOption.foreground},
              ),
            ],
          ),
        ],
      ),
    );
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _taps.add,
    );
  }

  NotificationDetails _detailsFor({
    List<AndroidNotificationAction> actions = const [],
    String? darwinCategoryId,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      'timefocus_main',
      'TimeFocus',
      importance: Importance.high,
      priority: Priority.high,
      actions: actions,
    ),
    // Explicit per-notification presentation flags (rather than relying on
    // DarwinInitializationSettings.defaultPresent*) so the banner also shows
    // while the app is foregrounded, not only when backgrounded.
    iOS: DarwinNotificationDetails(
      categoryIdentifier: darwinCategoryId,
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.active,
    ),
  );

  /// Payload that launched the app from terminated state, if any.
  Future<NotificationResponse?> launchDetails() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details?.notificationResponse;
    }
    return null;
  }

  /// Schedules exact with fallback to inexact when exact alarms are not
  /// permitted (FR-036). [extendBreakLabel] adds the localized extendBreak
  /// button (breakFinished only, T061).
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
    String? extendBreakLabel,
  }) async {
    final when = tz.TZDateTime.from(scheduledAt, tz.local);
    final details = _detailsFor(
      actions: extendBreakLabel == null
          ? const []
          : [AndroidNotificationAction(extendBreakActionId, extendBreakLabel)],
      darwinCategoryId: extendBreakLabel == null ? null : breakFinishedCategoryId,
    );
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
    notificationDetails: _detailsFor(),
    payload: payload,
  );

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelAll() => _plugin.cancelAll();
}
