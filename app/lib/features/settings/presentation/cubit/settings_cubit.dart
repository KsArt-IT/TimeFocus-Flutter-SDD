import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/settings/presentation/cubit/settings_state.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';

export 'package:timefocus/features/settings/presentation/cubit/settings_state.dart';

/// ActionsSettingsPage's cubit (T076/T081): every activity (archived or
/// not), archive/unarchive, delete (user activities only — FR-043).
@injectable
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._actions) : super(const SettingsState.loading()) {
    _subscription = _actions.watchAll().listen(
      (all) => emit(SettingsState.loaded(all)),
      onError: (Object e) =>
          emit(SettingsState.error(e is AppFailure ? e : UnknownFailure(e.toString()))),
    );
  }

  final ActionNameRepository _actions;
  StreamSubscription<List<ActionNameEntity>>? _subscription;

  Future<void> setArchived(int id, {required bool archived}) async {
    final result = await _actions.setArchived(id, archived: archived);
    if (result.isFailure) {
      logger.e('failed to change archived state', error: result.errorOrNull);
    }
  }

  Future<void> delete(int id) async {
    final result = await _actions.delete(id);
    if (result.isFailure) {
      logger.e('failed to delete activity', error: result.errorOrNull);
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
