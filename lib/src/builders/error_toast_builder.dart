import 'package:flutter/widgets.dart';

/// Abstract builder for error toast UI
/// 
/// Apps must implement this interface to provide their own toast UI
/// that matches their design system.
abstract class ErrorToastBuilder {
  const ErrorToastBuilder();
  
  /// Show an error toast with Send/Dismiss options
  /// 
  /// [context] - Build context for showing the toast
  /// [message] - User-friendly error message to display
  /// [onDismiss] - Callback when user dismisses the toast
  /// [onSend] - Callback when user chooses to send the error report
  void show(
    BuildContext context,
    String message, {
    required VoidCallback onDismiss,
    required VoidCallback onSend,
  });
}