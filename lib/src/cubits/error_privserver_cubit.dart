import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/error_privserver_config.dart';
import '../models/error_entry.dart';

/// Mixin that adds privacy-preserving error capture to any Cubit.
///
/// Applied to any Cubit using IUiFlowState. Automatically captures errors
/// from [tryOperation] and stores them locally for user review. No data is
/// sent to servers without explicit user consent.
///
/// Privacy is ensured by only capturing:
/// - Error types (e.g., "NetworkException")
/// - Cubit class names (e.g., "AccountCubit")
/// - Full stack traces (for debugging)
/// - Mapped error codes (e.g., "NET_001")
/// - Optional user messages (from IExceptionKeyMapper)
///
/// Usage:
/// ```dart
/// class MyCubit extends TryOperationCubit<MyState> with ErrorPrivserverMixin<MyState> {
///   MyCubit() : super(MyState.initial());
/// }
/// ```
mixin ErrorPrivserverMixin<S extends IUiFlowState> on Cubit<S> {
  static ErrorPrivserverConfig? _config;

  /// Configure the error privacy server.
  ///
  /// Must be called before using any Cubits with ErrorPrivserverMixin.
  static void configure(ErrorPrivserverConfig config) {
    _config = config;
  }

  /// Get the current configuration.
  static ErrorPrivserverConfig? get config => _config;

  /// Enhanced tryOperation with automatic error capture.
  Future<void> tryOperation(
    FutureOr<S> Function() action, {
    bool emitLoading = false,
  }) async {
    try {
      if (emitLoading) {
        emit(_createLoadingState());
      }
      final successState = await action();
      emit(successState);
    } catch (error, stackTrace) {
      final errorState = _createErrorState(error);
      emit(errorState);
      await _captureError(error, stackTrace);
    }
  }

  S _createLoadingState() {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.loading,
      error: null,
    ) as S;
  }

  S _createErrorState(Object error) {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.failure,
      error: error,
    ) as S;
  }

  Future<void> _captureError(Object error, StackTrace? stackTrace) async {
    if (_config == null) return;

    try {
      final messageKey = _config!.exceptionMapper(error);
      final userMessage = messageKey?.key;
      final errorCode = _config!.errorCodeMapper(error);

      final errorEntry = ErrorEntry(
        source: runtimeType.toString(),
        errorType: error.runtimeType.toString(),
        errorCode: errorCode,
        stackTrace: stackTrace?.toString() ?? 'No stack trace available',
        timestamp: DateTime.now(),
        userMessage: userMessage,
      );

      await _config!.storage.saveError(errorEntry);
    } catch (e) {
      debugPrint('ErrorPrivserverMixin: Failed to capture error: $e');
    }
  }
}
