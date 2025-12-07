import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kpss_2026/core/services/local_progress_service.dart';
import 'package:kpss_2026/core/repositories/question_repository.dart';
import 'package:kpss_2026/core/models/question_model.dart';
import 'package:kpss_2026/core/data/lessons_data.dart';

/// Yanlış Cevaplar sayfası - Modern ve Kullanışlı
class WrongAnswersPage extends StatefulWidget {
  const WrongAnswersPage({super.key});

  @override
  State<WrongAnswersPage> createState() => _WrongAnswersPageState();
}

class _WrongAnswersPageState extends State<WrongAnswersPage> {
  List<QuestionModel> _allQuestions = [];
  List<QuestionModel> _filteredQuestions = [];
  final Set<String> _expandedIds = {};
  bool _isLoading = true;
  String? _selectedLessonId; // Ders filtresi
  
  static const _primaryBlue = Color(0xFF6366F1);
  static const _errorRed = Color(0xFFEF4444);
  static const _successGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadWrongAnswers();
  }

  Future<void> _loadWrongAnswers() async {
    try {
      final progressService = await LocalProgressService.getInstance();
      final wrongQuestionIds = progressService.getAllWrongQuestions();
      
      if (wrongQuestionIds.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      final repo = QuestionRepository();
      final questions = await repo.getQuestionsByIds(wrongQuestionIds);
      
      if (mounted) {
        setState(() {
          _allQuestions = questions;
          _filteredQuestions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterByLesson(String? lessonId) {
    setState(() {
      _selectedLessonId = lessonId;
      if (lessonId == null) {
        _filteredQuestions = _allQuestions;
      } else {
        _filteredQuestions = _allQuestions.where((q) => q.lessonId == lessonId).toList();
      }
    });
  }

  Future<void> _removeWrongAnswer(String questionId) async {
    try {
      final progressService = await LocalProgressService.getInstance();
      await progressService.markQuestionAsLearned(questionId);
      
      setState(() {
        _allQuestions.removeWhere((q) => q.id == questionId);
        _filteredQuestions.removeWhere((q) => q.id == questionId);
        _expandedIds.remove(questionId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Soru listeden kaldırıldı'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Hata durumunda
    }
  }

  Future<void> _clearAllWrongAnswers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tümünü Temizle'),
        content: const Text('Tüm yanlış cevapları listeden kaldırmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _errorRed),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        final progressService = await LocalProgressService.getInstance();
        for (final q in _allQuestions) {
          await progressService.markQuestionAsLearned(q.id);
        }
        
        setState(() {
          _allQuestions.clear();
          _filteredQuestions.clear();
          _expandedIds.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Tüm yanlışlar temizlendi')),
          );
        }
      } catch (e) {
        // Hata
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Yanlışlarım', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        actions: [
          if (_allQuestions.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'clear') {
                  _clearAllWrongAnswers();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Tümünü Temizle'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allQuestions.isEmpty
              ? _buildEmptyState(textColor, subtextColor)
              : Column(
                  children: [
                    // Filtre ve İstatistik
                    _buildHeader(cardColor, textColor, subtextColor),
                    const SizedBox(height: 8),
                    // Liste
                    Expanded(
                      child: _filteredQuestions.isEmpty
                          ? _buildNoResults(textColor, subtextColor)
                          : _buildWrongAnswersList(cardColor, textColor, subtextColor),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader(Color cardColor, Color textColor, Color subtextColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // İstatistik
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Toplam',
                  '${_allQuestions.length}',
                  _errorRed,
                  Icons.close_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Gösterilen',
                  '${_filteredQuestions.length}',
                  _primaryBlue,
                  Icons.filter_list_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ders Filtresi
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tümü', null, textColor, subtextColor),
                const SizedBox(width: 8),
                ...lessonsData.map((lesson) {
                  final count = _allQuestions.where((q) => q.lessonId == lesson['id']).length;
                  if (count == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      '${lesson['name']} ($count)',
                      lesson['id'] as String,
                      textColor,
                      subtextColor,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? lessonId, Color textColor, Color subtextColor) {
    final isSelected = _selectedLessonId == lessonId;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _filterByLesson(lessonId),
      backgroundColor: Colors.transparent,
      selectedColor: _primaryBlue.withValues(alpha: 0.15),
      checkmarkColor: _primaryBlue,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? _primaryBlue : subtextColor,
      ),
      side: BorderSide(
        color: isSelected ? _primaryBlue : subtextColor.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subtextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: _successGreen,
            ),
            const SizedBox(height: 24),
            Text(
              'Harika! Yanlışınız Yok',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Yanlış cevapladığınız sorular\notomatik olarak burada görünecek',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: subtextColor,
                height: 1.5,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms),
      ),
    );
  }

  Widget _buildNoResults(Color textColor, Color subtextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off_rounded, size: 64, color: subtextColor),
            const SizedBox(height: 16),
            Text(
              'Bu derste yanlış yok',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Başka bir ders seçin',
              style: TextStyle(fontSize: 14, color: subtextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrongAnswersList(Color cardColor, Color textColor, Color subtextColor) {
    return RefreshIndicator(
      onRefresh: _loadWrongAnswers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredQuestions.length,
        itemBuilder: (context, index) {
          final question = _filteredQuestions[index];
          final isExpanded = _expandedIds.contains(question.id);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.close_rounded, color: _errorRed, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question.questionText,
                            maxLines: isExpanded ? null : 2,
                            overflow: isExpanded ? null : TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          color: subtextColor,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Expanded content
                if (isExpanded) ...[
                  Divider(height: 1, color: subtextColor.withValues(alpha: 0.2)),
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCorrect 
                                  ? _successGreen.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCorrect 
                                    ? _successGreen 
                                    : subtextColor.withValues(alpha: 0.2),
                                width: isCorrect ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isCorrect ? _successGreen : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isCorrect ? _successGreen : subtextColor,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isCorrect ? Colors.white : subtextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                if (isCorrect)
                                  Icon(Icons.check_circle_rounded, color: _successGreen, size: 22),
                              ],
                            ),
                          );
                        }),
                        
                        // Açıklama
                        if (question.explanation != null && question.explanation!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_rounded, color: _primaryBlue, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    question.explanation!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Öğrendim butonu
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _removeWrongAnswer(question.id),
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: const Text('Öğrendim, Listeden Kaldır'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _successGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ).animate(delay: (50 * index).ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }
}
