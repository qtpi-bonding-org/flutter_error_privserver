import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../models/error_entry.dart';
import '../storage/error_box_storage.dart';

/// Configuration for flutter_error_privserver library.
///
/// The library handles error capture and local storage only.
/// UI (pages, toasts, dialogs) is the app's responsibility.
class ErrorPrivserverConfig {
  const ErrorPrivserverConfig({
    required this.storage,
    required this.reporter,
    required this.errorCodeMapper,
    required this.exceptionMapper,
  });

  /// Storage implementation for error box entries.
  final ErrorBoxStorage storage;

  /// Function to send error entries to server.
  final Future<bool> Function(ErrorEntry) reporter;

  /// Function to map exceptions to safe error codes.
  final String Function(Object error) errorCodeMapper;

  /// Function to map exceptions to user-friendly messages (from cubit_ui_flow).
  final MessageKey? Function(Object error) exceptionMapper;
}
