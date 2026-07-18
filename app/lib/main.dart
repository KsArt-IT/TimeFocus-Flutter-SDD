import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:timefocus/app/app_root.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/core/time_zone/time_zone.dart';
import 'package:timefocus/features/notifications/data/datasources/local_notifications_datasource.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      await TimeZones.initialize();

      await configureDependencies();
      await getIt<LocalNotificationsDataSource>().init();

      runApp(const AppRoot());
    },
    (error, stack) {
      if (kDebugMode) {
        log('Zone error: $error', name: 'ZoneError', stackTrace: stack);
      }
    },
  );
}
