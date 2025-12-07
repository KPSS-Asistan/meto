import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/question_model.dart';
import '../../../core/repositories/question_repository.dart';
import '../../../core/repositories/progress_repository.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/user_data_service.dart';
import '../../../core/services/quiz_session_service.dart';
import '../../../core/services/quiz_stats_service.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/services/local_progress_service.dart';
import '../../../core/data/topics_data.dart';

import 'quiz_state.dart';

class QuizCubit extends Cubit<QuizState> {
  final QuestionRepository _repository;
  final ProgressRepository _progressRepository;
  String? _currentTopicId;
  bool _isNavigatingBack = false; // Geri dönüş flag'i - açıklama gösterme

  QuizCubit(this._repository, this._progressRepository) : super(const QuizState.initial());

  /// Geri dönüş mü kontrol et (açıklama gösterilmemeli)
  bool get isNavigatingBack => _isNavigatingBack;

  /// Quiz yükle - Aktif oturum varsa devam et, yoksa yeni başlat
  Future<void> loadQuiz(String topicId) async {
    try {
      emit(const QuizState.loading());
      _currentTopicId = topicId;
      AppLogger.debug('QuizCubit: Starting to load quiz for topic: $topicId');
      
      // 1. Aktif oturum var mı kontrol et
      final activeSession = await QuizSessionService.getActiveSession(topicId);
      
      if (activeSession != null) {
        // Aktif oturum var - devam et
        AppLogger.debug('QuizCubit: Resuming active session with ${activeSession.shuffledQuestionIds.length} questions');
        await _resumeSession(activeSession);
        return;
      }
      
      // 2. Yeni oturum başlat - Firebase'den soruları çek
      final questionsStream = _repository.getQuestionsByTopic(topicId);
      
      final allQuestions = await questionsStream
          .timeout(
            const Duration(seconds: 10),
            onTimeout: (sink) {
              AppLogger.error('Quiz load timeout', 'No response in 10 seconds');
              sink.addError('Sorular yüklenirken zaman aşımı oluştu. Lütfen tekrar deneyin.');
            },
          )
          .first;
      
      AppLogger.debug('QuizCubit: Received ${allQuestions.length} questions for topic $topicId');
      
      if (allQuestions.isEmpty) {
        AppLogger.warning('QuizCubit: No questions found for topic $topicId');
        emit(const QuizState.error(
          'Bu konu için henüz soru hazırlanmamış. 📚\n\nDiğer konuları keşfetmeye devam et veya biraz sonra tekrar dene!',
        ));
        return;
      }

      // 2.1 Çözülmüş soruları filtrele
      List<QuestionModel> questionsToAsk = allQuestions;
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId != null) {
        final solvedIds = await _progressRepository.getSolvedQuestionIds(userId, topicId);
        final unsolvedQuestions = allQuestions.where((q) => !solvedIds.contains(q.id)).toList();
        
        if (unsolvedQuestions.isNotEmpty) {
          questionsToAsk = unsolvedQuestions;
          AppLogger.debug('QuizCubit: Filtered ${solvedIds.length} solved questions. Remaining: ${questionsToAsk.length}');
        } else {
          // Hepsi çözülmüşse, hepsini tekrar sor (veya kullanıcıya sorulabilir)
          AppLogger.debug('QuizCubit: All questions solved. Restarting with all questions.');
          questionsToAsk = allQuestions;
        }
      }
      
      // 3. Rastgele 20 soru seç (veya mevcut sayı kadar)
      final shuffled = List<QuestionModel>.from(questionsToAsk)..shuffle();
      final questionCount = questionsToAsk.length < QuizSessionService.maxQuestions 
          ? questionsToAsk.length 
          : QuizSessionService.maxQuestions;
      final selectedQuestions = shuffled.take(questionCount).toList();
      
      // 4. Oturumu kaydet
      await QuizSessionService.startSession(
        topicId: topicId,
        questionIds: selectedQuestions.map((q) => q.id).toList(),
        shuffledQuestionIds: selectedQuestions.map((q) => q.id).toList(),
      );
      
      AppLogger.debug('QuizCubit: Started new session with $questionCount questions');
      
      // 5. Kalan süreyi al
      final remainingSeconds = await QuizSessionService.getRemainingTime(topicId);
      
      emit(QuizState.loaded(
        questions: selectedQuestions,
        currentQuestionIndex: 0,
        userAnswers: {},
        selectedOption: null,
        isAnswered: false,
        remainingSeconds: remainingSeconds,
        topicId: topicId,
      ));
    } catch (e, stackTrace) {
      AppLogger.error('QuizCubit: Quiz load failed', e, stackTrace);
      emit(QuizState.error('Sorular yüklenirken hata oluştu.\n\nLütfen internet bağlantınızı kontrol edin ve tekrar deneyin.'));
    }
  }

  /// Aktif oturumu devam ettir
  Future<void> _resumeSession(QuizSession session) async {
    try {
      // Soru ID'lerinden soruları çek
      final questions = await _repository.getQuestionsByIds(session.shuffledQuestionIds);
      
      if (questions.isEmpty) {
        AppLogger.error('QuizCubit: Failed to load questions for session');
        await QuizSessionService.clearSession(session.topicId);
        emit(const QuizState.error('Oturum yüklenemedi. Lütfen tekrar deneyin.'));
        return;
      }
      
      // Soruları oturumdaki sıraya göre sırala
      final orderedQuestions = <QuestionModel>[];
      for (final id in session.shuffledQuestionIds) {
        final question = questions.firstWhere(
          (q) => q.id == id,
          orElse: () => questions.first,
        );
        orderedQuestions.add(question);
      }
      
      final remainingSeconds = await QuizSessionService.getRemainingTime(session.topicId);
      
      emit(QuizState.loaded(
        questions: orderedQuestions,
        currentQuestionIndex: session.currentIndex,
        userAnswers: session.userAnswers,
        selectedOption: null,
        isAnswered: session.userAnswers.containsKey(session.currentIndex),
        remainingSeconds: remainingSeconds,
        topicId: session.topicId,
      ));
      
      AppLogger.debug('QuizCubit: Resumed session at index ${session.currentIndex}');
    } catch (e, stackTrace) {
      AppLogger.error('QuizCubit: Failed to resume session', e, stackTrace);
      await QuizSessionService.clearSession(session.topicId);
      emit(const QuizState.error('Oturum devam ettirilemedi. Lütfen tekrar deneyin.'));
    }
  }

  void selectOption(String option) {
    state.mapOrNull(
      loaded: (state) {
        emit(state.copyWith(selectedOption: option));
      },
    );
  }

  void submitAnswer() {
    _isNavigatingBack = false; // Yeni cevap - açıklama gösterilebilir
    state.mapOrNull(
      loaded: (state) {
        if (state.selectedOption == null) return;

        final newAnswers = Map<int, String>.from(state.userAnswers);
        newAnswers[state.currentQuestionIndex] = state.selectedOption!;

        // Cevabın doğru olup olmadığını kontrol et
        final currentQuestion = state.questions[state.currentQuestionIndex];
        final isCorrect = state.selectedOption == currentQuestion.correctAnswer;
        
        // Topic adını ve lessonId'yi bul
        String? topicName;
        String? lessonId = currentQuestion.lessonId;
        
        if (state.topicId != null) {
          final topic = topicsData.firstWhere(
            (t) => t['id'] == state.topicId,
            orElse: () => <String, dynamic>{},
          );
          topicName = topic['name'] as String?;
          
          // Eğer question'da lessonId boşsa, topic'ten al
          if (lessonId.isEmpty) {
            lessonId = topic['lesson_id'] as String?;
          }
        }
        
        // ⚡ İstatistikleri ANINDA kaydet (QuizStatsService)
        QuizStatsService.recordAnswer(
          isCorrect: isCorrect,
          lessonId: lessonId,
          topicId: state.topicId,
          topicName: topicName,
        );
        
        // ⚡ LocalProgressService'e de ANINDA kaydet
        _recordAnswerToLocalProgress(
          question: currentQuestion,
          selectedAnswer: state.selectedOption!,
          isCorrect: isCorrect,
        );
        
        emit(state.copyWith(
          userAnswers: newAnswers,
          isAnswered: true,
        ));
        
        // Oturum ilerlemesini kaydet
        if (state.topicId != null) {
          QuizSessionService.updateProgress(
            topicId: state.topicId!,
            currentIndex: state.currentQuestionIndex,
            userAnswers: newAnswers,
          );
        }
      },
    );
  }

  /// ⚡ Her cevabı anında LocalProgressService'e kaydet
  Future<void> _recordAnswerToLocalProgress({
    required QuestionModel question,
    required String selectedAnswer,
    required bool isCorrect,
  }) async {
    try {
      final progressService = await LocalProgressService.getInstance();
      
      // Konu adını topicsData'dan al
      final topicData = topicsData.firstWhere(
        (t) => t['id'] == question.topicId,
        orElse: () => {'name': '', 'lesson_id': ''},
      );
      final topicName = topicData['name'] as String? ?? '';
      
      // Tek soru için mini quiz result kaydet
      await progressService.recordQuizResult(
        topicId: question.topicId,
        lessonId: question.lessonId,
        topicName: topicName,
        totalQuestions: 1,
        correctAnswers: isCorrect ? 1 : 0,
        durationSeconds: 0,
        wrongQuestionIds: isCorrect ? [] : [question.id],
        wrongAnswerDetails: isCorrect ? {} : {question.id: selectedAnswer},
        correctAnswerDetails: isCorrect ? {} : {question.id: question.correctAnswer},
      );
    } catch (e) {
      AppLogger.error('Failed to record answer to LocalProgress', e);
    }
  }

  /// Önceki soruya dön (sadece görüntüleme, tekrar çözülemez, açıklama gösterilmez)
  void previousQuestion() {
    _isNavigatingBack = true; // Açıklama gösterme
    state.mapOrNull(
      loaded: (state) {
        if (state.currentQuestionIndex > 0) {
          final prevIndex = state.currentQuestionIndex - 1;
          final previousAnswer = state.userAnswers[prevIndex];
          
          emit(state.copyWith(
            currentQuestionIndex: prevIndex,
            selectedOption: previousAnswer,
            isAnswered: true, // Çözülmüş olarak göster, tekrar çözülemesin
          ));
        }
      },
    );
  }

  void nextQuestion() {
    state.mapOrNull(
      loaded: (state) {
        final nextIndex = state.currentQuestionIndex + 1;
        
        if (nextIndex >= state.questions.length) {
          // Quiz finished - oturumu tamamla
          int score = 0;
          for (int i = 0; i < state.questions.length; i++) {
            if (state.userAnswers[i] == state.questions[i].correctAnswer) {
              score++;
            }
          }
          
          // Oturumu tamamlandı olarak işaretle
          if (state.topicId != null) {
            QuizSessionService.completeSession(state.topicId!);
            // NOT: Her soru zaten anında kaydediliyor, burada tekrar kaydetmeye gerek yok
          }
          
          // ⚡ Streak'i işaretle - quiz tamamlandı
          StreakService.markTodayAsStudied();
          
          emit(QuizState.finished(
            questions: state.questions,
            userAnswers: state.userAnswers,
            score: score,
          ));
        } else {
          // Check if we have an answer for the next question (when navigating forward)
          final existingAnswer = state.userAnswers[nextIndex];
          
          emit(state.copyWith(
            currentQuestionIndex: nextIndex,
            selectedOption: existingAnswer, // Restore answer if exists
            isAnswered: existingAnswer != null, // Set answered flag
          ));
          
          // Oturum ilerlemesini kaydet
          if (state.topicId != null) {
            QuizSessionService.updateProgress(
              topicId: state.topicId!,
              currentIndex: nextIndex,
              userAnswers: state.userAnswers,
            );
          }
        }
      },
    );
  }

  /// Testi yeniden başlat (yeni sorularla)
  Future<void> restart() async {
    if (_currentTopicId == null) return;
    
    await QuizSessionService.clearSession(_currentTopicId!);
    await loadQuiz(_currentTopicId!);
  }

  /// Süre dolduğunda testi bitir
  void timeUp() {
    state.mapOrNull(
      loaded: (state) {
        int score = 0;
        for (int i = 0; i < state.questions.length; i++) {
          if (state.userAnswers[i] == state.questions[i].correctAnswer) {
            score++;
          }
        }
        
        // Oturumu tamamla
        if (state.topicId != null) {
          QuizSessionService.completeSession(state.topicId!);
          // NOT: Her soru zaten anında kaydediliyor, burada tekrar kaydetmeye gerek yok
        }
        
        // ⚡ Streak'i işaretle - quiz tamamlandı
        StreakService.markTodayAsStudied();
        
        emit(QuizState.finished(
          questions: state.questions,
          userAnswers: state.userAnswers,
          score: score,
        ));
      },
    );
  }

  /// Kalan süreyi güncelle
  void updateRemainingTime(int seconds) {
    state.mapOrNull(
      loaded: (state) {
        emit(state.copyWith(remainingSeconds: seconds));
        
        // Her 5 saniyede bir veya kritik durumlarda süreyi kaydet
        if (state.topicId != null && seconds % 5 == 0) {
          QuizSessionService.updateRemainingTime(state.topicId!, seconds);
        }
      },
    );
  }

  /// Quiz'den çıkarken durumu kaydet (Pause)
  Future<void> pauseQuiz() async {
    await state.maybeMap(
      loaded: (state) async {
        if (state.topicId != null) {
          // Hem süreyi hem de cevapları kaydet
          await QuizSessionService.updateProgress(
            topicId: state.topicId!,
            currentIndex: state.currentQuestionIndex,
            userAnswers: state.userAnswers,
          );
          await QuizSessionService.updateRemainingTime(state.topicId!, state.remainingSeconds);
          AppLogger.debug('QuizCubit: Paused quiz at index ${state.currentQuestionIndex} with ${state.remainingSeconds}s remaining');
        }
      },
      orElse: () async {},
    );
  }

  // Favori İşlemleri
  Future<void> toggleFavorite(String questionId) async {
    await UserDataService.toggleFavorite(questionId);
  }

  Future<bool> checkFavoriteStatus(String questionId) async {
    return await UserDataService.isFavorite(questionId);
  }
}
