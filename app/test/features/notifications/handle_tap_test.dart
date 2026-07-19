import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_intent.dart';
import 'package:timefocus/features/notifications/domain/usecases/handle_notification_tap_usecase.dart';
import 'package:timefocus/shared/enums/notification_type.dart';

String payloadFor(NotificationType type, Map<String, Object?> extra) =>
    jsonEncode({'type': type.index, 'title': '', 'body': '', ...extra});

void main() {
  final useCase = HandleNotificationTapUseCase();

  group('extendBreak action button', () {
    test('takes priority over the payload type', () {
      final intent = useCase(
        payloadJson: payloadFor(NotificationType.breakFinished, {'parentActionId': 1}),
        actionId: extendBreakActionId,
      );
      expect(intent, const NotificationIntent.extendBreak(AppConstants.extendBreakMinutes));
    });
  });

  group('FR-035 stale/undecodable payload → openTracker, no crash', () {
    test('null payload', () {
      expect(useCase(), const NotificationIntent.openTracker());
    });

    test('malformed JSON', () {
      expect(useCase(payloadJson: '{not json'), const NotificationIntent.openTracker());
    });

    test('missing type field', () {
      expect(
        useCase(payloadJson: jsonEncode({'foo': 'bar'})),
        const NotificationIntent.openTracker(),
      );
    });
  });

  group('all 9 notification types', () {
    test('pomodoroFinished → openTracker', () {
      final intent = useCase(
        payloadJson: payloadFor(NotificationType.pomodoroFinished, {
          'actionId': 1,
          'breakActionId': 2,
        }),
      );
      expect(intent, const NotificationIntent.openTracker());
    });

    test('breakFinished → resumeWork(parentActionId)', () {
      final intent = useCase(
        payloadJson: payloadFor(NotificationType.breakFinished, {
          'parentActionId': 7,
          'pomodoroCount': 2,
        }),
      );
      expect(intent, const NotificationIntent.resumeWork(7));
    });

    test('breakFinished without a usable parentActionId → openTracker', () {
      final intent = useCase(
        payloadJson: payloadFor(NotificationType.breakFinished, {'parentActionId': null}),
      );
      expect(intent, const NotificationIntent.openTracker());
    });

    test('mealFlexible with targetActionId → startAction (tap-confirmed, FR-031)', () {
      final intent = useCase(
        payloadJson: payloadFor(NotificationType.mealFlexible, {
          'scheduleEventId': 1,
          'targetActionId': 9,
        }),
      );
      expect(intent, const NotificationIntent.startAction(9));
    });

    test('mealFlexible without a linked activity → openTracker', () {
      final intent = useCase(
        payloadJson: payloadFor(NotificationType.mealFlexible, {
          'scheduleEventId': 1,
          'targetActionId': null,
        }),
      );
      expect(intent, const NotificationIntent.openTracker());
    });

    test('mealStrict with targetActionId → startAction (tap-confirmed, FR-031)', () {
      final intent = useCase(
        payloadJson: payloadFor(NotificationType.mealStrict, {
          'scheduleEventId': 1,
          'targetActionId': 4,
        }),
      );
      expect(intent, const NotificationIntent.startAction(4));
    });

    test('mealStrictWarning → openTracker', () {
      final intent = useCase(
        payloadJson: payloadFor(NotificationType.mealStrictWarning, {
          'scheduleEventId': 1,
          'minutesUntilEvent': 5,
          'currentPomodoroEndAt': DateTime(2026).toIso8601String(),
        }),
      );
      expect(intent, const NotificationIntent.openTracker());
    });

    test('waterReminder → openTracker', () {
      final intent = useCase(
        payloadJson: payloadFor(NotificationType.waterReminder, {
          'currentMl': 500,
          'goalMl': 2000,
          'recommendedGlasses': 2,
        }),
      );
      expect(intent, const NotificationIntent.openTracker());
    });

    test('toiletReminder → openTracker', () {
      final intent = useCase(payloadJson: payloadFor(NotificationType.toiletReminder, {}));
      expect(intent, const NotificationIntent.openTracker());
    });

    test('sleepReminder → openTracker', () {
      final intent = useCase(
        payloadJson: payloadFor(NotificationType.sleepReminder, {'sleepTimeMinutes': 1380}),
      );
      expect(intent, const NotificationIntent.openTracker());
    });
  });
}
