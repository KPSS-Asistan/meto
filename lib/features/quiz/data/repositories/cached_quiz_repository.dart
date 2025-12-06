import '../../domain/entities/quiz.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'firebase_quiz_repository.dart';

/// ⚡ HARDCODED ONLY - Sadece memory cache kullanır
/// FirebaseQuizRepository artık hardcoded data kullanıyor
class CachedQuizRepository implements QuizRepository {
  final FirebaseQuizRepository _quizRepo = FirebaseQuizRepository();
  
  // ⚡ MEMORY CACHE: QuizSet'leri bellekte tut
  static final Map<String, QuizSet> _memoryCache = {};

  @override
  Future<QuizSet> getQuizSet(String setId) async {
    // ⚡ Memory cache'e bak (en hızlı)
    if (_memoryCache.containsKey(setId)) {
      return _memoryCache[setId]!;
    }
    
    // Hardcoded data'dan al
    final quiz = await _quizRepo.getQuizSet(setId);
    
    // Memory cache'e ekle
    _memoryCache[setId] = quiz;
    
    return quiz;
  }

  /// Cache'i temizle
  void clearCache(String setId) {
    _memoryCache.remove(setId);
  }

  /// Tüm cache'i temizle
  void clearAllCache() {
    _memoryCache.clear();
  }
}
