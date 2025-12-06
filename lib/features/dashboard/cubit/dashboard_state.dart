import 'package:equatable/equatable.dart';
import 'package:kpss_2026/core/models/lesson_model.dart';

/// Dashboard state - Manages all dashboard data
class DashboardState extends Equatable {
  final int selectedIndex;
  final String? displayName;
  final bool isLoadingName;
  final List<LessonModel> lessons;
  final bool isLoadingLessons;
  final String? lessonsError;
  final int currentStreak;
  final List<bool> weekData;
  final bool isLoadingStreak;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // YENİ: Hoşgeldin kartı ve günlük görevler
  // ═══════════════════════════════════════════════════════════════════════════
  final bool showWelcomeCard;  // İlk kullanıcılar için hoşgeldin kartı
  final bool hasLastStudy;     // Kaldığın yerden devam kartı var mı?
  
  // Günlük görevler
  final int dailyQuestionsTarget;
  final int dailyQuestionsCompleted;
  final int dailyExplanationsTarget;
  final int dailyExplanationsCompleted;
  final int dailyFlashcardsTarget;
  final int dailyFlashcardsCompleted;

  const DashboardState({
    this.selectedIndex = 0,
    this.displayName,
    this.isLoadingName = false,
    this.lessons = const [],
    this.isLoadingLessons = true,
    this.lessonsError,
    this.currentStreak = 0,
    this.weekData = const [false, false, false, false, false, false, false],
    this.isLoadingStreak = false,
    this.showWelcomeCard = true,
    this.hasLastStudy = false,
    this.dailyQuestionsTarget = 50,
    this.dailyQuestionsCompleted = 0,
    this.dailyExplanationsTarget = 1,
    this.dailyExplanationsCompleted = 0,
    this.dailyFlashcardsTarget = 20,
    this.dailyFlashcardsCompleted = 0,
  });

  DashboardState copyWith({
    int? selectedIndex,
    String? displayName,
    bool? isLoadingName,
    List<LessonModel>? lessons,
    bool? isLoadingLessons,
    String? lessonsError,
    int? currentStreak,
    List<bool>? weekData,
    bool? isLoadingStreak,
    bool? showWelcomeCard,
    bool? hasLastStudy,
    int? dailyQuestionsTarget,
    int? dailyQuestionsCompleted,
    int? dailyExplanationsTarget,
    int? dailyExplanationsCompleted,
    int? dailyFlashcardsTarget,
    int? dailyFlashcardsCompleted,
  }) {
    return DashboardState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      displayName: displayName ?? this.displayName,
      isLoadingName: isLoadingName ?? this.isLoadingName,
      lessons: lessons ?? this.lessons,
      isLoadingLessons: isLoadingLessons ?? this.isLoadingLessons,
      lessonsError: lessonsError,
      currentStreak: currentStreak ?? this.currentStreak,
      weekData: weekData ?? this.weekData,
      isLoadingStreak: isLoadingStreak ?? this.isLoadingStreak,
      showWelcomeCard: showWelcomeCard ?? this.showWelcomeCard,
      hasLastStudy: hasLastStudy ?? this.hasLastStudy,
      dailyQuestionsTarget: dailyQuestionsTarget ?? this.dailyQuestionsTarget,
      dailyQuestionsCompleted: dailyQuestionsCompleted ?? this.dailyQuestionsCompleted,
      dailyExplanationsTarget: dailyExplanationsTarget ?? this.dailyExplanationsTarget,
      dailyExplanationsCompleted: dailyExplanationsCompleted ?? this.dailyExplanationsCompleted,
      dailyFlashcardsTarget: dailyFlashcardsTarget ?? this.dailyFlashcardsTarget,
      dailyFlashcardsCompleted: dailyFlashcardsCompleted ?? this.dailyFlashcardsCompleted,
    );
  }
  
  /// Günlük görevlerin tamamlanma yüzdesi
  double get dailyProgress {
    final total = dailyQuestionsTarget + dailyExplanationsTarget + dailyFlashcardsTarget;
    final completed = dailyQuestionsCompleted + dailyExplanationsCompleted + dailyFlashcardsCompleted;
    if (total == 0) return 0;
    return (completed / total).clamp(0.0, 1.0);
  }

  /// Tüm günlük hedefler tamamlandı mı? (Her biri ayrı ayrı)
  bool get isAllGoalsCompleted {
    return dailyQuestionsCompleted >= dailyQuestionsTarget &&
           dailyExplanationsCompleted >= dailyExplanationsTarget &&
           dailyFlashcardsCompleted >= dailyFlashcardsTarget;
  }

  @override
  List<Object?> get props => [
        selectedIndex,
        displayName,
        isLoadingName,
        lessons,
        isLoadingLessons,
        lessonsError,
        currentStreak,
        weekData,
        isLoadingStreak,
        showWelcomeCard,
        hasLastStudy,
        dailyQuestionsTarget,
        dailyQuestionsCompleted,
        dailyExplanationsTarget,
        dailyExplanationsCompleted,
        dailyFlashcardsTarget,
        dailyFlashcardsCompleted,
      ];
}
