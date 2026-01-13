# flutter_error_privserver

Privacy-preserving error reporting library for Flutter apps using cubit_ui_flow. Captures error types and stack traces without PII.

## Features

- **Privacy-First**: Only captures error types, cubit names, and stack traces - no function arguments or user data
- **User Control**: Never auto-sends errors - users choose what to share
- **Deduplication**: Automatically prevents spam by counting repeated errors
- **Seamless Integration**: Mixin approach works with any cubit base class
- **Flexible UI**: Interface-based design works with any design system

## Privacy Model

This library ensures privacy through **what we capture**, not by scrubbing what we capture:

### ✅ What We Capture (Safe by Design)
- Error types: `NetworkException`, `ValidationException`
- Cubit names: `AccountCubit`, `LoginCubit`
- Full stack traces: Complete method call chains for debugging
- Error codes: `NET_001`, `AUTH_002` (mapped from types)
- User messages: "Network error occurred" (optional, from IExceptionKeyMapper)

### ❌ What We DON'T Capture (Naturally Private)
- Function arguments: `createAccount(email: "user@example.com")`
- User input: Form field values, search queries
- API responses: Server data, tokens, credentials
- Local variables: Anything from function scope

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_error_privserver: ^0.1.0
  cubit_ui_flow: ^1.0.0
```

## Quick Start

### 1. Configure the Library

```dart
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

void main() {
  // Configure error privacy server
  ErrorPrivserver.configure(ErrorPrivserverConfig(
    storage: SharedPrefsErrorBoxStorage(),
    reporter: (errorEntry) => myClient.sendError(errorEntry),
    errorCodeMapper: ErrorCodeMapper.mapError,
    exceptionMapper: myExceptionMapper.map, // Your existing IExceptionKeyMapper
    showToast: false, // Disable toast (requires BuildContext)
    toastBuilder: MyErrorToastBuilder(), // Your implementation
    pageBuilder: MyErrorBoxPageBuilder(), // Your implementation
  ));
  
  runApp(MyApp());
}
```

### 2. Update Your Cubits (Mixin Approach)

Add the mixin to any cubit base class:

```dart
// Before
class AccountCubit extends TryOperationCubit<AccountState> {
  AccountCubit() : super(AccountState.initial());
  
  Future<void> createAccount() async {
    await tryOperation(() async {
      final account = await _authService.createAccount();
      return state.copyWith(account: account, status: UiFlowStatus.success);
    });
  }
}

// After - just add the mixin
class AccountCubit extends TryOperationCubit<AccountState> with ErrorPrivserverMixin<AccountState> {
  AccountCubit() : super(AccountState.initial());
  
  // Same code - errors are now automatically captured!
  Future<void> createAccount() async {
    await tryOperation(() async {
      final account = await _authService.createAccount();
      return state.copyWith(account: account, status: UiFlowStatus.success);
    });
  }
}

// Works with any cubit base class
class SettingsCubit extends HydratedCubit<SettingsState> with ErrorPrivserverMixin<SettingsState> {
  SettingsCubit() : super(SettingsState.initial());
  
  // Now you have both hydration AND error capture
  Future<void> updateSettings() async {
    await tryOperation(() async {
      // Your logic here
    });
  }
}
```

### 3. Implement UI Builders

You must implement the UI builders to match your design system:

```dart
class MyErrorToastBuilder extends ErrorToastBuilder {
  @override
  void show(BuildContext context, String message, {
    required VoidCallback onDismiss,
    required VoidCallback onSend,
  }) {
    // Your custom toast implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Send Report', onPressed: onSend),
      ),
    );
  }
}

class MyErrorBoxPageBuilder extends ErrorBoxPageBuilder {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ErrorBoxPageCubit()..loadErrors(),
      child: Scaffold(
        appBar: AppBar(title: Text('Error Reports')),
        body: BlocBuilder<ErrorBoxPageCubit, ErrorBoxPageState>(
          builder: (context, state) {
            // Your custom error box UI
            return ListView.builder(
              itemCount: state.unsentErrors.length,
              itemBuilder: (context, index) {
                final error = state.unsentErrors[index];
                return ListTile(
                  title: Text(error.errorData.errorCode),
                  subtitle: Text('${error.occurrenceCount} occurrences'),
                  trailing: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => context.read<ErrorBoxPageCubit>().sendError(error.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```

### 4. Add Navigation

```dart
// Add to your navigation
ListTile(
  leading: FutureBuilder<int>(
    future: ErrorPrivserver.getUnsentCount(),
    builder: (context, snapshot) {
      final count = snapshot.data ?? 0;
      return Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: Icon(Icons.bug_report_outlined),
      );
    },
  ),
  title: Text('Error Reports'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ErrorPrivserver.page(context)),
  ),
),
```

## API Reference

### ErrorPrivserver

Static convenience class for library usage:

- `configure(ErrorPrivserverConfig)` - Configure the library
- `page(BuildContext)` - Get the error box page widget
- `getUnsentCount()` - Get count of unsent errors
- `sendError(String id)` - Send specific error
- `deleteError(String id)` - Delete specific error
- `sendAllErrors()` - Send all unsent errors

### ErrorPrivserverCubit<S>

Enhanced cubit that extends `TryOperationCubit`:

- Automatically captures errors from `tryOperation` calls
- Stores errors locally with deduplication
- Preserves all existing cubit_ui_flow functionality

### ErrorCodeMapper

Utility for mapping exceptions to safe error codes:

- `mapError(Object error)` - Map exception to error code
- `addMapping(Type, String)` - Add custom mappings

## License

MIT License - see LICENSE file for details.