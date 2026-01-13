import 'package:flutter/widgets.dart';

import 'config/error_privserver_config.dart';
import 'cubits/error_privserver_cubit.dart';
import 'models/error_entry.dart';

/// Convenience class for easy setup and usage of flutter_error_privserver
class ErrorPrivserver {
  /// Configure the error privacy server
  /// 
  /// This must be called before using any Cubits with ErrorPrivserverMixin.
  /// 
  /// Example:
  /// ```dart
  /// ErrorPrivserver.configure(ErrorPrivserverConfig(
  ///   storage: SharedPrefsErrorBoxStorage(),
  ///   reporter: (errorEntry) => myClient.sendError(errorEntry),
  ///   errorCodeMapper: ErrorCodeMapper.mapError,
  ///   exceptionMapper: myExceptionMapper.map,
  ///   toastBuilder: MyErrorToastBuilder(),
  ///   pageBuilder: MyErrorBoxPageBuilder(),
  /// ));
  /// ```
  static void configure(ErrorPrivserverConfig config) {
    ErrorPrivserverMixin.configure(config);
  }
  
  /// Build the error box page widget
  /// 
  /// Returns the configured error box page for displaying unsent errors.
  /// Throws [StateError] if not configured.
  static Widget page(BuildContext context) {
    final config = ErrorPrivserverMixin.config;
    if (config == null) {
      throw StateError('ErrorPrivserver not configured. Call ErrorPrivserver.configure() first.');
    }
    return config.pageBuilder.build(context);
  }
  
  /// Get the count of unsent errors
  /// 
  /// Returns 0 if not configured.
  static Future<int> getUnsentCount() async {
    final config = ErrorPrivserverMixin.config;
    if (config == null) return 0;
    return await config.storage.getUnsentCount();
  }
  
  /// Get all unsent errors
  /// 
  /// Returns empty list if not configured.
  static Future<List<ErrorBoxEntry>> getUnsentErrors() async {
    final config = ErrorPrivserverMixin.config;
    if (config == null) return [];
    return await config.storage.getUnsentErrors();
  }
  
  /// Send a specific error to the server
  /// 
  /// Marks the error as sent after successful transmission.
  static Future<void> sendError(String errorId) async {
    final config = ErrorPrivserverMixin.config;
    if (config == null) return;
    
    final errorBoxEntry = await config.storage.getErrorById(errorId);
    if (errorBoxEntry == null) return;
    
    await config.reporter(errorBoxEntry.errorData);
    await config.storage.markAsSent(errorId);
  }
  
  /// Delete a specific error from storage
  static Future<void> deleteError(String errorId) async {
    final config = ErrorPrivserverMixin.config;
    if (config == null) return;
    
    await config.storage.deleteError(errorId);
  }
  
  /// Send all unsent errors to the server
  /// 
  /// Processes each error individually and marks them as sent.
  static Future<void> sendAllErrors() async {
    final errors = await getUnsentErrors();
    for (final error in errors) {
      try {
        await sendError(error.id);
      } catch (e) {
        // Continue with other errors even if one fails
        debugPrint('Failed to send error ${error.id}: $e');
      }
    }
  }
  
  /// Check if the library is configured
  static bool get isConfigured => ErrorPrivserverMixin.config != null;
}