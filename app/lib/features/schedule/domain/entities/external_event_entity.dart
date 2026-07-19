import 'package:freezed_annotation/freezed_annotation.dart';

part 'external_event_entity.freezed.dart';

/// System calendar event (FR-033 extension point — Phase 2, not implemented).
@freezed
abstract class ExternalEventEntity with _$ExternalEventEntity {
  const factory ExternalEventEntity({
    required String id,
    required String title,
    required DateTime start,
    required DateTime end,
  }) = _ExternalEventEntity;
}
