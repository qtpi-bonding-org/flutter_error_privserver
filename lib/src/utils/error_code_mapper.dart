/// Privacy-preserving error code mapper
/// 
/// Maps exception types to safe error codes without examining function arguments
/// or sensitive data. Only uses exception type and basic pattern matching.
class ErrorCodeMapper {
  static final Map<Type, String> _typeToCode = {
    // Network errors
    // NetworkException: 'NET_001',  // Uncomment when you have these types
    // TimeoutException: 'NET_002',
    // ConnectionException: 'NET_003',
    
    // Authentication errors
    // AuthException: 'AUTH_001',
    // UnauthorizedException: 'AUTH_002',
    // TokenExpiredException: 'AUTH_003',
    
    // Validation errors
    // ValidationException: 'VAL_001',
    FormatException: 'VAL_002',
    ArgumentError: 'VAL_003',
    
    // Storage errors
    // StorageException: 'STORE_001',
    // DatabaseException: 'STORE_002',
    
    // Common Flutter/Dart errors
    StateError: 'STATE_001',
    UnsupportedError: 'UNSUPPORTED_001',
    UnimplementedError: 'UNIMPLEMENTED_001',
    AssertionError: 'ASSERTION_001',
    TypeError: 'TYPE_001',
    NoSuchMethodError: 'METHOD_001',
    RangeError: 'RANGE_001',
  };
  
  /// Maps exception to privacy-safe error code
  /// Only uses exception type and basic pattern matching - no function arguments
  static String mapError(Object error) {
    final errorType = error.runtimeType;
    
    // Direct type mapping (preferred)
    if (_typeToCode.containsKey(errorType)) {
      return _typeToCode[errorType]!;
    }
    
    // Pattern matching on error message (privacy-safe)
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'NET_UNKNOWN';
    }
    
    if (errorString.contains('timeout')) {
      return 'NET_TIMEOUT';
    }
    
    if (errorString.contains('auth') || errorString.contains('unauthorized')) {
      return 'AUTH_UNKNOWN';
    }
    
    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return 'VAL_UNKNOWN';
    }
    
    if (errorString.contains('storage') || errorString.contains('database')) {
      return 'STORE_UNKNOWN';
    }
    
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'PERM_UNKNOWN';
    }
    
    if (errorString.contains('parse') || errorString.contains('format')) {
      return 'PARSE_UNKNOWN';
    }
    
    // Fallback to generic error with type name
    final typeName = errorType.toString().replaceAll('_', '').toUpperCase();
    return 'ERR_$typeName';
  }
  
  /// Add custom error type mappings
  /// 
  /// This allows apps to register their own exception types:
  /// ```dart
  /// ErrorCodeMapper.addMapping(MyCustomException, 'CUSTOM_001');
  /// ```
  static void addMapping(Type errorType, String errorCode) {
    _typeToCode[errorType] = errorCode;
  }
  
  /// Get all registered error type mappings
  static Map<Type, String> get registeredMappings => Map.unmodifiable(_typeToCode);
}