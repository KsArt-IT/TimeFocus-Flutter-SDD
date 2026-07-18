import 'package:injectable/injectable.dart';

import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/tracker/domain/usecases/start_action_usecase.dart';

/// Resume goes through the same transition matrix as start (FR-010).
@injectable
class ResumeActionUseCase {
  ResumeActionUseCase(this._start);

  final StartActionUseCase _start;

  Future<Result<StartActionOutcome>> call(
    int actionNameId, {
    ActionStartSource source = ActionStartSource.user,
    bool confirmed = false,
    DateTime? now,
  }) => _start(actionNameId, source: source, confirmed: confirmed, now: now);
}
