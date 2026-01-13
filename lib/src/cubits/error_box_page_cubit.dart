import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/error_entry.dart';
import 'error_privserver_cubit.dart';

/// State for error box page
class ErrorBoxPageState {
  const ErrorBoxPageState({
    this.unsentErrors = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ErrorBoxEntry> unsentErrors;
  final bool isLoading;
  final String? error;
  
  ErrorBoxPageState copyWith({
    List<ErrorBoxEntry>? unsentErrors,
    bool? isLoading,
    String? error,
  }) {
    return ErrorBoxPageState(
      unsentErrors: unsentErrors ?? this.unsentErrors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
  
  @override
  String toString() => 'ErrorBoxPageState(unsentErrors: ${unsentErrors.length}, isLoading: $isLoading, error: $error)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorBoxPageState &&
          runtimeType == other.runtimeType &&
          unsentErrors == other.unsentErrors &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => unsentErrors.hashCode ^ isLoading.hashCode ^ error.hashCode;
}

/// Cubit for managing error box page state
class ErrorBoxPageCubit extends Cubit<ErrorBoxPageState> {
  ErrorBoxPageCubit() : super(const ErrorBoxPageState());
  
  /// Load unsent errors from storage
  Future<void> loadErrors() async {
    final config = ErrorPrivserverMixin.config;
    if (config == null) return;
    
    emit(state.copyWith(isLoading: true));
    
    try {
      final errors = await config.storage.getUnsentErrors();
      emit(state.copyWith(
        unsentErrors: errors,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load errors: $e',
      ));
    }
  }
  
  /// Send a specific error to the server
  Future<void> sendError(String errorId) async {
    final config = ErrorPrivserverMixin.config;
    if (config == null) return;
    
    try {
      final errorBoxEntry = await config.storage.getErrorById(errorId);
      if (errorBoxEntry == null) return;
      
      await config.reporter(errorBoxEntry.errorData);
      await config.storage.markAsSent(errorId);
      await loadErrors(); // Refresh list
    } catch (e) {
      emit(state.copyWith(error: 'Failed to send error: $e'));
    }
  }
  
  /// Send all unsent errors to the server
  Future<void> sendAllErrors() async {
    for (final error in state.unsentErrors) {
      await sendError(error.id);
    }
  }
  
  /// Delete a specific error from storage
  Future<void> deleteError(String errorId) async {
    final config = ErrorPrivserverMixin.config;
    if (config == null) return;
    
    try {
      await config.storage.deleteError(errorId);
      await loadErrors(); // Refresh list
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete error: $e'));
    }
  }
}