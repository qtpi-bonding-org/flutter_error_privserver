import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

void main() {
  // Configure error privacy server
  ErrorPrivserver.configure(ErrorPrivserverConfig(
    storage: SharedPrefsErrorBoxStorage(),
    reporter: (errorEntry) async {
      // Simulate sending to server
      print('Sending error report: ${errorEntry.toJson()}');
      await Future.delayed(Duration(seconds: 1));
    },
    errorCodeMapper: ErrorCodeMapper.mapError,
    exceptionMapper: (error) {
      // Simple exception mapper for demo
      if (error.toString().contains('network')) {
        return MessageKey.networkError;
      }
      return MessageKey.genericError;
    },
    showToast: false, // Disabled - no BuildContext access in mixin
    toastBuilder: ExampleErrorToastBuilder(),
    pageBuilder: ExampleErrorBoxPageBuilder(),
  ));
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error Privserver Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Error Privserver Example')),
      body: BlocProvider(
        create: (context) => ExampleCubit(),
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ExampleCubit, ExampleState>(
                builder: (context, state) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Status: ${state.status}'),
                        if (state.hasError) 
                          Text('Error: ${state.error}', style: TextStyle(color: Colors.red)),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => context.read<ExampleCubit>().triggerNetworkError(),
                          child: Text('Trigger Network Error'),
                        ),
                        ElevatedButton(
                          onPressed: () => context.read<ExampleCubit>().triggerValidationError(),
                          child: Text('Trigger Validation Error'),
                        ),
                        ElevatedButton(
                          onPressed: () => context.read<ExampleCubit>().triggerGenericError(),
                          child: Text('Trigger Generic Error'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: FutureBuilder<int>(
                future: ErrorPrivserver.getUnsentCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ErrorPrivserver.page(context)),
                    ),
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      child: Icon(Icons.bug_report),
                    ),
                    label: Text('View Error Reports'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example cubit that uses the mixin approach
class ExampleCubit extends TryOperationCubit<ExampleState> with ErrorPrivserverMixin<ExampleState> {
  ExampleCubit() : super(ExampleState.initial());
  
  Future<void> triggerNetworkError() async {
    await tryOperation(() async {
      await Future.delayed(Duration(milliseconds: 500));
      throw Exception('Network connection failed');
    });
  }
  
  Future<void> triggerValidationError() async {
    await tryOperation(() async {
      await Future.delayed(Duration(milliseconds: 500));
      throw FormatException('Invalid email format');
    });
  }
  
  Future<void> triggerGenericError() async {
    await tryOperation(() async {
      await Future.delayed(Duration(milliseconds: 500));
      throw StateError('Something went wrong');
    });
  }
}

// Example state
class ExampleState with UiFlowStateMixin {
  @override
  final UiFlowStatus status;
  
  @override
  final Object? error;
  
  const ExampleState({
    this.status = UiFlowStatus.idle,
    this.error,
  });
  
  static ExampleState initial() => ExampleState();
  
  ExampleState copyWith({
    UiFlowStatus? status,
    Object? error,
  }) {
    return ExampleState(
      status: status ?? this.status,
      error: error,
    );
  }
}

// Example toast builder
class ExampleErrorToastBuilder extends ErrorToastBuilder {
  @override
  void show(BuildContext context, String message, {
    required VoidCallback onDismiss,
    required VoidCallback onSend,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Send Report',
          onPressed: onSend,
        ),
      ),
    );
  }
}

// Example error box page builder
class ExampleErrorBoxPageBuilder extends ErrorBoxPageBuilder {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ErrorBoxPageCubit()..loadErrors(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Error Reports'),
          actions: [
            BlocBuilder<ErrorBoxPageCubit, ErrorBoxPageState>(
              builder: (context, state) {
                if (state.unsentErrors.isEmpty) return SizedBox.shrink();
                
                return TextButton.icon(
                  onPressed: () => context.read<ErrorBoxPageCubit>().sendAllErrors(),
                  icon: Icon(Icons.send_outlined, color: Colors.white),
                  label: Text('Send All (${state.unsentErrors.length})', style: TextStyle(color: Colors.white)),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<ErrorBoxPageCubit, ErrorBoxPageState>(
          builder: (context, state) {
            if (state.isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (state.unsentErrors.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No error reports to review'),
                    SizedBox(height: 8),
                    Text('Trigger some errors to see them here!', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: state.unsentErrors.length,
              itemBuilder: (context, index) {
                final error = state.unsentErrors[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error.errorData.errorCode,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Chip(
                              label: Text('${error.occurrenceCount}x'),
                              backgroundColor: Colors.orange.shade100,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('Type: ${error.errorData.errorType}'),
                        Text('Source: ${error.errorData.source}'),
                        if (error.errorData.userMessage != null)
                          Text('Message: ${error.errorData.userMessage}'),
                        Text('Last occurred: ${_formatTime(error.lastOccurred)}'),
                        SizedBox(height: 12),
                        ExpansionTile(
                          title: Text('Stack Trace'),
                          tilePadding: EdgeInsets.zero,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                error.errorData.stackTrace,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => context.read<ErrorBoxPageCubit>().deleteError(error.id),
                              icon: Icon(Icons.delete_outline),
                              label: Text('Delete'),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => context.read<ErrorBoxPageCubit>().sendError(error.id),
                              icon: Icon(Icons.send),
                              label: Text('Send'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}