import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kpss_2026/core/repositories/lesson_repository.dart';
import 'package:kpss_2026/core/services/quiz_stats_service.dart';
import 'dashboard_state.dart';

/// Dashboard cubit - manages navigation, lessons, streaks and user data
/// ⚡ OPTIMISTIC UI PATTERN: UI changes instantly, errors handled gracefully
/// ⚡ OPTIMIZED: Singleton SharedPreferences + Staggered Loading
class DashboardCubit extends Cubit<DashboardState> {
  final LessonRepository _lessonRepository;
  SharedPreferences? _prefs;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // KEYS
  // ═══════════════════════════════════════════════════════════════════════════
  static const String _keyWelcomeShown = 'welcome_card_dismissed';
  static const String _keyDailyQuestionsCompleted = 'daily_questions_completed';
  static const String _keyDailyExplanationsCompleted = 'daily_explanations_completed';
  static const String _keyDailyFlashcardsCompleted = 'daily_flashcards_completed';
  static const String _keyDailyResetDate = 'daily_reset_date';
  
  DashboardCubit({
    required LessonRepository lessonRepository,
  })  : _lessonRepository = lessonRepository,
        super(const DashboardState());

  /// Initialize dashboard - ⚡ ULTRA FAST - NO AWAIT
  void init() {
    // ⚡ Hemen başlat, await yok
    _initAsync();
  }
  
  Future<void> _initAsync() async {
    // ⚡ SharedPreferences'ı bir kez al
    _prefs ??= await SharedPreferences.getInstance();
    
    // ⚡ SİRALI ama HİÇ BEKLEMEDEN - emit'ler anında UI'a yansır
    _loadDisplayNameFast();
    _loadLessonsFast();
    _loadStreakFast();
    _loadDailyTasksFast();
  }
  
  /// ⚡ Display name - SADECE cache kullan, Firebase'e dokunma
  Future<void> _loadDisplayNameFast() async {
    // Cache'den al - Firebase'e hiç gitme
    final cachedName = _prefs?.getString('user_display_name');
    final name = (cachedName != null && cachedName.isNotEmpty) 
        ? cachedName 
        : 'Kullanıcı';
    emit(state.copyWith(displayName: name, isLoadingName: false));
  }
  
  /// ⚡ Lessons - hardcoded, anında
  Future<void> _loadLessonsFast() async {
    try {
      final lessons = await _lessonRepository.getLessons();
      emit(state.copyWith(lessons: lessons, isLoadingLessons: false));
    } catch (_) {}
  }
  
  /// ⚡ Streak - Doğrudan SharedPrefs'ten (StreakService'i bypass)
  Future<void> _loadStreakFast() async {
    try {
      // ⚡ Doğrudan _prefs kullan - ekstra getInstance() yok
      final streak = _prefs!.getInt('current_streak') ?? 0;
      
      // Haftalık veri
      final studiedDays = _prefs!.getStringList('streak_days')?.toSet() ?? {};
      final today = DateTime.now();
      final monday = today.subtract(Duration(days: today.weekday - 1));
      
      final weekData = List.generate(7, (index) {
        final date = monday.add(Duration(days: index));
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        return studiedDays.contains(key);
      });
      
      emit(state.copyWith(currentStreak: streak, weekData: weekData, isLoadingStreak: false));
    } catch (_) {
      emit(state.copyWith(isLoadingStreak: false));
    }
  }
  
  /// ⚡ Daily tasks - QuizStatsService'ten gerçek veri al
  Future<void> _loadDailyTasksFast() async {
    final welcomeDismissed = _prefs!.getBool(_keyWelcomeShown) ?? false;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastResetDate = _prefs!.getString(_keyDailyResetDate);
    
    // ⚡ Bugünkü gerçek soru çözme sayısını al
    final todayStats = await QuizStatsService.getTodayStats();
    final todaySolved = todayStats['solved'] ?? 0;
    
    // ⚡ Kaydedilmiş hedefleri yükle (varsayılan değerlerle)
    final qTarget = _prefs!.getInt('daily_questions_target') ?? 50;
    final eTarget = _prefs!.getInt('daily_explanations_target') ?? 1;
    final fTarget = _prefs!.getInt('daily_flashcards_target') ?? 20;
    
    int e = 0, f = 0;
    if (lastResetDate == todayStr) {
      e = _prefs!.getInt(_keyDailyExplanationsCompleted) ?? 0;
      f = _prefs!.getInt(_keyDailyFlashcardsCompleted) ?? 0;
    }
    
    emit(state.copyWith(
      showWelcomeCard: !welcomeDismissed,
      dailyQuestionsCompleted: todaySolved, // ⚡ Gerçek veri
      dailyExplanationsCompleted: e,
      dailyFlashcardsCompleted: f,
      dailyQuestionsTarget: qTarget,
      dailyExplanationsTarget: eTarget,
      dailyFlashcardsTarget: fTarget,
    ));
  }
  
  /// Hoşgeldin kartını kapat
  Future<void> dismissWelcomeCard() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyWelcomeShown, true);
    emit(state.copyWith(showWelcomeCard: false));
  }
  
  /// DEBUG: Hoşgeldin kartını sıfırla (test için)
  Future<void> resetWelcomeCard() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_keyWelcomeShown);
    emit(state.copyWith(showWelcomeCard: true));
  }
  
  /// Günlük görev ilerlemesini güncelle
  /// ⚡ Tüm görevler tamamlandığında streak güncellenir
  Future<void> updateDailyProgress({
    int? questionsCompleted,
    int? explanationsCompleted,
    int? flashcardsCompleted,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    
    final newQuestions = questionsCompleted ?? state.dailyQuestionsCompleted;
    final newExplanations = explanationsCompleted ?? state.dailyExplanationsCompleted;
    final newFlashcards = flashcardsCompleted ?? state.dailyFlashcardsCompleted;
    
    if (questionsCompleted != null) {
      await _prefs!.setInt(_keyDailyQuestionsCompleted, questionsCompleted);
    }
    if (explanationsCompleted != null) {
      await _prefs!.setInt(_keyDailyExplanationsCompleted, explanationsCompleted);
    }
    if (flashcardsCompleted != null) {
      await _prefs!.setInt(_keyDailyFlashcardsCompleted, flashcardsCompleted);
    }
    
    emit(state.copyWith(
      dailyQuestionsCompleted: newQuestions,
      dailyExplanationsCompleted: newExplanations,
      dailyFlashcardsCompleted: newFlashcards,
    ));
    
    // ═══════════════════════════════════════════════════════════════════════════
    // STREAK KONTROLÜ: Tüm görevler tamamlandıysa bugünü işaretle
    // ═══════════════════════════════════════════════════════════════════════════
    final allCompleted = newQuestions >= state.dailyQuestionsTarget &&
                         newExplanations >= state.dailyExplanationsTarget &&
                         newFlashcards >= state.dailyFlashcardsTarget;
    
    if (allCompleted) {
      await _markTodayAsCompleted();
    }
  }
  
  /// Bugünü tamamlandı olarak işaretle ve streak'i güncelle
  Future<void> _markTodayAsCompleted() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // Çalışılan günleri al ve bugünü ekle
    final studiedDays = _prefs!.getStringList('streak_days')?.toSet() ?? {};
    if (!studiedDays.contains(todayKey)) {
      studiedDays.add(todayKey);
      await _prefs!.setStringList('streak_days', studiedDays.toList());
      
      // Streak'i güncelle
      final newStreak = (state.currentStreak) + 1;
      await _prefs!.setInt('current_streak', newStreak);
      emit(state.copyWith(currentStreak: newStreak));
    }
  }
  
  /// Son çalışma durumunu güncelle
  void updateLastStudyStatus(bool hasLastStudy) {
    emit(state.copyWith(hasLastStudy: hasLastStudy));
  }

  /// Change selected tab index
  void changeTab(int index) {
    emit(state.copyWith(selectedIndex: index));
  }

  /// Refresh lessons (pull-to-refresh)
  Future<void> refreshLessons() async {
    try {
      final lessons = await _lessonRepository.refreshLessons();
      emit(state.copyWith(lessons: lessons, lessonsError: null));
    } catch (_) {}
  }

  /// ⚡ Tüm istatistikleri yenile - Quiz/Flashcard'dan dönünce çağrılır
  Future<void> refreshStats() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadStreakFast();
    await _loadDailyTasksFast();
  }

  /// Günlük hedefleri güncelle (kullanıcı ayarlarından)
  Future<void> updateDailyTargets({
    int? questions,
    int? explanations,
    int? flashcards,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    
    final newQuestionsTarget = questions ?? state.dailyQuestionsTarget;
    final newExplanationsTarget = explanations ?? state.dailyExplanationsTarget;
    final newFlashcardsTarget = flashcards ?? state.dailyFlashcardsTarget;
    
    // SharedPreferences'a kaydet
    await _prefs!.setInt('daily_questions_target', newQuestionsTarget);
    await _prefs!.setInt('daily_explanations_target', newExplanationsTarget);
    await _prefs!.setInt('daily_flashcards_target', newFlashcardsTarget);
    
    emit(state.copyWith(
      dailyQuestionsTarget: newQuestionsTarget,
      dailyExplanationsTarget: newExplanationsTarget,
      dailyFlashcardsTarget: newFlashcardsTarget,
    ));
  }
}
