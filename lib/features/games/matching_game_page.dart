import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/theme_aware_header.dart';
import 'cubit/game_cubit.dart';
import 'cubit/game_state.dart';

/// Eşleştirme Oyunu - Minimal & Professional
class MatchingGamePage extends StatelessWidget {
  final String lessonId;
  final String topicId;
  final String topicName;

  const MatchingGamePage({
    super.key,
    required this.lessonId,
    required this.topicId,
    required this.topicName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameCubit()..loadMatchingGame(topicId),
      child: _MatchingGameView(topicName: topicName),
    );
  }
}

class _MatchingGameView extends StatefulWidget {
  final String topicName;

  const _MatchingGameView({required this.topicName});

  @override
  State<_MatchingGameView> createState() => _MatchingGameViewState();
}

class _MatchingGameViewState extends State<_MatchingGameView> {
  // Oyun verileri
  List<Map<String, String>> _selectedPairs = []; // Rastgele seçilen 8 çift
  List<String> _shuffledAnswers = [];
  bool _answersShuffled = false;
  
  static const int _maxPairs = 8; // Her oyunda maksimum 8 çift
  
  // Zamanlayıcı
  Timer? _timer;
  int _elapsedSeconds = 0;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: BlocConsumer<GameCubit, GameState>(
          listener: (context, state) {
            // Rastgele 8 çift seç ve cevapları karıştır
            if (!_answersShuffled && state.matchingPairs.isNotEmpty) {
              // Rastgele 8 çift seç (veya daha az varsa hepsini al)
              final allPairs = List<Map<String, String>>.from(state.matchingPairs);
              allPairs.shuffle();
              _selectedPairs = allPairs.take(_maxPairs).toList();
              
              // Cevapları karıştır
              _shuffledAnswers = _selectedPairs.map((p) => p['answer']!).toList()..shuffle();
              _answersShuffled = true;
              _startTimer();
            }

            // Oyun bitti
            if (state.isGameOver) {
              _timer?.cancel();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showCompletionDialog(context, state);
              });
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return _buildLoadingState(isDark);
            }

            if (state.error != null) {
              return _buildErrorState(state.error!, isDark);
            }

            final pairs = state.matchingPairs;
            if (pairs.isEmpty) {
              return _buildEmptyState(isDark);
            }

            // Seçilen çift sayısını kullan
            final activePairCount = _selectedPairs.isNotEmpty ? _selectedPairs.length : pairs.length.clamp(0, _maxPairs);

            return Column(
              children: [
                // Header - ThemeAwareHeader ile tutarlı tasarım
                ThemeAwareHeader(
                  title: 'Eşleştirme Oyunu',
                  subtitle: '${widget.topicName} • ${_formatTime(_elapsedSeconds)} • ${state.score}/$activePairCount',
                  onClose: () => _showExitDialog(context),
                ),

                // Oyun alanı - ortalanmış
                Expanded(
                  child: _buildGameArea(pairs, state, isDark),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Oyun hazırlanıyor...',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea(List<Map<String, String>> pairs, GameState state, bool isDark) {
    // Seçilen çiftleri kullan (yoksa orijinal pairs'i kullan)
    final activePairs = _selectedPairs.isNotEmpty ? _selectedPairs : pairs.take(_maxPairs).toList();
    final questions = activePairs.map((p) => p['question']!).toList();
    final answers = _shuffledAnswers.isNotEmpty ? _shuffledAnswers : activePairs.map((p) => p['answer']!).toList();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Kavramlar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Tanımlar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Sol sütun: Kavramlar
              Expanded(
                child: Column(
                  children: List.generate(questions.length, (index) {
                    final item = questions[index];
                    final isMatched = state.matchedPairs.contains(item);
                    final isSelected = state.selectedQuestion == item;

                    return Padding(
                      padding: EdgeInsets.only(bottom: index < questions.length - 1 ? 12 : 0),
                      child: _GameCard(
                        text: item,
                        isMatched: isMatched,
                        isSelected: isSelected,
                        isDark: isDark,
                        isQuestion: true,
                        onTap: () {
                          if (!isMatched) {
                            HapticFeedback.selectionClick();
                            context.read<GameCubit>().selectQuestion(item);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _checkMatchAfterSelection(context, item, null);
                            });
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Sağ sütun: Tanımlar
              Expanded(
                child: Column(
                  children: List.generate(answers.length, (index) {
                    final item = answers[index];
                    final isMatched = state.matchedPairs.contains(item);
                    final isSelected = state.selectedAnswer == item;

                    return Padding(
                      padding: EdgeInsets.only(bottom: index < answers.length - 1 ? 12 : 0),
                      child: _GameCard(
                        text: item,
                        isMatched: isMatched,
                        isSelected: isSelected,
                        isDark: isDark,
                        isQuestion: false,
                        onTap: () {
                          if (!isMatched) {
                            HapticFeedback.selectionClick();
                            context.read<GameCubit>().selectAnswer(item);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _checkMatchAfterSelection(context, null, item);
                            });
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkMatchAfterSelection(BuildContext context, String? newQuestion, String? newAnswer) {
    final state = context.read<GameCubit>().state;
    final selectedQ = newQuestion ?? state.selectedQuestion;
    final selectedA = newAnswer ?? state.selectedAnswer;
    
    // Her iki taraf da seçilmişse kontrol et
    if (selectedQ != null && selectedA != null) {
      // Seçilen çiftleri kullan
      final pairs = _selectedPairs.isNotEmpty ? _selectedPairs : state.matchingPairs;
      final isMatch = pairs.any(
        (pair) => pair['question'] == selectedQ && pair['answer'] == selectedA,
      );

      if (isMatch) {
        // Doğru eşleşme
        HapticFeedback.mediumImpact();
      } else {
        // Yanlış eşleşme
        HapticFeedback.heavyImpact();
        
        // Seçimleri temizle (kısa gecikme ile)
        final cubit = context.read<GameCubit>();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) cubit.clearSelections();
        });
      }
    }
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(
              'Bir sorun oluştu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Geri Dön'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.extension_off_rounded, size: 36, color: AppColors.warning),
            ),
            const SizedBox(height: 20),
            Text(
              'Oyun verisi bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu konu için henüz eşleştirme oyunu hazırlanmamış.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Geri Dön'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.exit_to_app_rounded,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              'Oyundan Çık',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            // Content
            const Text(
              'İlerlemeniz kaydedilmeyecek. Çıkmak istediğinize emin misiniz?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
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
                      'Vazgeç',
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
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Çık',
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

  void _showCompletionDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              'Tebrikler!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            // Content
            Text(
              'Tüm eşleştirmeleri ${_formatTime(_elapsedSeconds)} sürede tamamladınız.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _resetGame();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tekrar Oyna',
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
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tamamla',
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

  void _resetGame() {
    _timer?.cancel();
    setState(() {
      _elapsedSeconds = 0;
      _answersShuffled = false;
      _shuffledAnswers = [];
      _selectedPairs = [];
    });
    context.read<GameCubit>().resetGame();
    final pairs = context.read<GameCubit>().state.matchingPairs;
    if (pairs.isNotEmpty) {
      // Yeni rastgele 8 çift seç
      final allPairs = List<Map<String, String>>.from(pairs);
      allPairs.shuffle();
      setState(() {
        _selectedPairs = allPairs.take(_maxPairs).toList();
        _shuffledAnswers = _selectedPairs.map((p) => p['answer']!).toList()..shuffle();
        _answersShuffled = true;
      });
      _startTimer();
    }
  }
}

/// Oyun kartı widget'ı - Büyük ve okunabilir
class _GameCard extends StatelessWidget {
  final String text;
  final bool isMatched;
  final bool isSelected;
  final bool isDark;
  final bool isQuestion;
  final VoidCallback onTap;

  const _GameCard({
    required this.text,
    required this.isMatched,
    required this.isSelected,
    required this.isDark,
    required this.isQuestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isQuestion ? AppColors.primary : AppColors.success;
    
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isMatched) {
      bgColor = AppColors.success.withValues(alpha: 0.08);
      borderColor = AppColors.success;
      textColor = AppColors.success;
    } else if (isSelected) {
      bgColor = accentColor.withValues(alpha: 0.08);
      borderColor = accentColor;
      textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    } else {
      bgColor = isDark ? AppColors.darkSurface : Colors.white;
      borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB);
      textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    }

    // Renk şeridi için accent color
    final stripeColor = isMatched 
        ? AppColors.success 
        : (isQuestion ? AppColors.primary : AppColors.success);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isMatched ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            boxShadow: [
              if (!isMatched)
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  // Sol kenarda renk şeridi (%10 genişlik)
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: stripeColor.withValues(alpha: isMatched ? 1.0 : 0.8),
                    ),
                  ),
                  // İçerik
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          // Metin - sola hizalanmış
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isMatched ? FontWeight.w600 : FontWeight.w500,
                                color: textColor,
                                height: 1.35,
                              ),
                              textAlign: TextAlign.start,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Eşleşme ikonu alanı
                          SizedBox(
                            width: 24,
                            child: AnimatedOpacity(
                              opacity: isMatched ? 1 : 0,
                              duration: const Duration(milliseconds: 150),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
