import 'dart:convert';

/// Kullanıcının tüm local verilerini tutan model
/// AI analizi için optimize edilmiş yapı
class LocalUserData {
  // Temel bilgiler
  final String? odisplayName;
  final String? email;
  final DateTime? lastSync;
  final bool isLoggedIn;
  
  // Streak
  final int currentStreak;
  final String? lastStudyDate; // "2025-12-04" formatında
  final int longestStreak;
  
  // Konu bazlı ilerleme
  final Map<String, TopicProgressData> topicProgress;
  
  // Yanlış cevaplar (AI analiz için detaylı)
  final List<WrongAnswerData> wrongAnswers;
  
  // Flashcard ilerlemesi
  final Map<String, FlashcardProgressData> flashcardProgress;
  
  // Quiz geçmişi (son 50)
  final List<QuizSessionData> quizHistory;
  
  // Favoriler
  final List<String> favoriteTopics;
  
  // Ayarlar
  final UserSettingsData settings;
  
  // İstatistikler
  final int totalStudyTimeMinutes;
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;

  LocalUserData({
    this.odisplayName,
    this.email,
    this.lastSync,
    this.isLoggedIn = false,
    this.currentStreak = 0,
    this.lastStudyDate,
    this.longestStreak = 0,
    Map<String, TopicProgressData>? topicProgress,
    List<WrongAnswerData>? wrongAnswers,
    Map<String, FlashcardProgressData>? flashcardProgress,
    List<QuizSessionData>? quizHistory,
    List<String>? favoriteTopics,
    UserSettingsData? settings,
    this.totalStudyTimeMinutes = 0,
    this.totalQuestionsAnswered = 0,
    this.totalCorrectAnswers = 0,
  })  : topicProgress = topicProgress ?? {},
        wrongAnswers = wrongAnswers ?? [],
        flashcardProgress = flashcardProgress ?? {},
        quizHistory = quizHistory ?? [],
        favoriteTopics = favoriteTopics ?? [],
        settings = settings ?? UserSettingsData();

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'displayName': odisplayName,
    'email': email,
    'lastSync': lastSync?.toIso8601String(),
    'isLoggedIn': isLoggedIn,
    'currentStreak': currentStreak,
    'lastStudyDate': lastStudyDate,
    'longestStreak': longestStreak,
    'topicProgress': topicProgress.map((k, v) => MapEntry(k, v.toJson())),
    'wrongAnswers': wrongAnswers.map((e) => e.toJson()).toList(),
    'flashcardProgress': flashcardProgress.map((k, v) => MapEntry(k, v.toJson())),
    'quizHistory': quizHistory.map((e) => e.toJson()).toList(),
    'favoriteTopics': favoriteTopics,
    'settings': settings.toJson(),
    'totalStudyTimeMinutes': totalStudyTimeMinutes,
    'totalQuestionsAnswered': totalQuestionsAnswered,
    'totalCorrectAnswers': totalCorrectAnswers,
  };

  factory LocalUserData.fromJson(Map<String, dynamic> json) => LocalUserData(
    odisplayName: json['displayName'] as String?,
    email: json['email'] as String?,
    lastSync: json['lastSync'] != null ? DateTime.parse(json['lastSync']) : null,
    isLoggedIn: json['isLoggedIn'] as bool? ?? false,
    currentStreak: json['currentStreak'] as int? ?? 0,
    lastStudyDate: json['lastStudyDate'] as String?,
    longestStreak: json['longestStreak'] as int? ?? 0,
    topicProgress: (json['topicProgress'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, TopicProgressData.fromJson(v as Map<String, dynamic>)),
    ),
    wrongAnswers: (json['wrongAnswers'] as List<dynamic>?)
        ?.map((e) => WrongAnswerData.fromJson(e as Map<String, dynamic>))
        .toList(),
    flashcardProgress: (json['flashcardProgress'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, FlashcardProgressData.fromJson(v as Map<String, dynamic>)),
    ),
    quizHistory: (json['quizHistory'] as List<dynamic>?)
        ?.map((e) => QuizSessionData.fromJson(e as Map<String, dynamic>))
        .toList(),
    favoriteTopics: (json['favoriteTopics'] as List<dynamic>?)?.cast<String>(),
    settings: json['settings'] != null 
        ? UserSettingsData.fromJson(json['settings'] as Map<String, dynamic>)
        : null,
    totalStudyTimeMinutes: json['totalStudyTimeMinutes'] as int? ?? 0,
    totalQuestionsAnswered: json['totalQuestionsAnswered'] as int? ?? 0,
    totalCorrectAnswers: json['totalCorrectAnswers'] as int? ?? 0,
  );

  String toJsonString() => jsonEncode(toJson());
  
  factory LocalUserData.fromJsonString(String jsonString) =>
      LocalUserData.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  // Copy with
  LocalUserData copyWith({
    String? odisplayName,
    String? email,
    DateTime? lastSync,
    bool? isLoggedIn,
    int? currentStreak,
    String? lastStudyDate,
    int? longestStreak,
    Map<String, TopicProgressData>? topicProgress,
    List<WrongAnswerData>? wrongAnswers,
    Map<String, FlashcardProgressData>? flashcardProgress,
    List<QuizSessionData>? quizHistory,
    List<String>? favoriteTopics,
    UserSettingsData? settings,
    int? totalStudyTimeMinutes,
    int? totalQuestionsAnswered,
    int? totalCorrectAnswers,
  }) {
    return LocalUserData(
      odisplayName: odisplayName ?? this.odisplayName,
      email: email ?? this.email,
      lastSync: lastSync ?? this.lastSync,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentStreak: currentStreak ?? this.currentStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      longestStreak: longestStreak ?? this.longestStreak,
      topicProgress: topicProgress ?? this.topicProgress,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      flashcardProgress: flashcardProgress ?? this.flashcardProgress,
      quizHistory: quizHistory ?? this.quizHistory,
      favoriteTopics: favoriteTopics ?? this.favoriteTopics,
      settings: settings ?? this.settings,
      totalStudyTimeMinutes: totalStudyTimeMinutes ?? this.totalStudyTimeMinutes,
      totalQuestionsAnswered: totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
    );
  }

  // AI Analiz için yardımcı metodlar
  
  /// Zayıf konuları getir (başarı oranı < 60%)
  List<String> getWeakTopics() {
    return topicProgress.entries
        .where((e) => e.value.successRate < 0.6 && e.value.attemptedQuestions >= 5)
        .map((e) => e.key)
        .toList();
  }
  
  /// Güçlü konuları getir (başarı oranı >= 80%)
  List<String> getStrongTopics() {
    return topicProgress.entries
        .where((e) => e.value.successRate >= 0.8 && e.value.attemptedQuestions >= 5)
        .map((e) => e.key)
        .toList();
  }
  
  /// En çok yanlış yapılan soruları getir
  List<WrongAnswerData> getMostMissedQuestions({int limit = 10}) {
    final grouped = <String, int>{};
    for (final wrong in wrongAnswers) {
      grouped[wrong.questionId] = (grouped[wrong.questionId] ?? 0) + 1;
    }
    
    final sorted = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) {
      return wrongAnswers.firstWhere((w) => w.questionId == e.key);
    }).toList();
  }
  
  /// Genel başarı oranı
  double get overallSuccessRate {
    if (totalQuestionsAnswered == 0) return 0;
    return totalCorrectAnswers / totalQuestionsAnswered;
  }
}

/// Konu bazlı ilerleme verisi
class TopicProgressData {
  final String lessonId;
  final String topicName;
  final int totalQuestions;
  final int attemptedQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double successRate;
  final DateTime? lastStudy;
  final int studyCount;
  final int averageTimeSeconds; // saniye/soru

  TopicProgressData({
    required this.lessonId,
    required this.topicName,
    this.totalQuestions = 0,
    this.attemptedQuestions = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.successRate = 0,
    this.lastStudy,
    this.studyCount = 0,
    this.averageTimeSeconds = 0,
  });

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'topicName': topicName,
    'totalQuestions': totalQuestions,
    'attemptedQuestions': attemptedQuestions,
    'correctAnswers': correctAnswers,
    'wrongAnswers': wrongAnswers,
    'successRate': successRate,
    'lastStudy': lastStudy?.toIso8601String(),
    'studyCount': studyCount,
    'averageTimeSeconds': averageTimeSeconds,
  };

  factory TopicProgressData.fromJson(Map<String, dynamic> json) => TopicProgressData(
    lessonId: json['lessonId'] as String? ?? '',
    topicName: json['topicName'] as String? ?? '',
    totalQuestions: json['totalQuestions'] as int? ?? 0,
    attemptedQuestions: json['attemptedQuestions'] as int? ?? 0,
    correctAnswers: json['correctAnswers'] as int? ?? 0,
    wrongAnswers: json['wrongAnswers'] as int? ?? 0,
    successRate: (json['successRate'] as num?)?.toDouble() ?? 0,
    lastStudy: json['lastStudy'] != null ? DateTime.parse(json['lastStudy']) : null,
    studyCount: json['studyCount'] as int? ?? 0,
    averageTimeSeconds: json['averageTimeSeconds'] as int? ?? 0,
  );

  TopicProgressData copyWith({
    String? lessonId,
    String? topicName,
    int? totalQuestions,
    int? attemptedQuestions,
    int? correctAnswers,
    int? wrongAnswers,
    double? successRate,
    DateTime? lastStudy,
    int? studyCount,
    int? averageTimeSeconds,
  }) {
    return TopicProgressData(
      lessonId: lessonId ?? this.lessonId,
      topicName: topicName ?? this.topicName,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      attemptedQuestions: attemptedQuestions ?? this.attemptedQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      successRate: successRate ?? this.successRate,
      lastStudy: lastStudy ?? this.lastStudy,
      studyCount: studyCount ?? this.studyCount,
      averageTimeSeconds: averageTimeSeconds ?? this.averageTimeSeconds,
    );
  }
}

/// Yanlış cevap verisi (AI analiz için detaylı)
class WrongAnswerData {
  final String questionId;
  final String topicId;
  final String lessonId;
  final String selectedAnswer;
  final String correctAnswer;
  final DateTime timestamp;
  final int attemptCount; // kaç kez yanlış yaptı

  WrongAnswerData({
    required this.questionId,
    required this.topicId,
    required this.lessonId,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.timestamp,
    this.attemptCount = 1,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'topicId': topicId,
    'lessonId': lessonId,
    'selectedAnswer': selectedAnswer,
    'correctAnswer': correctAnswer,
    'timestamp': timestamp.toIso8601String(),
    'attemptCount': attemptCount,
  };

  factory WrongAnswerData.fromJson(Map<String, dynamic> json) => WrongAnswerData(
    questionId: json['questionId'] as String? ?? '',
    topicId: json['topicId'] as String? ?? '',
    lessonId: json['lessonId'] as String? ?? '',
    selectedAnswer: json['selectedAnswer'] as String? ?? '',
    correctAnswer: json['correctAnswer'] as String? ?? '',
    timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),
    attemptCount: json['attemptCount'] as int? ?? 1,
  );
}

/// Flashcard ilerleme verisi
class FlashcardProgressData {
  final int totalCards;
  final int masteredCards;
  final int learningCards;
  final int newCards;
  final DateTime? lastReview;
  final int reviewCount;

  FlashcardProgressData({
    this.totalCards = 0,
    this.masteredCards = 0,
    this.learningCards = 0,
    this.newCards = 0,
    this.lastReview,
    this.reviewCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'totalCards': totalCards,
    'masteredCards': masteredCards,
    'learningCards': learningCards,
    'newCards': newCards,
    'lastReview': lastReview?.toIso8601String(),
    'reviewCount': reviewCount,
  };

  factory FlashcardProgressData.fromJson(Map<String, dynamic> json) => FlashcardProgressData(
    totalCards: json['totalCards'] as int? ?? 0,
    masteredCards: json['masteredCards'] as int? ?? 0,
    learningCards: json['learningCards'] as int? ?? 0,
    newCards: json['newCards'] as int? ?? 0,
    lastReview: json['lastReview'] != null ? DateTime.parse(json['lastReview']) : null,
    reviewCount: json['reviewCount'] as int? ?? 0,
  );
}

/// Quiz oturumu verisi
class QuizSessionData {
  final String id;
  final String topicId;
  final String lessonId;
  final DateTime date;
  final int totalQuestions;
  final int correctAnswers;
  final int durationSeconds;
  final List<String> wrongQuestionIds;

  QuizSessionData({
    required this.id,
    required this.topicId,
    required this.lessonId,
    required this.date,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.durationSeconds,
    List<String>? wrongQuestionIds,
  }) : wrongQuestionIds = wrongQuestionIds ?? [];

  double get successRate => totalQuestions > 0 ? correctAnswers / totalQuestions : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'topicId': topicId,
    'lessonId': lessonId,
    'date': date.toIso8601String(),
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'durationSeconds': durationSeconds,
    'wrongQuestionIds': wrongQuestionIds,
  };

  factory QuizSessionData.fromJson(Map<String, dynamic> json) => QuizSessionData(
    id: json['id'] as String? ?? '',
    topicId: json['topicId'] as String? ?? '',
    lessonId: json['lessonId'] as String? ?? '',
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    totalQuestions: json['totalQuestions'] as int? ?? 0,
    correctAnswers: json['correctAnswers'] as int? ?? 0,
    durationSeconds: json['durationSeconds'] as int? ?? 0,
    wrongQuestionIds: (json['wrongQuestionIds'] as List<dynamic>?)?.cast<String>(),
  );
}

/// Kullanıcı ayarları
class UserSettingsData {
  final bool darkMode;
  final bool notificationsEnabled;
  final int dailyGoalMinutes;
  final String preferredStudyTime; // "morning", "afternoon", "evening"

  UserSettingsData({
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.dailyGoalMinutes = 30,
    this.preferredStudyTime = 'evening',
  });

  Map<String, dynamic> toJson() => {
    'darkMode': darkMode,
    'notificationsEnabled': notificationsEnabled,
    'dailyGoalMinutes': dailyGoalMinutes,
    'preferredStudyTime': preferredStudyTime,
  };

  factory UserSettingsData.fromJson(Map<String, dynamic> json) => UserSettingsData(
    darkMode: json['darkMode'] as bool? ?? false,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    dailyGoalMinutes: json['dailyGoalMinutes'] as int? ?? 30,
    preferredStudyTime: json['preferredStudyTime'] as String? ?? 'evening',
  );
}
