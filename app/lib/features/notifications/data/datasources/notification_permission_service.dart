import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:timefocus/core/utils/app_logger.dart';

/// Requests notification permissions per Android SDK version:
/// SDK 33+ — POST_NOTIFICATIONS, SDK 31+ — SCHEDULE_EXACT_ALARM.
/// Refusal disables reminders; tracking keeps working (FR-036).
@lazySingleton
class NotificationPermissionService {
  /// Returns true when notifications are allowed.
  Future<bool> request() async {
    if (Platform.isIOS) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    if (!Platform.isAndroid) return true;

    final info = await DeviceInfoPlugin().androidInfo;
    final sdk = info.version.sdkInt;
    var granted = true;
    if (sdk >= 33) {
      final status = await Permission.notification.request();
      granted = status.isGranted;
    }
    if (sdk >= 31) {
      final exact = await Permission.scheduleExactAlarm.status;
      if (exact.isDenied) {
        final result = await Permission.scheduleExactAlarm.request();
        if (!result.isGranted) {
          logger.i('exact alarms denied — falling back to inexact scheduling');
        }
      }
    }
    return granted;
  }

  Future<bool> isGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
}
