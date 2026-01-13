# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-13

### Added
- Initial release of flutter_error_privserver
- `ErrorPrivserverMixin` for adding privacy-preserving error capture to any cubit
- `ErrorPrivserverCubit` convenience class (deprecated in favor of mixin)
- `SharedPrefsErrorBoxStorage` implementation for local error storage
- Automatic error deduplication based on fingerprinting
- `ErrorCodeMapper` utility for mapping exceptions to safe error codes
- Builder interfaces for customizable UI (`ErrorToastBuilder`, `ErrorBoxPageBuilder`, `ErrorBoxCardBuilder`)
- `ErrorBoxPageCubit` for managing error box page state
- Complete example app demonstrating usage
- Comprehensive test suite
- Privacy-first design - only captures error types, cubit names, and stack traces
- No function arguments, user input, or PII captured
- Full raw stack traces preserved for debugging
- User control - never auto-sends errors
- Works with any cubit base class (TryOperationCubit, HydratedCubit, custom classes)

### Features
- **Privacy-Preserving**: Only captures safe data by design
- **Flexible Integration**: Mixin approach works with any cubit inheritance hierarchy
- **Automatic Deduplication**: Prevents spam by counting repeated errors
- **User Control**: Users choose what to send, nothing auto-sent
- **Customizable UI**: Interface-based design for any design system
- **Comprehensive Storage**: Local storage with metadata (occurrence count, timestamps)
- **Error Code Mapping**: Safe error codes for categorization
- **Full Stack Traces**: Complete debugging information preserved