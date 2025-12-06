import 'package:kpss_2026/core/models/lesson_model.dart';
import 'package:kpss_2026/core/data/lessons_data.dart';

/// ⚡ HARDCODED ONLY - Firebase bağımlılığı kaldırıldı
/// Yeni ders eklemek için lessons_data.dart'ı güncelle
class LessonRepository {
  LessonRepository();
  
  // ⚡ Memory cache
  static List<LessonModel>? _cachedLessons;

  /// ⚡ HARDCODE-ONLY: Dersleri hardcode'dan al - 0 Firebase!
  Future<List<LessonModel>> getLessons() async {
    _cachedLessons ??= lessonsData.map((e) => LessonModel.fromJson(e)).toList();
    return _cachedLessons!;
  }
  
  /// Refresh - sadece memory cache'i yeniden yükler
  Future<List<LessonModel>> refreshLessons() async {
    _cachedLessons = null;
    return getLessons();
  }

  /// ⚡ HARDCODE-ONLY: Tek dersi al - 0 Firebase!
  Future<LessonModel?> getLessonById(String lessonId) async {
    _cachedLessons ??= lessonsData.map((e) => LessonModel.fromJson(e)).toList();
    
    final found = _cachedLessons!.where((l) => l.id == lessonId);
    return found.isNotEmpty ? found.first : null;
  }
}
