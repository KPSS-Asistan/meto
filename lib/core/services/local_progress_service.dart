import 'package:shared_preferences/shared_preferences.dart';
import 'package:kpss_2026/core/models/local_user_data.dart';

/// Kullanıcı verilerini local'de yöneten servis
/// Tüm ilerleme verileri SharedPreferences'ta JSON olarak tutulur
/// Firebase sync günde 1x yapılır (sadece giriş yapmış kullanıcılar için)
class LocalProgressService {
  static const String _userDataKey = 'local_user_data';
  static const String _lastSyncKey = 'last_sync_date';
  
  static LocalProgressService? _instance;
  static SharedPreferences? _prefs;
  
  LocalUserData _userData = LocalUserData();
  
  LocalProgressService._();
  
  static Future<LocalProgressService> getInstance() async {
    if (_instance == null) {
      _instance = LocalProgressService._();
      _prefs = await SharedPreferences.getInstance();
      await _instance!._loadData();
    }
    return _instance!;
  }
  
  /// Mevcut kullanıcı verisini getir
  LocalUserData get userData => _userData;
  
  /// Veriyi yükle
  Future<void> _loadData() async {
    final jsonString = _prefs?.getString(_userDataKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        _userData = LocalUserData.fromJsonString(jsonString);
      } catch (e) {
        // Parse hatası - yeni veri oluştur
        _userData = LocalUserData();
      }
    }
  }
  
  /// Veriyi kaydet
  Future<void> _saveData() async {
    await _prefs?.setString(_userDataKey, _userData.toJsonString());
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STREAK YÖNETİMİ
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Bugün çalışma kaydı ekle ve streak güncelle
  Future<void> recordStudySession() async {
    final today = _formatDate(DateTime.now());
    final lastDate = _userData.lastStudyDate;
    
    int newStreak = _userData.currentStreak;
    
    if (lastDate == null) {
      // İlk çalışma
      newStreak = 1;
    } else if (lastDate == today) {
      // Bugün zaten çalışmış, streak değişmez
      return;
    } else {
      final yesterday = _formatDate(DateTime.now().subtract(const Duration(days: 1)));
      if (lastDate == yesterday) {
        // Dün çalışmış, streak devam
        newStreak = _userData.currentStreak + 1;
      } else {
        // Streak kırıldı
        newStreak = 1;
      }
    }
    
    final longestStreak = newStreak > _userData.longestStreak 
        ? newStreak 
        : _userData.longestStreak;
    
    _userData = _userData.copyWith(
      currentStreak: newStreak,
      lastStudyDate: today,
      longestStreak: longestStreak,
    );
    
    await _saveData();
  }
  
  /// Streak bilgisini getir
  int get currentStreak => _userData.currentStreak;
  int get longestStreak => _userData.longestStreak;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // QUIZ SONUÇLARI
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Quiz sonucu kaydet
  Future<void> recordQuizResult({
    required String topicId,
    required String lessonId,
    required String topicName,
    required int totalQuestions,
    required int correctAnswers,
    required int durationSeconds,
    required List<String> wrongQuestionIds,
    required Map<String, String> wrongAnswerDetails, // questionId -> selectedAnswer
    required Map<String, String> correctAnswerDetails, // questionId -> correctAnswer
  }) async {
    // Quiz oturumu ekle
    final session = QuizSessionData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      topicId: topicId,
      lessonId: lessonId,
      date: DateTime.now(),
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      durationSeconds: durationSeconds,
      wrongQuestionIds: wrongQuestionIds,
    );
    
    // Son 50 quiz tut
    final quizHistory = List<QuizSessionData>.from(_userData.quizHistory);
    quizHistory.insert(0, session);
    if (quizHistory.length > 50) {
      quizHistory.removeRange(50, quizHistory.length);
    }
    
    // Konu ilerlemesini güncelle
    final topicProgress = Map<String, TopicProgressData>.from(_userData.topicProgress);
    final existing = topicProgress[topicId] ?? TopicProgressData(
      lessonId: lessonId,
      topicName: topicName,
    );
    
    final newAttempted = existing.attemptedQuestions + totalQuestions;
    final newCorrect = existing.correctAnswers + correctAnswers;
    final newWrong = existing.wrongAnswers + (totalQuestions - correctAnswers);
    final newSuccessRate = newAttempted > 0 ? newCorrect / newAttempted : 0.0;
    
    topicProgress[topicId] = existing.copyWith(
      attemptedQuestions: newAttempted,
      correctAnswers: newCorrect,
      wrongAnswers: newWrong,
      successRate: newSuccessRate,
      lastStudy: DateTime.now(),
      studyCount: existing.studyCount + 1,
      averageTimeSeconds: durationSeconds ~/ totalQuestions,
    );
    
    // Yanlış cevapları kaydet
    final wrongAnswers = List<WrongAnswerData>.from(_userData.wrongAnswers);
    for (final questionId in wrongQuestionIds) {
      // Aynı soru daha önce yanlış yapılmış mı?
      final existingIndex = wrongAnswers.indexWhere((w) => w.questionId == questionId);
      
      if (existingIndex >= 0) {
        // Attempt count artır
        final existing = wrongAnswers[existingIndex];
        wrongAnswers[existingIndex] = WrongAnswerData(
          questionId: questionId,
          topicId: topicId,
          lessonId: lessonId,
          selectedAnswer: wrongAnswerDetails[questionId] ?? '',
          correctAnswer: correctAnswerDetails[questionId] ?? '',
          timestamp: DateTime.now(),
          attemptCount: existing.attemptCount + 1,
        );
      } else {
        wrongAnswers.add(WrongAnswerData(
          questionId: questionId,
          topicId: topicId,
          lessonId: lessonId,
          selectedAnswer: wrongAnswerDetails[questionId] ?? '',
          correctAnswer: correctAnswerDetails[questionId] ?? '',
          timestamp: DateTime.now(),
          attemptCount: 1,
        ));
      }
    }
    
    // Son 200 yanlış tut
    if (wrongAnswers.length > 200) {
      wrongAnswers.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      wrongAnswers.removeRange(200, wrongAnswers.length);
    }
    
    // Genel istatistikleri güncelle
    _userData = _userData.copyWith(
      quizHistory: quizHistory,
      topicProgress: topicProgress,
      wrongAnswers: wrongAnswers,
      totalQuestionsAnswered: _userData.totalQuestionsAnswered + totalQuestions,
      totalCorrectAnswers: _userData.totalCorrectAnswers + correctAnswers,
    );
    
    // Streak güncelle
    await recordStudySession();
    
    await _saveData();
  }
  
  /// Konu ilerlemesini getir
  TopicProgressData? getTopicProgress(String topicId) {
    return _userData.topicProgress[topicId];
  }
  
  /// Tüm konu ilerlemelerini getir
  Map<String, TopicProgressData> get allTopicProgress => _userData.topicProgress;
  
  /// Yanlış cevapları getir (belirli konu için)
  List<WrongAnswerData> getWrongAnswers({String? topicId}) {
    if (topicId == null) return _userData.wrongAnswers;
    return _userData.wrongAnswers.where((w) => w.topicId == topicId).toList();
  }
  
  /// Yanlış yapılan soru ID'lerini getir
  List<String> getWrongQuestionIds({String? topicId}) {
    return getWrongAnswers(topicId: topicId).map((w) => w.questionId).toSet().toList();
  }
  
  /// Tüm yanlış soruları getir (wrong_answers_page için)
  List<String> getAllWrongQuestions() {
    return _userData.wrongAnswers.map((w) => w.questionId).toSet().toList();
  }
  
  /// Soruyu öğrenildi olarak işaretle (yanlışlardan kaldır)
  Future<void> markQuestionAsLearned(String questionId) async {
    final wrongAnswers = List<WrongAnswerData>.from(_userData.wrongAnswers);
    wrongAnswers.removeWhere((w) => w.questionId == questionId);
    _userData = _userData.copyWith(wrongAnswers: wrongAnswers);
    await _saveData();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FLASHCARD İLERLEMESİ
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Flashcard ilerlemesi kaydet
  Future<void> updateFlashcardProgress({
    required String topicId,
    required int totalCards,
    required int masteredCards,
    required int learningCards,
    required int newCards,
  }) async {
    final flashcardProgress = Map<String, FlashcardProgressData>.from(_userData.flashcardProgress);
    final existing = flashcardProgress[topicId];
    
    flashcardProgress[topicId] = FlashcardProgressData(
      totalCards: totalCards,
      masteredCards: masteredCards,
      learningCards: learningCards,
      newCards: newCards,
      lastReview: DateTime.now(),
      reviewCount: (existing?.reviewCount ?? 0) + 1,
    );
    
    _userData = _userData.copyWith(flashcardProgress: flashcardProgress);
    await _saveData();
  }
  
  /// Flashcard ilerlemesini getir
  FlashcardProgressData? getFlashcardProgress(String topicId) {
    return _userData.flashcardProgress[topicId];
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FAVORİLER
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Favori ekle/çıkar
  Future<void> toggleFavorite(String topicId) async {
    final favorites = List<String>.from(_userData.favoriteTopics);
    
    if (favorites.contains(topicId)) {
      favorites.remove(topicId);
    } else {
      favorites.add(topicId);
    }
    
    _userData = _userData.copyWith(favoriteTopics: favorites);
    await _saveData();
  }
  
  /// Favori mi kontrol et
  bool isFavorite(String topicId) {
    return _userData.favoriteTopics.contains(topicId);
  }
  
  /// Tüm favorileri getir
  List<String> get favorites => _userData.favoriteTopics;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // KULLANICI BİLGİLERİ
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Kullanıcı bilgilerini güncelle (login sonrası)
  Future<void> setUserInfo({
    required String displayName,
    required String email,
    required bool isLoggedIn,
  }) async {
    _userData = _userData.copyWith(
      odisplayName: displayName,
      email: email,
      isLoggedIn: isLoggedIn,
    );
    await _saveData();
  }
  
  /// Çıkış yap (local veri silinmez, sadece login durumu değişir)
  Future<void> logout() async {
    _userData = _userData.copyWith(isLoggedIn: false);
    await _saveData();
  }
  
  /// Tüm local veriyi sil
  Future<void> clearAllData() async {
    _userData = LocalUserData();
    await _prefs?.remove(_userDataKey);
    await _prefs?.remove(_lastSyncKey);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // AYARLAR
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Ayarları güncelle
  Future<void> updateSettings(UserSettingsData settings) async {
    _userData = _userData.copyWith(settings: settings);
    await _saveData();
  }
  
  /// Ayarları getir
  UserSettingsData get settings => _userData.settings;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Son sync tarihini getir
  DateTime? get lastSyncDate {
    final dateStr = _prefs?.getString(_lastSyncKey);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }
  
  /// Sync gerekli mi? (24 saatten eski)
  bool get needsSync {
    final lastSync = lastSyncDate;
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync).inHours >= 24;
  }
  
  /// Sync tarihini güncelle
  Future<void> markSynced() async {
    await _prefs?.setString(_lastSyncKey, DateTime.now().toIso8601String());
    _userData = _userData.copyWith(lastSync: DateTime.now());
    await _saveData();
  }
  
  /// Firebase'den gelen veriyi local'e yükle
  Future<void> importFromFirebase(Map<String, dynamic> firebaseData) async {
    try {
      _userData = LocalUserData.fromJson(firebaseData);
      await _saveData();
    } catch (e) {
      // Import hatası - mevcut veriyi koru
    }
  }
  
  /// Local veriyi Firebase formatında export et
  Map<String, dynamic> exportForFirebase() {
    return _userData.toJson();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // AI ANALİZ İÇİN YARDIMCI METODLAR
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Zayıf konuları getir
  List<String> getWeakTopics() => _userData.getWeakTopics();
  
  /// Güçlü konuları getir
  List<String> getStrongTopics() => _userData.getStrongTopics();
  
  /// En çok yanlış yapılan soruları getir
  List<WrongAnswerData> getMostMissedQuestions({int limit = 10}) {
    return _userData.getMostMissedQuestions(limit: limit);
  }
  
  /// Genel başarı oranı
  double get overallSuccessRate => _userData.overallSuccessRate;
  
  /// AI için özet veri
  Map<String, dynamic> getAISummary() {
    return {
      'totalQuestionsAnswered': _userData.totalQuestionsAnswered,
      'totalCorrectAnswers': _userData.totalCorrectAnswers,
      'overallSuccessRate': overallSuccessRate,
      'currentStreak': currentStreak,
      'weakTopics': getWeakTopics(),
      'strongTopics': getStrongTopics(),
      'mostMissedQuestionCount': getMostMissedQuestions().length,
      'totalStudyTimeMinutes': _userData.totalStudyTimeMinutes,
      'quizCount': _userData.quizHistory.length,
    };
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // YARDIMCI METODLAR
  // ═══════════════════════════════════════════════════════════════════════════
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
