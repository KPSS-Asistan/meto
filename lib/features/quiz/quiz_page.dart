import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/quiz_analysis_service.dart';
import '../../core/models/question_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';
import 'package:kpss_2026/features/dashboard/cubit/dashboard_cubit.dart';
import '../../core/repositories/progress_repository.dart';
import '../../core/repositories/question_repository.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/formatted_question_text.dart';
import '../../core/widgets/loading_overlay.dart';
import 'cubit/quiz_cubit.dart';
import 'cubit/quiz_state.dart';
import 'widgets/ai_analysis_button.dart';
import 'widgets/favorite_button.dart';
import 'widgets/option_card.dart';
import 'widgets/report_dialog.dart';
import 'widgets/stat_card.dart';

class QuizPage extends StatelessWidget {
  final String lessonId;
  final String topicId;
  final String topicName;

  const QuizPage({
    super.key,
    required this.lessonId,
    required this.topicId,
    required this.topicName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuizCubit(
        context.read<QuestionRepository>(),
        context.read<ProgressRepository>(),
      )..loadQuiz(topicId),
      child: _QuizView(
        lessonId: lessonId,
        topicId: topicId,
        topicName: topicName,
      ),
    );
  }
}

class _QuizView extends StatefulWidget {
  final String lessonId;
  final String topicId;
  final String topicName;

  const _QuizView({
    required this.lessonId,
    required this.topicId,
    required this.topicName,
  });

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  Timer? _timer;
  int _remainingSeconds = 1200; // 20 dakika
  bool _timerStarted = false;

  @override
  void dispose() {
    _timer?.cancel();
    if (mounted) {
      context.read<QuizCubit>().pauseQuiz();
    }
    super.dispose();
  }

  void _startTimer(int initialSeconds) {
    if (_timerStarted) return;
    _timerStarted = true;
    _remainingSeconds = initialSeconds;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        
        if (mounted) {
          context.read<QuizCubit>().updateRemainingTime(_remainingSeconds);
        }
      } else {
        timer.cancel();
        if (mounted) {
          context.read<QuizCubit>().timeUp();
        }
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<QuizCubit, QuizState>(
          listenWhen: (previous, current) {
            return previous.maybeMap(
              loaded: (p) => current.maybeMap(
                loaded: (c) => 
                  p.isAnswered != c.isAnswered || 
                  p.currentQuestionIndex != c.currentQuestionIndex,
                orElse: () => true,
              ),
              orElse: () => true,
            );
          },
          listener: (context, state) {
            state.mapOrNull(
              loading: (_) {
                _timer?.cancel();
                _timerStarted = false;
              },
              loaded: (loadedState) {
                if (!_timerStarted) {
                  _startTimer(loadedState.remainingSeconds);
                }
                
                if (loadedState.isAnswered && 
                    loadedState.selectedOption != null) {
                  final question = loadedState.questions[loadedState.currentQuestionIndex];
                  final isCorrect = loadedState.selectedOption == question.correctAnswer;
                  
                  _saveProgress(context, question.id, isCorrect);
                  
                  final cubit = context.read<QuizCubit>();
                  if (!isCorrect && question.explanation != null && !cubit.isNavigatingBack) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showExplanationSheet(context, question.explanation!);
                    });
                  }
                }
              },
              finished: (_) {
                _timer?.cancel();
              },
            );
          },
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const LoadingIndicator(
                message: 'Sorular yükleniyor...',
              ),
              error: (msg) => ErrorState(
                message: msg,
                onRetry: () => context.pop(),
              ),
              finished: (questions, userAnswers, score) => _buildFinished(
                context,
                questions,
                userAnswers,
                score,
              ),
              loaded: (questions, currentIndex, userAnswers, selectedOption, isAnswered, remainingSeconds, topicId) {
                final question = questions[currentIndex];
                final totalQuestions = questions.length;
                
                final timerColor = _remainingSeconds <= 300 
                    ? const Color(0xFFEF4444) 
                    : const Color(0xFF6366F1);

                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 24),
                                onPressed: () => _showExitConfirmation(context),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.background,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _showReportDialog(context, question.id),
                                icon: const Icon(Icons.flag_outlined, size: 22),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.background,
                                  foregroundColor: const Color(0xFF6B7280),
                                ),
                                tooltip: 'Hata Bildir',
                              ),
                              const SizedBox(width: 8),
                              FavoriteButton(questionId: question.id),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: timerColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 18,
                                      color: timerColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatTime(_remainingSeconds),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: timerColor,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${currentIndex + 1}/$totalQuestions',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Question & Options
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 32,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FormattedQuestionText(
                                    text: question.questionText,
                                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.02),
                                  
                                  const SizedBox(height: 24),

                                  ...question.options.entries.map((entry) {
                                    final optionKey = entry.key;
                                    final optionText = entry.value;
                                    final isSelected = selectedOption == optionKey;
                                    final isCorrect = optionKey == question.correctAnswer;
                                    final showResult = isAnswered;

                                    return OptionCard(
                                      optionKey: optionKey,
                                      optionText: optionText,
                                      isSelected: isSelected,
                                      isCorrect: isCorrect,
                                      showResult: showResult,
                                      onTap: isAnswered
                                          ? null
                                          : () => context.read<QuizCubit>().selectOption(optionKey),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Row(
                        children: [
                          if (currentIndex > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: OutlinedButton(
                                onPressed: () => context.read<QuizCubit>().previousQuestion(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6B7280),
                                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Icon(Icons.arrow_back_rounded, size: 20),
                              ),
                            ),
                          Expanded(
                            child: FilledButton(
                              onPressed: selectedOption == null
                                  ? null
                                  : () {
                                      if (!isAnswered) {
                                        context.read<QuizCubit>().submitAnswer();
                                      } else {
                                        context.read<QuizCubit>().nextQuestion();
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: const Color(0xFFE5E7EB),
                                foregroundColor: Colors.white,
                                disabledForegroundColor: const Color(0xFF9CA3AF),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                isAnswered
                                    ? (currentIndex + 1 < totalQuestions
                                        ? 'Devam Et'
                                        : 'Sonuçlarý Gör')
                                    : 'Cevapla',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.exit_to_app_rounded,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Testten Çýk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ýlerlemeniz kaydedilecek ve kaldýðýnýz yerden devam edebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Devam Et',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await context.read<QuizCubit>().pauseQuiz();
                      if (context.mounted) {
                        try {
                          context.read<DashboardCubit>().refreshStats();
                        } catch (_) {}
                        context.pop();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Çýk',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, String questionId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Kapat',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value,
          child: Opacity(
            opacity: anim1.value,
            child: ReportDialog(questionId: questionId),
          ),
        );
      },
    );
  }

  Future<void> _saveProgress(
    BuildContext context,
    String questionId,
    bool isCorrect,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await context.read<ProgressRepository>().saveProgress(
            userId: userId,
            questionId: questionId,
            topicId: widget.topicId,
            topicName: widget.topicName,
            isCorrect: isCorrect,
            contentType: 'question',
          );
    } catch (e) {
      AppLogger.error('Quiz progress save failed', e);
    }
  }

  void _showExplanationSheet(BuildContext context, String explanation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  explanation,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Color(0xFF374151),
                    letterSpacing: 0.1,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Anladým',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinished(
    BuildContext context,
    List<QuestionModel> questions,
    Map<int, String> userAnswers,
    int score,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<DashboardCubit>().refreshStats();
      } catch (_) {}
    });

    final totalQuestions = questions.length;
    final percentage = (score / totalQuestions * 100).round();
    final wrongCount = totalQuestions - score;

    // Wrong Questions Hazýrlýðý
    final wrongQuestionsList = <WrongQuestionInfo>[];
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final userAnswer = userAnswers[i];
      if (userAnswer != null && userAnswer != q.correctAnswer) {
        wrongQuestionsList.add(WrongQuestionInfo(
          questionId: q.id,
          questionText: q.questionText,
          userAnswer: userAnswer,
          correctAnswer: q.correctAnswer,
          subtopicId: q.subtopicId, 
          subtopicName: q.subtopicName, 
        ));
      }
    }
    
    Color primaryColor;
    Color bgColor;
    IconData icon;
    String message;
    
    if (percentage >= 80) {
      primaryColor = const Color(0xFF10B981);
      bgColor = const Color(0xFFECFDF5);
      icon = Icons.emoji_events_rounded;
      message = 'Mükemmel!';
    } else if (percentage >= 60) {
      primaryColor = const Color(0xFF6366F1);
      bgColor = const Color(0xFFEEF2FF);
      icon = Icons.thumb_up_rounded;
      message = 'Ýyi Gidiyorsun!';
    } else if (percentage >= 40) {
      primaryColor = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFFFBEB);
      icon = Icons.trending_up_rounded;
      message = 'Geliþtirebilirsin';
    } else {
      primaryColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEF2F2);
      icon = Icons.refresh_rounded;
      message = 'Tekrar Dene';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 3),
              ),
              child: Icon(icon, size: 64, color: primaryColor),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 24),
            
            Text(
              message,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    value: '$score',
                    label: 'Doðru',
                    color: const Color(0xFF10B981),
                    bgColor: const Color(0xFFECFDF5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    value: '$wrongCount',
                    label: 'Yanlýþ',
                    color: const Color(0xFFEF4444),
                    bgColor: const Color(0xFFFEF2F2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    value: '%$percentage',
                    label: 'Baþarý',
                    color: primaryColor,
                    bgColor: bgColor,
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 20),
          
          AIAnalysisButton(
            topicId: widget.topicId,
            topicName: widget.topicName,
            totalQuestions: totalQuestions,
            correctAnswers: score,
            wrongAnswers: wrongCount,
            successRate: percentage.toDouble(),
            wrongQuestions: wrongQuestionsList,
          ),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.read<QuizCubit>().restart(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Tekrar Dene',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Ana Sayfaya Dön',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
