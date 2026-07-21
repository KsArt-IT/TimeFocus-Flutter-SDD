import 'package:freezed_annotation/freezed_annotation.dart';

part 'water_log_entity.freezed.dart';

/// One drink log entry — schedule timeline points and the history "Water"
/// mode list share this shape.
@freezed
abstract class WaterLogEntity with _$WaterLogEntity {
  const factory WaterLogEntity({
    required int id,
    required int volume,
    required DateTime createdAt,
  }) = _WaterLogEntity;
}
