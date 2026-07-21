import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/water/domain/repositories/water_repository.dart';
import 'package:timefocus/features/water/presentation/cubit/water_log_edit_state.dart';

export 'package:timefocus/features/water/presentation/cubit/water_log_edit_state.dart';

/// Screen-scoped cubit for WaterLogEditPage: edit or delete a single drink
/// log entry's time/amount (History screen's water mode).
@injectable
class WaterLogEditCubit extends Cubit<WaterLogEditState> {
  WaterLogEditCubit(this._water) : super(const WaterLogEditState.loading());

  final WaterRepository _water;

  Future<void> load(int id) async {
    final result = await _water.getLog(id);
    if (isClosed) return;
    final log = result.valueOrNull;
    if (log == null) {
      emit(WaterLogEditState.error(result.errorOrNull!));
      return;
    }
    emit(WaterLogEditState.loaded(log: log));
  }

  Future<void> save({required int id, required int volume, required DateTime createdAt}) async {
    final result = await _water.updateLog(id: id, volume: volume, createdAt: createdAt);
    if (isClosed) return;
    if (result.isFailure) {
      logger.e('failed to update water log', error: result.errorOrNull);
    }
  }

  Future<void> deleteLog(int id) async {
    final result = await _water.deleteLog(id);
    if (isClosed) return;
    if (result.isFailure) {
      logger.e('failed to delete water log', error: result.errorOrNull);
    }
  }
}
