import 'package:flutter/widgets.dart';

/// Abstract builder for error box page UI
/// 
/// Apps must implement this interface to provide their own error box page
/// that matches their design system.
abstract class ErrorBoxPageBuilder {
  const ErrorBoxPageBuilder();
  
  /// Build the error box page widget
  /// 
  /// The implementation should use [ErrorBoxPageCubit] to manage state
  /// and display the list of unsent errors with send/delete actions.
  Widget build(BuildContext context);
}