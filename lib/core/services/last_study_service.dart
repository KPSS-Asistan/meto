import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Son çalışılan konuyu takip eden servis
/// Kullanıcı bir modüle girdiğinde otomatik güncellenir
class LastStudyService {
  static const String _lastStudyKey = 'last_study_data';
  
  static SharedPreferences? _prefs;
  
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Son çalışılan konuyu kaydet
  static Future<void> saveLastStudy({
    required String lessonId,
    required String lessonName,
    required String topicId,
    required String topicName,
    required String moduleName,
  }) async {
    final prefs = await _instance;
    
    final data = {
      'lessonId': lessonId,
      'lessonName': lessonName,
      'topicId': topicId,
      'topicName': topicName,
      'moduleName': moduleName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_lastStudyKey, jsonEncode(data));
  }

  /// Son çalışılan konuyu al
  static Future<Map<String, dynamic>?> getLastStudy() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(_lastStudyKey);
    
    if (jsonStr == null || jsonStr.isEmpty) return null;
    
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Son çalışma var mı?
  static Future<bool> hasLastStudy() async {
    final data = await getLastStudy();
    return data != null;
  }

  /// Son çalışmayı temizle
  static Future<void> clearLastStudy() async {
    final prefs = await _instance;
    await prefs.remove(_lastStudyKey);
  }
}
