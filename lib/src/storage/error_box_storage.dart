import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/error_entry.dart';

/// Abstract storage interface for error box entries
abstract class ErrorBoxStorage {
  Future<void> saveError(ErrorEntry error);
  Future<List<ErrorBoxEntry>> getUnsentErrors();
  Future<ErrorBoxEntry?> getErrorById(String id);
  Future<void> markAsSent(String id);
  Future<void> deleteError(String id);
  Future<int> getUnsentCount();
}

/// SharedPreferences implementation of ErrorBoxStorage
/// 
/// Provides automatic deduplication based on error fingerprints.
/// When the same error occurs multiple times, it increments the count
/// instead of creating duplicate entries.
class SharedPrefsErrorBoxStorage implements ErrorBoxStorage {
  static const String _key = 'flutter_error_privserver_entries';
  static const Uuid _uuid = Uuid();
  
  @override
  Future<void> saveError(ErrorEntry error) async {
    final entries = await _loadEntries();
    
    // Generate fingerprint for deduplication
    final fingerprint = ErrorBoxEntry.generateFingerprint(error);
    
    // Check for existing error with same fingerprint
    final existingIndex = entries.indexWhere((e) => e.fingerprint == fingerprint && !e.wasSent);
    
    if (existingIndex != -1) {
      // Update existing entry - increment count and update timestamp
      entries[existingIndex] = entries[existingIndex].incrementCount();
    } else {
      // Create new entry
      final newEntry = ErrorBoxEntry(
        id: _uuid.v4(),
        fingerprint: fingerprint,
        errorData: error,
        occurrenceCount: 1,
        firstOccurred: DateTime.now(),
        lastOccurred: DateTime.now(),
      );
      entries.add(newEntry);
    }
    
    await _saveEntries(entries);
  }
  
  @override
  Future<List<ErrorBoxEntry>> getUnsentErrors() async {
    final entries = await _loadEntries();
    return entries
        .where((entry) => !entry.wasSent)
        .toList()
      ..sort((a, b) => b.lastOccurred.compareTo(a.lastOccurred));
  }
  
  @override
  Future<ErrorBoxEntry?> getErrorById(String id) async {
    final entries = await _loadEntries();
    try {
      return entries.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> markAsSent(String id) async {
    final entries = await _loadEntries();
    final index = entries.indexWhere((e) => e.id == id);
    
    if (index != -1) {
      entries[index] = entries[index].copyWith(
        wasSent: true,
        sentAt: DateTime.now(),
      );
      await _saveEntries(entries);
    }
  }
  
  @override
  Future<void> deleteError(String id) async {
    final entries = await _loadEntries();
    entries.removeWhere((e) => e.id == id);
    await _saveEntries(entries);
  }
  
  @override
  Future<int> getUnsentCount() async {
    final entries = await getUnsentErrors();
    return entries.length;
  }
  
  Future<List<ErrorBoxEntry>> _loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key) ?? '[]';
      final jsonList = jsonDecode(jsonString) as List;
      
      return jsonList
          .map((json) => ErrorBoxEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If there's any error loading, return empty list and clear corrupted data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      return [];
    }
  }
  
  Future<void> _saveEntries(List<ErrorBoxEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }
}