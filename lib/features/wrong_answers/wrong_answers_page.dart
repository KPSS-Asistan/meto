import 'package:flutter/material.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import 'package:kpss_2026/core/services/user_data_service.dart';
import 'package:kpss_2026/core/repositories/question_repository.dart';
import 'package:kpss_2026/core/models/question_model.dart';

/// Yanlış Cevaplar sayfası - Açılır/kapanır soru listesi
class WrongAnswersPage extends StatefulWidget {
  const WrongAnswersPage({super.key});

  @override
  State<WrongAnswersPage> createState() => _WrongAnswersPageState();
}

class _WrongAnswersPageState extends State<WrongAnswersPage> {
  List<QuestionModel> _questions = [];
  final Set<String> _expandedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWrongAnswers();
  }

  Future<void> _loadWrongAnswers() async {
    final wrongAnswers = await UserDataService.getWrongAnswers();
    if (wrongAnswers.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    final repo = QuestionRepository();
    final questions = await repo.getQuestionsByIds(wrongAnswers.toList());
    
    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeWrongAnswer(String questionId) async {
    await UserDataService.removeWrongAnswer(questionId);
    setState(() {
      _questions.removeWhere((q) => q.id == questionId);
      _expandedIds.remove(questionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Yanlışlarım'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_questions.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? _buildEmptyState(isDark)
              : _buildWrongAnswersList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: AppColors.success,
            ),
            const SizedBox(height: 16),
            Text(
              'Harika! Yanlışınız yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yanlış cevapladığınız sorular\notomatik olarak burada görünecek',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrongAnswersList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final question = _questions[index];
        final isExpanded = _expandedIds.contains(question.id);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              // Header - tıklanabilir
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedIds.remove(question.id);
                    } else {
                      _expandedIds.add(question.id);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.questionText,
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded ? null : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expanded content
              if (isExpanded) ...[
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seçenekler
                      ...question.options.entries.map((entry) {
                        final isCorrect = entry.key == question.correctAnswer;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isCorrect 
                                ? AppColors.success.withValues(alpha: 0.1)
                                : (isDark ? AppColors.darkBackground : AppColors.background),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCorrect 
                                  ? AppColors.success 
                                  : (isDark ? AppColors.darkBorder : AppColors.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isCorrect ? AppColors.success : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCorrect 
                                        ? AppColors.success 
                                        : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isCorrect 
                                          ? Colors.white 
                                          : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isCorrect)
                                const Icon(Icons.check_rounded, color: AppColors.success, size: 20),
                            ],
                          ),
                        );
                      }),
                      
                      // Açıklama
                      if (question.explanation != null && question.explanation!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline_rounded, color: AppColors.info, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  question.explanation!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Listeden kaldır butonu
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _removeWrongAnswer(question.id),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Öğrendim, Listeden Kaldır'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: BorderSide(color: AppColors.success),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
