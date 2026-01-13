import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

void main() {
  group('ErrorEntry', () {
    test('creates error entry with all fields', () {
      final timestamp = DateTime.now();
      final entry = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: timestamp,
        userMessage: 'Network error occurred',
      );

      expect(entry.source, 'TestCubit');
      expect(entry.errorType, 'NetworkException');
      expect(entry.errorCode, 'NET_001');
      expect(entry.stackTrace, 'test stack trace');
      expect(entry.timestamp, timestamp);
      expect(entry.userMessage, 'Network error occurred');
    });

    test('serializes to and from JSON correctly', () {
      final timestamp = DateTime.now();
      final entry = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: timestamp,
        userMessage: 'Network error occurred',
      );

      final json = entry.toJson();
      final restored = ErrorEntry.fromJson(json);

      expect(restored.source, entry.source);
      expect(restored.errorType, entry.errorType);
      expect(restored.errorCode, entry.errorCode);
      expect(restored.stackTrace, entry.stackTrace);
      expect(restored.timestamp, entry.timestamp);
      expect(restored.userMessage, entry.userMessage);
    });

    test('handles null user message', () {
      final entry = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      expect(entry.userMessage, null);

      final json = entry.toJson();
      final restored = ErrorEntry.fromJson(json);
      expect(restored.userMessage, null);
    });

    test('equality works correctly', () {
      final timestamp = DateTime.now();
      final entry1 = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: timestamp,
      );

      final entry2 = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: timestamp,
      );

      final entry3 = ErrorEntry(
        source: 'DifferentCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: timestamp,
      );

      expect(entry1, equals(entry2));
      expect(entry1, isNot(equals(entry3)));
    });
  });

  group('ErrorBoxEntry', () {
    test('creates error box entry with metadata', () {
      final errorData = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      final firstOccurred = DateTime.now();
      final lastOccurred = DateTime.now().add(const Duration(minutes: 5));

      final boxEntry = ErrorBoxEntry(
        id: 'test-id',
        fingerprint: 'test-fingerprint',
        errorData: errorData,
        occurrenceCount: 3,
        firstOccurred: firstOccurred,
        lastOccurred: lastOccurred,
      );

      expect(boxEntry.id, 'test-id');
      expect(boxEntry.fingerprint, 'test-fingerprint');
      expect(boxEntry.errorData, errorData);
      expect(boxEntry.occurrenceCount, 3);
      expect(boxEntry.firstOccurred, firstOccurred);
      expect(boxEntry.lastOccurred, lastOccurred);
      expect(boxEntry.wasSent, false);
      expect(boxEntry.sentAt, null);
    });

    test('generates fingerprint correctly', () {
      final errorData = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      final fingerprint = ErrorBoxEntry.generateFingerprint(errorData);
      expect(fingerprint, isNotEmpty);
      expect(fingerprint.length, 64); // SHA256 hash length

      // Same error should generate same fingerprint
      final fingerprint2 = ErrorBoxEntry.generateFingerprint(errorData);
      expect(fingerprint, fingerprint2);

      // Different error should generate different fingerprint
      final differentError = ErrorEntry(
        source: 'DifferentCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );
      final differentFingerprint = ErrorBoxEntry.generateFingerprint(differentError);
      expect(fingerprint, isNot(differentFingerprint));
    });

    test('increments count correctly', () {
      final errorData = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      final originalTime = DateTime.now();
      final boxEntry = ErrorBoxEntry(
        id: 'test-id',
        fingerprint: 'test-fingerprint',
        errorData: errorData,
        occurrenceCount: 1,
        firstOccurred: originalTime,
        lastOccurred: originalTime,
      );

      final incremented = boxEntry.incrementCount();

      expect(incremented.occurrenceCount, 2);
      expect(incremented.firstOccurred, originalTime); // Should not change
      expect(incremented.lastOccurred.isAfter(originalTime), true); // Should be updated
      expect(incremented.id, boxEntry.id); // Other fields unchanged
      expect(incremented.fingerprint, boxEntry.fingerprint);
    });

    test('serializes to and from JSON correctly', () {
      final errorData = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      final firstOccurred = DateTime.now();
      final lastOccurred = DateTime.now().add(const Duration(minutes: 5));
      final sentAt = DateTime.now().add(const Duration(minutes: 10));

      final boxEntry = ErrorBoxEntry(
        id: 'test-id',
        fingerprint: 'test-fingerprint',
        errorData: errorData,
        occurrenceCount: 3,
        firstOccurred: firstOccurred,
        lastOccurred: lastOccurred,
        wasSent: true,
        sentAt: sentAt,
      );

      final json = boxEntry.toJson();
      final restored = ErrorBoxEntry.fromJson(json);

      expect(restored.id, boxEntry.id);
      expect(restored.fingerprint, boxEntry.fingerprint);
      expect(restored.errorData.source, boxEntry.errorData.source);
      expect(restored.occurrenceCount, boxEntry.occurrenceCount);
      expect(restored.firstOccurred, boxEntry.firstOccurred);
      expect(restored.lastOccurred, boxEntry.lastOccurred);
      expect(restored.wasSent, boxEntry.wasSent);
      expect(restored.sentAt, boxEntry.sentAt);
    });
  });
}