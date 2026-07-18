import 'package:timefocus/gen/app_localizations.dart';

/// Base exception class for the application
sealed class AppFailure implements Exception {
  const AppFailure(this.message, [this.code]);

  final String message;
  final String? code;

  String localizedMessage(AppLocalizations locale) {
    return message;
  }

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Unknown error
class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, [super.code]);
}

/// Platform related exceptions
class PlatformFailure extends AppFailure {
  const PlatformFailure(super.message, [super.code]);
}

/// Initialization related exceptions
class InitializationFailure extends AppFailure {
  const InitializationFailure(super.message, [super.code]);
}

/// Network related exceptions
class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, [super.code]);
}

/// Validation related exceptions
class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, [super.code]);
}

/// Settings related exceptions
class SettingsFailure extends AppFailure {
  const SettingsFailure(super.message, [super.code]);
}

/// Action exceptions
class ActionFailure extends AppFailure {
  const ActionFailure(super.message, [super.code]);
}

/// Action exceptions
class PomodoroFailure extends AppFailure {
  const PomodoroFailure(super.message, [super.code]);
}

/// Database related exceptions
class DatabaseFailure extends AppFailure {
  const DatabaseFailure(String? message, {String? code}) : super(message ?? '', code);

  static const uniqueViolation = 'unique_violation';
  static const entityNotFound = 'entity_not_found';
  static const savingError = 'saving_error';

  @override
  String localizedMessage(AppLocalizations locale) => switch (code) {
    uniqueViolation => locale.uniqueViolation,
    entityNotFound => locale.entityNotFound,
    _ => message,
  };
}

/// Schedule related exceptions
class ScheduleFailure extends AppFailure {
  const ScheduleFailure(super.message, [super.code]);
}

/// Water related exceptions
class WaterFailure extends AppFailure {
  const WaterFailure(super.message, [super.code]);
}

/// Notification related exceptions
class NotificationFailure extends AppFailure {
  const NotificationFailure(String? message, {String? code}) : super(message ?? '', code);

  static const notFound = 'not_found';
  static const notLaunch = 'not_launch_details';

  @override
  String localizedMessage(AppLocalizations locale) => switch (code) {
    notFound => locale.notificationNotFound,
    _ => locale.notificationFailure(message),
  };
}
