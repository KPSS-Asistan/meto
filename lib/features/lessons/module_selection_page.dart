import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import 'package:kpss_2026/core/services/last_study_service.dart';
import 'package:kpss_2026/core/services/local_progress_service.dart';
import 'package:kpss_2026/core/services/streak_service.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';
import 'package:kpss_2026/core/utils/string_extensions.dart';
import 'package:kpss_2026/core/widgets/theme_aware_header.dart';

enum ContentType {
  anlatim('Konu Anlatımı', Icons.menu_book_rounded, AppColors.primary),
  gorselOzet('Görsel Özet', Icons.image_rounded, Color(0xFF0EA5E9)),
  test('Testler', Icons.quiz, AppColors.success),
  flashcards('Flashcards', Icons.style, Color(0xFF8B5CF6)),
  hikaye('Hikayeler', Icons.auto_stories, Color(0xFFF59E0B)),
  eslestirme('Eşleştirme', Icons.compare_arrows, Color(0xFF10B981));

  const ContentType(this.displayName, this.icon, this.color);

  final String displayName;
  final IconData icon;
  final Color color;
}

class ModuleSelectionPage extends StatefulWidget {
  final String lessonId;
  final String topicId;
  final String topicName;
  final String lessonName;

  const ModuleSelectionPage({
    super.key,
    required this.lessonId,
    required this.topicId,
    required this.topicName,
    required this.lessonName,
  });

  @override
  State<ModuleSelectionPage> createState() => _ModuleSelectionPageState();
}

class _ModuleSelectionPageState extends State<ModuleSelectionPage> {
  int _completedCountTopic = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _isLoading = true;
  String? _recommendedAction;

  @override
  void initState() {
    super.initState();
    _loadTopicData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ⚡ Sayfa tekrar görünür olduğunda verileri yenile
    // Bu, quiz'den geri dönüldüğünde çalışır
  }

  /// ⚡ Quiz'den dönünce verileri yenile
  void refreshData() {
    _loadTopicData();
  }

  Future<void> _loadTopicData() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // ⚡ LocalProgressService'den konu bazlı istatistikleri al
      final progressService = await LocalProgressService.getInstance();
      final topicProgress = progressService.getTopicProgress(widget.topicId);
      
      // 🐛 DEBUG: Konu ilerlemesini logla
      print('📊 DEBUG - Topic Progress for ${widget.topicId}:');
      print('   - Data: $topicProgress');
      print('   - Attempted: ${topicProgress?.attemptedQuestions ?? 0}');
      print('   - Correct: ${topicProgress?.correctAnswers ?? 0}');
      
      // İstatistikleri hesapla
      final totalSolved = topicProgress?.attemptedQuestions ?? 0;
      final correctCount = topicProgress?.correctAnswers ?? 0;
      final wrongCount = totalSolved - correctCount;
      final successRate = totalSolved > 0 ? (correctCount / totalSolved * 100) : 0.0;

      // Varsayılan soru sayısı (gerçek sayı quiz başladığında yüklenir)
      const questionCount = 20;

      // Calculate recommendation
      final recommendation = _calculateRecommendation(
        totalSolved,
        questionCount,
        successRate,
      );

      if (mounted) {
        setState(() {
          _completedCountTopic = totalSolved;
          _correctCount = correctCount;
          _wrongCount = wrongCount;
          _recommendedAction = recommendation;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Load topic data failed', e);
      print('❌ DEBUG - Error loading topic data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _calculateRecommendation(
    int solved,
    int total,
    double successRate,
  ) {
    if (solved == 0) {
      return 'Konu anlatımını okuyarak başla';
    } else if (solved < total * 0.3) {
      return 'Testlere devam et';
    } else if (successRate < 60) {
      return 'Yanlışlarını tekrar et';
    } else if (solved < total) {
      return 'Kalan soruları çöz';
    } else {
      return 'Konuyu tamamladın! 🎉';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Ana içerik alanı
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ThemeAwareHeader(
      title: widget.topicName.toTitleCase(),
      onClose: () => Navigator.of(context).pop(),
    );
  }



  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }
    return _buildContent();
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadTopicData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildRecommendationCard(),
            const SizedBox(height: 20),
            _buildContentTypes(),
            const SizedBox(height: 20),
            _buildStatsCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }



  Widget _buildStatsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accuracy = _completedCountTopic > 0 
        ? ((_correctCount / _completedCountTopic) * 100).round() 
        : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CompactStatItem(
            label: 'Çözülen',
            value: '$_completedCountTopic',
            color: AppColors.primary,
          ),
          _StatDivider(),
          _CompactStatItem(
            label: 'Doğru',
            value: '$_correctCount',
            color: AppColors.success,
          ),
          _StatDivider(),
          _CompactStatItem(
            label: 'Yanlış',
            value: '$_wrongCount',
            color: const Color(0xFFEF4444),
          ),
          _StatDivider(),
          _CompactStatItem(
            label: 'Başarı',
            value: '%$accuracy',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    if (_recommendedAction == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Önerilen Adım',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _recommendedAction!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypes() {
    // Timeline yapısı - Alt alta sıralı modüller
    final modules = [
      ContentType.anlatim,
      ContentType.test,
      ContentType.flashcards,
      ContentType.hikaye,
      ContentType.gorselOzet,
      ContentType.eslestirme,
    ];
    
    return Column(
      children: List.generate(modules.length, (index) {
        final contentType = modules[index];
        final isLast = index == modules.length - 1;
        
        return _TimelineModuleCard(
          contentType: contentType,
          isLast: isLast,
          stepNumber: index + 1,
          onTap: () => _navigateToContent(contentType),
        );
      }),
    );
  }

  Future<void> _navigateToContent(ContentType contentType) async {
    // ⚡ Son çalışmayı kaydet + Bugünü çalışıldı olarak işaretle
    await LastStudyService.saveLastStudy(
      lessonId: widget.lessonId,
      lessonName: widget.lessonName,
      topicId: widget.topicId,
      topicName: widget.topicName,
      moduleName: contentType.displayName,
    );
    await StreakService.markTodayAsStudied();
    
    if (!mounted) return;
    
    switch (contentType) {
      case ContentType.anlatim:
        context.push(
          '/lessons/${widget.lessonId}/topics/${widget.topicId}/explanation',
          extra: {
            'topicName': widget.topicName,
            'lessonName': widget.lessonName,
            'lessonId': widget.lessonId,
          },
        );
        break;
      case ContentType.gorselOzet:
        context.push(
          '/lessons/${widget.lessonId}/topics/${widget.topicId}/visual-summary',
          extra: {
            'topicName': widget.topicName,
            'lessonName': widget.lessonName,
            'lessonId': widget.lessonId,
          },
        );
        break;
      case ContentType.test:
        // Quiz sayfasına yönlendir - topicId gönder
        context.push(
          '/lessons/${widget.lessonId}/topics/${widget.topicId}/quiz',
          extra: {
            'topicName': widget.topicName,
            'lessonId': widget.lessonId,
          },
        ).then((_) => _loadTopicData()); // ⚡ Quiz'den dönünce verileri yenile
        break;
      case ContentType.flashcards:
        // Flashcard sayfasına yönlendir
        context.push('/flashcards/${widget.topicId}').then((_) => _loadTopicData()); // ⚡ Flashcard'dan dönünce yenile
        break;
      case ContentType.hikaye:
        context.push(
          '/lessons/${widget.lessonId}/topics/${widget.topicId}/story',
          extra: {
            'topicName': widget.topicName,
            'lessonName': widget.lessonName,
            'lessonId': widget.lessonId,
          },
        );
        break;
      case ContentType.eslestirme:
        context.push(
          '/lessons/${widget.lessonId}/topics/${widget.topicId}/matching',
          extra: {
            'topicName': widget.topicName,
          },
        );
        break;
    }
  }
}

/// Timeline tarzı modül kartı
class _TimelineModuleCard extends StatelessWidget {
  final ContentType contentType;
  final bool isLast;
  final int stepNumber;
  final VoidCallback? onTap;

  const _TimelineModuleCard({
    required this.contentType,
    required this.isLast,
    required this.stepNumber,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = contentType.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline çizgisi
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Numara dairesi
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                // Bağlantı çizgisi
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Kart içeriği
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    // İkon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        contentType.icon,
                        size: 24,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Başlık
                    Expanded(
                      child: Text(
                        contentType.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    
                    // Ok
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _CompactStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE5E7EB),
    );
  }
}


