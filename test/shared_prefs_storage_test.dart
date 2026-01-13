import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

void main() {
  group('SharedPrefsErrorBoxStorage', () {
    late SharedPrefsErrorBoxStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = SharedPrefsErrorBoxStorage();
    });

    test('saves and retrieves errors correctly', () async {
      final errorEntry = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      await storage.saveError(errorEntry);

      final unsentErrors = await storage.getUnsentErrors();
      expect(unsentErrors.length, 1);
      expect(unsentErrors.first.errorData.source, 'TestCubit');
      expect(unsentErrors.first.errorData.errorCode, 'NET_001');
      expect(unsentErrors.first.occurrenceCount, 1);
    });

    test('deduplicates identical errors', () async {
      final errorEntry = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      // Save the same error multiple times
      await storage.saveError(errorEntry);
      await storage.saveError(errorEntry);
      await storage.saveError(errorEntry);

      final unsentErrors = await storage.getUnsentErrors();
      expect(unsentErrors.length, 1);
      expect(unsentErrors.first.occurrenceCount, 3);
    });

    test('stores different errors separately', () async {
      final errorEntry1 = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      final errorEntry2 = ErrorEntry(
        source: 'TestCubit',
        errorType: 'ValidationException',
        errorCode: 'VAL_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      await storage.saveError(errorEntry1);
      await storage.saveError(errorEntry2);

      final unsentErrors = await storage.getUnsentErrors();
      expect(unsentErrors.length, 2);
    });

    test('marks errors as sent correctly', () async {
      final errorEntry = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      await storage.saveError(errorEntry);

      var unsentErrors = await storage.getUnsentErrors();
      expect(unsentErrors.length, 1);
      
      final errorId = unsentErrors.first.id;
      await storage.markAsSent(errorId);

      unsentErrors = await storage.getUnsentErrors();
      expect(unsentErrors.length, 0);

      // Verify the error still exists but is marked as sent
      final sentError = await storage.getErrorById(errorId);
      expect(sentError, isNotNull);
      expect(sentError!.wasSent, true);
      expect(sentError.sentAt, isNotNull);
    });

    test('deletes errors correctly', () async {
      final errorEntry = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      await storage.saveError(errorEntry);

      var unsentErrors = await storage.getUnsentErrors();
      expect(unsentErrors.length, 1);
      
      final errorId = unsentErrors.first.id;
      await storage.deleteError(errorId);

      unsentErrors = await storage.getUnsentErrors();
      expect(unsentErrors.length, 0);

      final deletedError = await storage.getErrorById(errorId);
      expect(deletedError, isNull);
    });

    test('returns correct unsent count', () async {
      expect(await storage.getUnsentCount(), 0);

      final errorEntry = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      await storage.saveError(errorEntry);
      expect(await storage.getUnsentCount(), 1);

      await storage.saveError(errorEntry); // Should deduplicate
      expect(await storage.getUnsentCount(), 1);

      final differentError = ErrorEntry(
        source: 'TestCubit',
        errorType: 'ValidationException',
        errorCode: 'VAL_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      await storage.saveError(differentError);
      expect(await storage.getUnsentCount(), 2);
    });

    test('handles corrupted data gracefully', () async {
      // Manually set corrupted data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('flutter_error_privserver_entries', 'invalid json');

      // Should return empty list and clear corrupted data
      final errors = await storage.getUnsentErrors();
      expect(errors, isEmpty);

      // Should be able to save new errors after corruption
      final errorEntry = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      await storage.saveError(errorEntry);
      final newErrors = await storage.getUnsentErrors();
      expect(newErrors.length, 1);
    });

    test('sorts errors by last occurred time (newest first)', () async {
      final oldError = ErrorEntry(
        source: 'TestCubit',
        errorType: 'NetworkException',
        errorCode: 'NET_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final newError = ErrorEntry(
        source: 'TestCubit',
        errorType: 'ValidationException',
        errorCode: 'VAL_001',
        stackTrace: 'test stack trace',
        timestamp: DateTime.now(),
      );

      await storage.saveError(oldError);
      await Future.delayed(const Duration(milliseconds: 10)); // Ensure different timestamps
      await storage.saveError(newError);

      final unsentErrors = await storage.getUnsentErrors();
      expect(unsentErrors.length, 2);
      expect(unsentErrors.first.errorData.errorCode, 'VAL_001'); // Newer error first
      expect(unsentErrors.last.errorData.errorCode, 'NET_001'); // Older error last
    });
  });
}