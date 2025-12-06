import 'dart:convert';
import 'package:flutter/foundation.dart';

/// JSON Parser - Background thread parsing for large JSON
/// Prevents UI freeze when parsing 100+ items
class JsonParser {
  /// Threshold for using isolate (10KB)
  static const int _isolateThreshold = 10000;

  /// Parse JSON Map in isolate (background thread)
  static Future<Map<String, dynamic>> parseMap(String jsonString) async {
    if (jsonString.length < _isolateThreshold) {
      // Small JSON, parse on main thread (faster)
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }

    // Large JSON, parse in isolate
    return compute(_parseMapInIsolate, jsonString);
  }

  static Map<String, dynamic> _parseMapInIsolate(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Parse JSON List in isolate
  static Future<List<dynamic>> parseList(String jsonString) async {
    if (jsonString.length < _isolateThreshold) {
      return jsonDecode(jsonString) as List<dynamic>;
    }

    return compute(_parseListInIsolate, jsonString);
  }

  static List<dynamic> _parseListInIsolate(String jsonString) {
    return jsonDecode(jsonString) as List<dynamic>;
  }

  /// Parse with type casting
  static Future<List<T>> parseTypedList<T>(
    String jsonString,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final list = await parseList(jsonString);
    return list
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Encode JSON in isolate
  static Future<String> encode(Object object) async {
    final jsonString = jsonEncode(object);

    if (jsonString.length < _isolateThreshold) {
      return jsonString;
    }

    return compute(_encodeInIsolate, object);
  }

  static String _encodeInIsolate(Object object) {
    return jsonEncode(object);
  }

  /// Safe parse with fallback
  static Future<Map<String, dynamic>?> tryParseMap(String? jsonString) async {
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      return await parseMap(jsonString);
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return null;
    }
  }

  /// Safe parse list with fallback
  static Future<List<dynamic>?> tryParseList(String? jsonString) async {
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      return await parseList(jsonString);
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return null;
    }
  }
}
