import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../models/error_entry.dart';
import '../storage/error_box_storage.dart';
import '../builders/error_toast_builder.dart';
import '../builders/error_box_page_builder.dart';

/// Configuration for flutter_error_privserver library
class ErrorPrivserverConfig {
  const ErrorPrivserverConfig({
    required this.storage,
    required this.reporter,
    required this.errorCodeMapper,
    required this.exceptionMapper,
    this.showToast = true,
    required this.toastBuilder,
    required this.pageBuilder,
  });

  /// Storage implementation for error box entries
  final ErrorBoxStorage storage;
  
  /// Function to send error entries to server
  final Future<void> Function(ErrorEntry) reporter;
  
  /// Function to map exceptions to safe error codes
  final String Function(Object error) errorCodeMapper;
  
  /// Function to map exceptions to user-friendly messages (from cubit_ui_flow)
  final MessageKey? Function(Object error) exceptionMapper;
  
  /// Whether to show toast when errors occur
  final bool showToast;
  
  /// Builder for error toast UI
  final ErrorToastBuilder toastBuilder;
  
  /// Builder for error box page UI
  final ErrorBoxPageBuilder pageBuilder;
}