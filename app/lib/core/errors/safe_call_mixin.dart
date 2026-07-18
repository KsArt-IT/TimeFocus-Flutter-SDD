import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/result/result.dart';

mixin SafeCallMixin {
  Future<Result<T>> safeCall<T>(AsyncValueGetter<T> invoke) async {
    try {
      final value = await invoke();
      return success(value);
    } catch (e) {
      return failure(_handleError(e));
    }
  }

  Future<Result<void>> voidSafeCall(AsyncCallback invoke) async {
    try {
      await invoke();
      return success(null);
    } catch (e) {
      return failure(_handleError(e));
    }
  }

  AppFailure _handleError(Object e) {
    switch (e) {
      case PlatformException(:final code, :final message):
        log('code: $code, message: $message', name: 'PlatformException');
        return PlatformFailure(message ?? e.toString(), code);

      case AppFailure():
        log(e.toString(), name: 'AppError');
        return e;

      default:
        log(e.toString(), name: 'UnknownError');
        return UnknownFailure(e.toString());
    }
  }
}
