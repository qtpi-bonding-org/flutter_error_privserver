import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Privacy-preserving error data sent to server
/// 
/// Privacy comes from WHAT we capture, not from scrubbing what we capture:
/// - Only error types (safe by design)
/// - Only cubit class names (safe by design) 
/// - Full raw stack traces (complete debugging info)
/// - Mapped error codes (safe by design)
/// - No function arguments, no user input, no PII
class ErrorEntry {
  const ErrorEntry({
    required this.source,
    required this.errorType,
    required this.errorCode,
    required this.stackTrace,
    required this.timestamp,
    this.userMessage,
  });

  final String source;           // Cubit class name: "AccountCubit"
  final String errorType;        // Exception type: "NetworkException"  
  final String errorCode;        // Safe mapped code: "NET_001"
  final String stackTrace;       // FULL raw stack trace - no truncation or sanitization
  final DateTime timestamp;
  final String? userMessage;     // Optional: what user saw from IExceptionKeyMapper

  factory ErrorEntry.fromJson(Map<String, dynamic> json) => ErrorEntry(
    source: json['source'] as String,
    errorType: json['errorType'] as String,
    errorCode: json['errorCode'] as String,
    stackTrace: json['stackTrace'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    userMessage: json['userMessage'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'source': source,
    'errorType': errorType,
    'errorCode': errorCode,
    'stackTrace': stackTrace,
    'timestamp': timestamp.toIso8601String(),
    'userMessage': userMessage,
  };

  @override
  String toString() => 'ErrorEntry(source: $source, errorType: $errorType, errorCode: $errorCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorEntry &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          errorType == other.errorType &&
          errorCode == other.errorCode &&
          stackTrace == other.stackTrace &&
          timestamp == other.timestamp &&
          userMessage == other.userMessage;

  @override
  int get hashCode =>
      source.hashCode ^
      errorType.hashCode ^
      errorCode.hashCode ^
      stackTrace.hashCode ^
      timestamp.hashCode ^
      userMessage.hashCode;
}

/// Local storage wrapper with user metadata
class ErrorBoxEntry {
  const ErrorBoxEntry({
    required this.id,
    required this.fingerprint,
    required this.errorData,
    required this.occurrenceCount,
    required this.firstOccurred,
    required this.lastOccurred,
    this.wasSent = false,
    this.sentAt,
  });

  final String id;               // UUID
  final String fingerprint;      // Hash for deduplication
  final ErrorEntry errorData;    // The actual error data
  final int occurrenceCount;     // How many times this error occurred
  final DateTime firstOccurred;  // When first seen
  final DateTime lastOccurred;   // When last seen
  final bool wasSent;           // User sent this error
  final DateTime? sentAt;       // When user sent it

  ErrorBoxEntry copyWith({
    int? occurrenceCount,
    DateTime? lastOccurred,
    bool? wasSent,
    DateTime? sentAt,
  }) {
    return ErrorBoxEntry(
      id: id,
      fingerprint: fingerprint,
      errorData: errorData,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      firstOccurred: firstOccurred,
      lastOccurred: lastOccurred ?? this.lastOccurred,
      wasSent: wasSent ?? this.wasSent,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  ErrorBoxEntry incrementCount() {
    return copyWith(
      occurrenceCount: occurrenceCount + 1,
      lastOccurred: DateTime.now(),
    );
  }

  factory ErrorBoxEntry.fromJson(Map<String, dynamic> json) => ErrorBoxEntry(
    id: json['id'] as String,
    fingerprint: json['fingerprint'] as String,
    errorData: ErrorEntry.fromJson(json['errorData'] as Map<String, dynamic>),
    occurrenceCount: json['occurrenceCount'] as int,
    firstOccurred: DateTime.parse(json['firstOccurred'] as String),
    lastOccurred: DateTime.parse(json['lastOccurred'] as String),
    wasSent: json['wasSent'] as bool,
    sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt'] as String) : null,
  );

  /// Generate fingerprint for deduplication based on error characteristics
  static String generateFingerprint(ErrorEntry error) {
    // Combine error type, code, and source for fingerprint
    final combined = '${error.errorType}:${error.errorCode}:${error.source}';
    return sha256.convert(utf8.encode(combined)).toString();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fingerprint': fingerprint,
    'errorData': errorData.toJson(),
    'occurrenceCount': occurrenceCount,
    'firstOccurred': firstOccurred.toIso8601String(),
    'lastOccurred': lastOccurred.toIso8601String(),
    'wasSent': wasSent,
    'sentAt': sentAt?.toIso8601String(),
  };

  @override
  String toString() => 'ErrorBoxEntry(id: $id, errorCode: ${errorData.errorCode}, count: $occurrenceCount, sent: $wasSent)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorBoxEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}