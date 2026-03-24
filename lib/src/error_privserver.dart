import 'package:flutter/foundation.dart';

import 'config/error_privserver_config.dart';
import 'cubits/error_privserver_cubit.dart';
import 'models/error_entry.dart';

/// Convenience API for flutter_error_privserver.
///
/// Provides static methods for configuration and send-only operations.
/// Storage management (marking as sent, deleting) is the app's responsibility.
class ErrorPrivserver {
  /// Configure the error privacy server.
  ///
  /// Must be called before using any Cubits with ErrorPrivserverMixin.
  ///
  /// ```dart
  /// ErrorPrivserver.configure(ErrorPrivserverConfig(
  ///   storage: myErrorBoxStorage,
  ///   reporter: (errorEntry) => myClient.sendError(errorEntry),
  ///   errorCodeMapper: ErrorCodeMapper.mapError,
  ///   exceptionMapper: myExceptionMapper.map,
  /// ));
  /// ```
  static void configure(ErrorPrivserverConfig config) {
    ErrorPrivserverMixin.configure(config);
  }

  /// Whether the library has been configured.
  static bool get isConfigured => ErrorPrivserverMixin.config != null;

  /// Get the count of unsent errors.
  ///
  /// Returns 0 if not configured.
  static Future<int> getUnsentCount() async {
    final config = ErrorPrivserverMixin.config;
    if (config == null) return 0;
    return await config.storage.getUnsentCount();
  }

  /// Get all unsent errors.
  ///
  /// Returns empty list if not configured.
  static Future<List<ErrorBoxEntry>> getUnsentErrors() async {
    final config = ErrorPrivserverMixin.config;
    if (config == null) return [];
    return await config.storage.getUnsentErrors();
  }

  /// Send a specific error to the server (send only, does not mark as sent).
  ///
  /// Returns true if the report was sent successfully.
  static Future<bool> sendError(String errorId) async {
    final config = ErrorPrivserverMixin.config;
    if (config == null) return false;

    final errorBoxEntry = await config.storage.getErrorById(errorId);
    if (errorBoxEntry == null) return false;

    return await config.reporter(errorBoxEntry.errorData);
  }

  /// Capture an error from non-cubit code (services, repositories, background workers).
  ///
  /// Stores the error in the Error Box for developer review without triggering
  /// any UI state change or toast. This is the service-layer equivalent of
  /// [ErrorPrivserverMixin]'s automatic capture in cubits.
  ///
  /// No-op if not configured. Never throws — error capture must never crash the app.
  ///
  /// ```dart
  /// } catch (e, stack) {
  ///   debugPrint('E2EEPuller: decryption failed: $e');
  ///   await ErrorPrivserver.captureError(e, stack, source: 'E2EEPuller');
  /// }
  /// ```
  static Future<void> captureError(
    Object error,
    StackTrace stackTrace, {
    required String source,
  }) async {
    final config = ErrorPrivserverMixin.config;
    if (config == null) return;

    try {
      final messageKey = config.exceptionMapper(error);
      final errorCode = config.errorCodeMapper(error);

      final errorEntry = ErrorEntry(
        source: source,
        errorType: error.runtimeType.toString(),
        errorCode: errorCode,
        stackTrace: stackTrace.toString(),
        timestamp: DateTime.now(),
        userMessage: messageKey?.key,
      );

      await config.storage.saveError(errorEntry);
    } catch (e) {
      debugPrint('ErrorPrivserver: Failed to capture error: $e');
    }
  }

  /// Send all unsent errors to the server (send only, does not mark as sent).
  ///
  /// Returns the list of error IDs that were successfully sent.
  /// Stops on first failure (server likely unreachable).
  static Future<List<String>> sendAllErrors() async {
    final errors = await getUnsentErrors();
    final sentIds = <String>[];

    for (final error in errors) {
      try {
        final success = await sendError(error.id);
        if (success) {
          sentIds.add(error.id);
        } else {
          break;
        }
      } catch (e) {
        debugPrint('ErrorPrivserver: Failed to send error ${error.id}: $e');
        break;
      }
    }

    return sentIds;
  }
}
