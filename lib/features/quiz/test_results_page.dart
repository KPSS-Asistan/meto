import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kpss_2026/core/services/teleport_service.dart';
import 'package:kpss_2026/core/services/premium_service.dart';
import 'package:kpss_2026/core/services/quiz_analysis_service.dart';
import 'package:kpss_2026/core/utils/string_extensions.dart';
import 'package:kpss_2026/features/quiz/widgets/teleport_modal.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TestResultsPage extends StatefulWidget {
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int timeSpent;
  final String topicId;
  final String topicName;

  const TestResultsPage({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.timeSpent,
    required this.topicId,
    required this.topicName,
  });

  @override
  State<TestResultsPage> createState() => _TestResultsPageState();
}

class _TestResultsPageState extends State<TestResultsPage> {
  bool _isPremium = false;
  bool _isAnalyzing = false;
  String? _analysisResult;
  bool _showAnalysis = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _saveQuizResults();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await PremiumService.isPremium();
    if (mounted) {
      setState(() => _isPremium = isPremium);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}dk ${secs}sn';
  }

  double get successRate =>
      widget.totalQuestions > 0 ? (widget.correctAnswers / widget.totalQuestions) * 100 : 0;

  /// 📊 Quiz sonuçlarını kaydet - AI analiz için
  Future<void> _saveQuizResults() async {
    final prefs = await SharedPreferences.getInstance();
    
    final quizResult = {
      'topicName': widget.topicName,
      'totalQuestions': widget.totalQuestions,
      'correctAnswers': widget.correctAnswers,
      'wrongAnswers': widget.wrongAnswers,
      'timeSpent': widget.timeSpent,
      'successRate': successRate,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    // Önceki sonuçları al
    final savedResults = prefs.getStringList('quiz_results') ?? [];
    
    // Yeni sonucu ekle (JSON olarak)
    savedResults.add(jsonEncode(quizResult));
    
    // Sadece son 10 sonucu tut (hafıza için)
    if (savedResults.length > 10) {
      savedResults.removeAt(0);
    }
    
    await prefs.setStringList('quiz_results', savedResults);
  }

  /// 🧠 AI Analiz - Premium özellik
  Future<void> _performAIAnalysis() async {
    if (!_isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _showAnalysis = true;
    });

    try {
      final analysisService = QuizAnalysisService();
      final result = await analysisService.analyzeQuizResult(
        topicId: widget.topicId,
        topicName: widget.topicName,
        totalQuestions: widget.totalQuestions,
        correctAnswers: widget.correctAnswers,
        wrongAnswers: widget.wrongAnswers,
        timeSpent: widget.timeSpent,
        successRate: successRate,
      );

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisResult = 'Analiz yapılırken bir hata oluştu. Lütfen tekrar deneyin.';
          _isAnalyzing = false;
        });
      }
    }
  }

  /// 🔒 Premium Gerekli Dialog
  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock Icon
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
            const SizedBox(height: 8),
            // Features
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildFeatureRow('Hangi konularda eksiğin var'),
                  const SizedBox(height: 8),
                  _buildFeatureRow('Kişiselleştirilmiş çalışma önerileri'),
                  const SizedBox(height: 8),
                  _buildFeatureRow('Zaman yönetimi analizi'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Vazgeç',
              style: TextStyle(color: Colors.grey[600]),
            ),
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

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  /// 🚀 TELEPORT: Kullanıcıyı zayıf konusuna ışınla
  Future<void> _activateTeleport(BuildContext context) async {
    if (!context.mounted) return;

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                SizedBox(height: 16),
                Text('🧠 Performansın analiz ediliyor...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final teleportService = TeleportService();
      final analysis = await teleportService.analyzeAndGetWeakTopic();

      if (context.mounted) {
        Navigator.pop(context); // Loading'i kapat

        if (analysis.hasWeakTopic) {
          // Zayıf konu bulundu - Teleport modal'ı aç
          await TeleportModal.show(context, analysis);
        } else if (analysis.needsMoreData) {
          // Yeterli veri yok
          _showInfoDialog(
            context,
            '📊 Daha Fazla Veri Gerekli',
            'Analiz için henüz yeterli veri yok. Birkaç test daha çöz, sonra tekrar dene!',
          );
        } else {
          // Her şey yolunda
          _showInfoDialog(
            context,
            '🎉 Harika Gidiyorsun!',
            'Belirgin bir zayıf nokta bulunamadı. Böyle devam et!',
          );
        }
      }
    } on TeleportException catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showInfoDialog(context, '❌ Hata', e.message);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showInfoDialog(context, '❌ Hata', 'Beklenmeyen bir hata oluştu: $e');
      }
    }
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          widget.topicName.toTitleCase(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F41BB),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: successRate >= 70
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                successRate >= 70 ? Icons.check_circle : Icons.info,
                size: 64,
                color: successRate >= 70 ? Colors.green : Colors.orange,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              successRate >= 70 ? 'Tebrikler!' : 'Test Tamamlandı',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1F41BB),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Başarı Oranı: ${successRate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            // Stats Cards
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _StatRow(
                    icon: Icons.quiz,
                    label: 'Toplam Soru',
                    value: widget.totalQuestions.toString(),
                    color: const Color(0xFF1F41BB),
                    isDark: isDark,
                  ),
                  Divider(height: 32, color: isDark ? Colors.white12 : null),
                  _StatRow(
                    icon: Icons.check_circle,
                    label: 'Doğru',
                    value: widget.correctAnswers.toString(),
                    color: Colors.green,
                    isDark: isDark,
                  ),
                  Divider(height: 32, color: isDark ? Colors.white12 : null),
                  _StatRow(
                    icon: Icons.cancel,
                    label: 'Yanlış',
                    value: widget.wrongAnswers.toString(),
                    color: Colors.red,
                    isDark: isDark,
                  ),
                  Divider(height: 32, color: isDark ? Colors.white12 : null),
                  _StatRow(
                    icon: Icons.timer,
                    label: 'Süre',
                    value: _formatTime(widget.timeSpent),
                    color: const Color(0xFF2196F3),
                    isDark: isDark,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
            
            // 🧠 AI ANALİZ BUTONU - Her zaman göster
            _buildAnalysisSection(isDark),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _activateTeleport(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '🚀 Zayıf Konuma Işınla',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/dashboard'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: isDark ? Colors.white38 : const Color(0xFF1F41BB),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Ana Sayfaya Dön',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F41BB),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI Analiz Bölümü
  Widget _buildAnalysisSection(bool isDark) {
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
          onTap: _isAnalyzing ? null : _performAIAnalysis,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
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
                    Icon(
                      _isAnalyzing 
                          ? Icons.hourglass_top_rounded
                          : Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
                
                // Analiz Sonucu
                if (_showAnalysis) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isAnalyzing
                        ? Column(
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'AI analiz yapıyor...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _analysisResult ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                              height: 1.6,
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
