import 'package:flutter_test/flutter_test.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/features/notifications/domain/usecases/deferred_queue_usecase.dart';
import 'package:timefocus/shared/enums/notification_type.dart';

NotificationDraft draft(NotificationType type) =>
    NotificationDraft(type: type, scheduledAt: DateTime(2026, 7, 18), title: 't', body: 'b');

void main() {
  group('shouldDeferNotification (FR-034a/FR-037)', () {
    test('neither muted nor Pomodoro-active → never deferred', () {
      for (final type in NotificationType.values) {
        expect(
          shouldDeferNotification(type, pomodoroActive: false, muted: false),
          isFalse,
          reason: type.name,
        );
      }
    });

    test('muted defers every type — a blanket suppression, not just the Pomodoro list', () {
      for (final type in NotificationType.values) {
        expect(
          shouldDeferNotification(type, pomodoroActive: false, muted: true),
          isTrue,
          reason: type.name,
        );
      }
    });

    test('Pomodoro-active only defers mealFlexible/waterReminder/sleepReminder', () {
      for (final type in pomodoroDeferredTypes) {
        expect(
          shouldDeferNotification(type, pomodoroActive: true, muted: false),
          isTrue,
          reason: type.name,
        );
      }
      final untouched = NotificationType.values.toSet().difference(pomodoroDeferredTypes);
      for (final type in untouched) {
        expect(
          shouldDeferNotification(type, pomodoroActive: true, muted: false),
          isFalse,
          reason: type.name,
        );
      }
    });
  });

  group('DeferredQueueUseCase', () {
    test('enqueue then drain returns items in order and empties the queue', () {
      final useCase = DeferredQueueUseCase();
      expect(useCase.isEmpty, isTrue);

      final water = draft(NotificationType.waterReminder);
      final sleep = draft(NotificationType.sleepReminder);
      useCase
        ..enqueue(water)
        ..enqueue(sleep);
      expect(useCase.isEmpty, isFalse);

      expect(useCase.drain(), [water, sleep]);
      expect(useCase.isEmpty, isTrue);
      expect(useCase.drain(), isEmpty);
    });
  });
}
