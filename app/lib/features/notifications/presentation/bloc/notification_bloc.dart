import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/notifications/data/datasources/local_notifications_datasource.dart';
import 'package:timefocus/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:timefocus/features/notifications/domain/usecases/handle_notification_tap_usecase.dart';
import 'package:timefocus/features/notifications/presentation/bloc/notification_event.dart';
import 'package:timefocus/features/notifications/presentation/bloc/notification_state.dart';

export 'package:timefocus/features/notifications/presentation/bloc/notification_event.dart';
export 'package:timefocus/features/notifications/presentation/bloc/notification_state.dart';

/// Global bloc (contracts/blocs.md): cold-start launch details, warm taps,
/// rescheduleAll on start (FR-035a), and flushing the deferred queue when
/// Pomodoro ends or a mute lifts (FR-034a). Dispatches intents for
/// RootBlocListener to act on — never imports another Bloc.
@lazySingleton
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc(this._local, this._scheduler, this._handleTap)
    : super(const NotificationState()) {
    on<NotificationsInitialized>(_onInitialized, transformer: droppable());
    on<NotificationTapped>(_onTapped, transformer: sequential());
    on<ScheduleRecalculated>(_onScheduleRecalculated, transformer: sequential());
    on<NotificationIntentHandled>(_onIntentHandled, transformer: sequential());

    _tapsSub = _local.taps.listen(
      (response) => add(
        NotificationEvent.tapped(payload: response.payload, actionId: response.actionId),
      ),
    );
  }

  final LocalNotificationsDataSource _local;
  final NotificationScheduler _scheduler;
  final HandleNotificationTapUseCase _handleTap;
  StreamSubscription<NotificationResponse>? _tapsSub;

  Future<void> _onInitialized(
    NotificationsInitialized event,
    Emitter<NotificationState> emit,
  ) async {
    final launch = await _local.launchDetails();
    if (isClosed) return;
    if (launch != null) {
      final intent = _handleTap(payloadJson: launch.payload, actionId: launch.actionId);
      emit(state.copyWith(pendingIntent: intent));
    }
    final result = await _scheduler.rescheduleAll();
    if (result.isFailure) logger.e('rescheduleAll failed', error: result.errorOrNull);
  }

  void _onTapped(NotificationTapped event, Emitter<NotificationState> emit) {
    final intent = _handleTap(payloadJson: event.payload, actionId: event.actionId);
    emit(state.copyWith(pendingIntent: intent));
  }

  Future<void> _onScheduleRecalculated(
    ScheduleRecalculated event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _scheduler.flushDeferred();
    if (result.isFailure) logger.e('flushDeferred failed', error: result.errorOrNull);
  }

  void _onIntentHandled(NotificationIntentHandled event, Emitter<NotificationState> emit) {
    emit(state.copyWith(pendingIntent: null));
  }

  @override
  Future<void> close() async {
    await _tapsSub?.cancel();
    return super.close();
  }
}
