import 'package:flutter/widgets.dart';
import '../models/error_entry.dart';

/// Abstract builder for individual error box card UI
/// 
/// Apps can implement this interface to customize how individual
/// error entries are displayed in the error box.
abstract class ErrorBoxCardBuilder {
  const ErrorBoxCardBuilder();
  
  /// Build a widget for displaying an individual error entry
  /// 
  /// [context] - Build context
  /// [error] - The error box entry to display
  /// [onSend] - Callback when user chooses to send this error
  /// [onDelete] - Callback when user chooses to delete this error
  Widget build(
    BuildContext context,
    ErrorBoxEntry error, {
    required VoidCallback onSend,
    required VoidCallback onDelete,
  });
}