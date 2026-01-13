import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/error_privserver_config.dart';
import '../models/error_entry.dart';

/// Mixin that adds privacy-preserving error capture to any Cubit
/// 
/// This mixin can be applied to any Cubit that uses IUiFlowState to automatically
/// capture errors and store them locally for user review. No data is sent to 
/// servers without explicit user consent.
/// 
/// Privacy is ensured by only capturing:
/// - Error types (e.g., "NetworkException")
/// - Cubit class names (e.g., "AccountCubit") 
/// - Full stack traces (for debugging)
/// - Mapped error codes (e.g., "NET_001")
/// - Optional user messages (from IExceptionKeyMapper)
/// 
/// Function arguments, user input, and other sensitive data are never captured.
/// 
/// Usage:
/// ```dart
/// class MyCubit extends TryOperationCubit<MyState> with ErrorPrivserverMixin<MyState> {
///   MyCubit() : super(MyState.initial());
/// }
/// 
/// // Or with any other cubit base class:
/// class MyHydratedCubit extends HydratedCubit<MyState> with ErrorPrivserverMixin<MyState> {
///   MyHydratedCubit() : super(MyState.initial());
/// }
/// ```
mixin ErrorPrivserverMixin<S extends IUiFlowState> on Cubit<S> {
  static ErrorPrivserverConfig? _config;
  
  /// Configure the error privacy server
  /// 
  /// This must be called before using any Cubits with ErrorPrivserverMixin.
  static void configure(ErrorPrivserverConfig config) {
    _config = config;
  }
  
  /// Get the current configuration (for internal use)
  static ErrorPrivserverConfig? get config => _config;
  
  /// Enhanced tryOperation with automatic error capture
  /// 
  /// This method provides the same functionality as TryOperationCubit.tryOperation
  /// but adds privacy-preserving error capture.
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
      // Create error state
      final errorState = _createErrorState(error);
      emit(errorState);
      
      // Capture error for privacy-preserving storage
      await _captureError(error, stackTrace);
    }
  }
  
  /// Creates loading state from current state.
  /// Uses dynamic copyWith pattern for compatibility with Freezed states.
  S _createLoadingState() {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.loading,
      error: null,
    ) as S;
  }

  /// Creates error state from current state and error.
  /// Uses dynamic copyWith pattern for compatibility with Freezed states.
  S _createErrorState(Object error) {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.failure,
      error: error,
    ) as S;
  }
  
  Future<void> _captureError(Object error, StackTrace? stackTrace) async {
    if (_config == null) return; // Not configured, skip capture
    
    try {
      // Get user-friendly message using existing cubit_ui_flow pattern
      final messageKey = _config!.exceptionMapper(error);
      final userMessage = messageKey?.key; // Optional: what user sees
      
      // Map to safe error code (privacy-preserving)
      final errorCode = _config!.errorCodeMapper(error);
      
      // Create privacy-preserving error entry
      final errorEntry = ErrorEntry(
        source: runtimeType.toString(),                    // "AccountCubit" - safe by design
        errorType: error.runtimeType.toString(),           // "NetworkException" - safe by design  
        errorCode: errorCode,                              // "NET_001" - mapped safe code
        stackTrace: stackTrace?.toString() ?? 'No stack trace available', // FULL raw stack trace - no truncation
        timestamp: DateTime.now(),
        userMessage: userMessage,                          // Optional: "Network error occurred"
      );
      
      // Save to local storage with deduplication
      await _config!.storage.saveError(errorEntry);
      
      // Note: Toast functionality removed since it requires BuildContext
      // Apps should handle error display in their UI layer
      
    } catch (e) {
      // Never let error reporting break the app
      debugPrint('ErrorPrivserverMixin: Failed to capture error: $e');
    }
  }
}

/// Enhanced cubit that extends TryOperationCubit with privacy-preserving error capture
/// 
/// This is provided for convenience, but using the mixin is recommended for flexibility.
/// 
/// @deprecated Use ErrorPrivserverMixin instead for better flexibility
abstract class ErrorPrivserverCubit<S extends IUiFlowState> extends TryOperationCubit<S> with ErrorPrivserverMixin<S> {
  ErrorPrivserverCubit(super.initialState);
  
  /// Configure the error privacy server
  /// 
  /// This must be called before using any ErrorPrivserverCubit instances.
  static void configure(ErrorPrivserverConfig config) {
    ErrorPrivserverMixin.configure(config);
  }
  
  /// Get the current configuration (for internal use)
  static ErrorPrivserverConfig? get config => ErrorPrivserverMixin.config;
}