import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../config/error_privserver_config.dart';
import '../models/error_entry.dart';

/// Mixin that adds privacy-preserving error capture to any [TryOperationCubit].
///
/// Hooks [TryOperationCubit.onOperationError] rather than re-implementing
/// [TryOperationCubit.tryOperation]'s try/catch/emit control flow — the
/// error state has already been emitted by the time this mixin sees the
/// error; it only adds the capture side effect on top.
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
mixin ErrorPrivserverMixin<S extends IUiFlowState> on TryOperationCubit<S> {
  static ErrorPrivserverConfig? _config;

  /// Configure the error privacy server.
  ///
  /// Must be called before using any Cubits with ErrorPrivserverMixin.
  static void configure(ErrorPrivserverConfig config) {
    _config = config;
  }

  /// Get the current configuration.
  static ErrorPrivserverConfig? get config => _config;

  @override
  void onOperationError(Object error, StackTrace stackTrace) {
    super.onOperationError(error, stackTrace);
    unawaited(_captureError(error, stackTrace));
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
