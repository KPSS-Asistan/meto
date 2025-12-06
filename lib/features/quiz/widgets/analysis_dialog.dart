import 'package:flutter/material.dart';
import '../../../../core/data/subtopics_mapping.dart';
import '../../../../core/services/quiz_analysis_service.dart';

class AnalysisDialog extends StatefulWidget {
  final String topicId;
  final String topicName;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double successRate;
  final List<WrongQuestionInfo> wrongQuestions;

  const AnalysisDialog({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.successRate,
    required this.wrongQuestions,
  });

  @override
  State<AnalysisDialog> createState() => _AnalysisDialogState();
}

class _AnalysisDialogState extends State<AnalysisDialog> {
  String _aiAnalysis = '';
  bool _isComplete = false;
  List<String> _weakTopics = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    final subtopics = SubtopicMapping.getSubtopics(widget.topicId);
    if (subtopics.isNotEmpty) {
      _weakTopics = subtopics.take(3).map((s) => s.name).toList();
    }
    _startStreaming();
  }

  void _startStreaming() async {
    try {
      final service = QuizAnalysisService();
      await for (final chunk in service.analyzeQuizResultStreaming(
        topicId: widget.topicId,
        topicName: widget.topicName,
        totalQuestions: widget.totalQuestions,
        correctAnswers: widget.correctAnswers,
        wrongAnswers: widget.wrongAnswers,
        successRate: widget.successRate,
        wrongQuestions: widget.wrongQuestions,
      )) {
        if (mounted) {
          setState(() => _aiAnalysis = chunk.replaceAll('**', '').replaceAll('*', ''));
          // Scroll takibi
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
      if (mounted) setState(() => _isComplete = true);
    } catch (e) {
      if (mounted) setState(() { _aiAnalysis = 'Analiz yapılamadı.'; _isComplete = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: bgColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header - Kompakt
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.topicName,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Inline İstatistikler
                        Row(
                          children: [
                            _buildMiniStat('${widget.correctAnswers}', 'doğru', const Color(0xFF10B981)),
                            const SizedBox(width: 12),
                            _buildMiniStat('${widget.wrongAnswers}', 'yanlış', const Color(0xFFEF4444)),
                            const SizedBox(width: 12),
                            _buildMiniStat('%${widget.successRate.round()}', 'başarı', const Color(0xFF6366F1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: subtextColor),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: subtextColor.withValues(alpha: 0.15)),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zayıf Konular - Kompakt
                    if (_weakTopics.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.flag_rounded, size: 16, color: const Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Text('Odaklanman Gereken Konular', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _weakTopics.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.5)),
                          ),
                          child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF92400E))),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // AI Koç Analizi - Premium görünüm
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6366F1),
                            const Color(0xFF8B5CF6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.psychology_rounded, size: 24, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('AI Koç Analizi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                Text('Kişiselleştirilmiş öneriler', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                              ],
                            ),
                          ),
                          if (!_isComplete)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.8))),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // AI İçerik
                    if (_aiAnalysis.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: subtextColor.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1))),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('AI düşünüyor...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                  const SizedBox(height: 4),
                                  Text('Performansın analiz ediliyor, öneriler hazırlanıyor', style: TextStyle(fontSize: 12, color: subtextColor, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._buildAIBullets(textColor, subtextColor, isDark),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tamam', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
      ],
    );
  }

  /// AI çıktısını bullet kartlarına böl
  List<Widget> _buildAIBullets(Color textColor, Color subtextColor, bool isDark) {
    final bullets = _aiAnalysis.split('•').where((s) => s.trim().isNotEmpty).toList();
    
    final bulletData = <Map<String, dynamic>>[
      {'icon': Icons.analytics_rounded, 'color': const Color(0xFF6366F1), 'label': 'Durum'},
      {'icon': Icons.flag_rounded, 'color': const Color(0xFFF59E0B), 'label': 'Odak'},
      {'icon': Icons.lightbulb_rounded, 'color': const Color(0xFF10B981), 'label': 'Öneri'},
      {'icon': Icons.emoji_emotions_rounded, 'color': const Color(0xFFEC4899), 'label': 'Motivasyon'},
    ];

    return [
      for (int i = 0; i < bullets.length && i < 4; i++)
        Container(
          margin: EdgeInsets.only(bottom: i < bullets.length - 1 ? 12 : 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bulletData[i]['color'].withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bulletData[i]['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(bulletData[i]['icon'], size: 16, color: bulletData[i]['color']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  bullets[i].trim().replaceFirst(RegExp(r'^[A-Za-zğüşöçıİĞÜŞÖÇ]+:\s*'), ''),
                  style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      if (!_isComplete)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(const Color(0xFF6366F1))),
              ),
              const SizedBox(width: 8),
              Text('yazıyor...', style: TextStyle(fontSize: 11, color: subtextColor, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
    ];
  }
}
