import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

void main() {
  group('ErrorCodeMapper', () {
    test('maps known exception types to specific codes', () {
      expect(ErrorCodeMapper.mapError(const FormatException('test')), 'VAL_002');
      expect(ErrorCodeMapper.mapError(ArgumentError('test')), 'VAL_003');
      expect(ErrorCodeMapper.mapError(StateError('test')), 'STATE_001');
      expect(ErrorCodeMapper.mapError(TypeError()), 'TYPE_001');
    });

    test('maps unknown exception types to generic codes', () {
      final customError = Exception('custom error');
      final result = ErrorCodeMapper.mapError(customError);
      expect(result, 'ERR_EXCEPTION');
    });

    test('uses pattern matching for common error patterns', () {
      expect(ErrorCodeMapper.mapError(Exception('network failed')), 'NET_UNKNOWN');
      expect(ErrorCodeMapper.mapError(Exception('connection timeout')), 'NET_UNKNOWN');
      expect(ErrorCodeMapper.mapError(Exception('request timeout')), 'NET_TIMEOUT');
      expect(ErrorCodeMapper.mapError(Exception('auth failed')), 'AUTH_UNKNOWN');
      expect(ErrorCodeMapper.mapError(Exception('unauthorized access')), 'AUTH_UNKNOWN');
      expect(ErrorCodeMapper.mapError(Exception('validation error')), 'VAL_UNKNOWN');
      expect(ErrorCodeMapper.mapError(Exception('invalid format')), 'VAL_UNKNOWN');
      expect(ErrorCodeMapper.mapError(Exception('storage failed')), 'STORE_UNKNOWN');
      expect(ErrorCodeMapper.mapError(Exception('database error')), 'STORE_UNKNOWN');
      expect(ErrorCodeMapper.mapError(Exception('permission denied')), 'PERM_UNKNOWN');
      expect(ErrorCodeMapper.mapError(Exception('parse error')), 'PARSE_UNKNOWN');
    });

    test('allows adding custom mappings', () {
      // Define a custom exception type
      const customError = CustomTestException('test');
      
      // Should use generic mapping initially
      expect(ErrorCodeMapper.mapError(customError), 'ERR_CUSTOMTESTEXCEPTION');
      
      // Add custom mapping
      ErrorCodeMapper.addMapping(CustomTestException, 'CUSTOM_001');
      
      // Should now use custom mapping
      expect(ErrorCodeMapper.mapError(customError), 'CUSTOM_001');
    });

    test('returns registered mappings', () {
      final mappings = ErrorCodeMapper.registeredMappings;
      expect(mappings[FormatException], 'VAL_002');
      expect(mappings[StateError], 'STATE_001');
      expect(mappings.containsKey(String), false);
    });
  });
}

class CustomTestException implements Exception {
  const CustomTestException(this.message);
  
  final String message;
  
  @override
  String toString() => 'CustomTestException: $message';
}