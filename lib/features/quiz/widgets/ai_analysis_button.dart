import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/quiz_analysis_service.dart';
import '../../../../core/services/premium_service.dart';
import 'analysis_dialog.dart';

/// 🧠 AI Analiz Butonu - Premium özellik
class AIAnalysisButton extends StatefulWidget {
  final String topicId;
  final String topicName;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double successRate;
  final List<WrongQuestionInfo> wrongQuestions;

  const AIAnalysisButton({
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
  State<AIAnalysisButton> createState() => _AIAnalysisButtonState();
}

class _AIAnalysisButtonState extends State<AIAnalysisButton> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremium();
  }

  Future<void> _checkPremium() async {
    final isPremium = await PremiumService.isPremium();
    if (mounted) setState(() => _isPremium = isPremium);
  }

  Future<void> _performAnalysis() async {
    if (!_isPremium) {
      _showPremiumDialog();
      return;
    }

    // Analiz dialog'unu aç
    _showAnalysisDialog();
  }

  void _showAnalysisDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Analiz',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value,
          child: Opacity(
            opacity: anim1.value,
            child: AnalysisDialog(
              topicId: widget.topicId,
              topicName: widget.topicName,
              totalQuestions: widget.totalQuestions,
              correctAnswers: widget.correctAnswers,
              wrongAnswers: widget.wrongAnswers,
              successRate: widget.successRate,
              wrongQuestions: widget.wrongQuestions,
            ),
          ),
        );
      },
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.2),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 36,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Premium Özellik',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI destekli detaylı analiz ve kişiselleştirilmiş öneriler almak için Premium\'a geç.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _featureRow('Hangi konularda eksiğin var'),
                  const SizedBox(height: 8),
                  _featureRow('Kişiselleştirilmiş çalışma önerileri'),
                  const SizedBox(height: 8),
                  _featureRow('Zaman yönetimi analizi'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Vazgeç', style: TextStyle(color: Colors.grey[600])),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/premium');
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded, size: 18),
                SizedBox(width: 6),
                Text('Premium\'a Geç'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isPremium
              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isPremium ? const Color(0xFF6366F1) : Colors.grey).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _performAnalysis,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isPremium ? Icons.psychology_rounded : Icons.lock_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Durumumu Analiz Et',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (!_isPremium) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isPremium
                            ? 'AI ile eksiklerini ve gelişim alanlarını öğren'
                            : 'Premium ile detaylı analiz al',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}
