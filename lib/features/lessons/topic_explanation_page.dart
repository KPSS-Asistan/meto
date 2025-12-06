import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/topic_explanation_model.dart';
import '../../core/repositories/cached_explanation_repository.dart';
import '../../core/services/streak_service.dart';
import '../../core/services/daily_progress_service.dart';
import '../../core/theme/app_colors.dart';

class TopicExplanationPage extends StatelessWidget {
  final String lessonId;
  final String topicId;
  final String topicName;
  final String lessonName;

  const TopicExplanationPage({
    super.key,
    required this.lessonId,
    required this.topicId,
    required this.topicName,
    required this.lessonName,
  });

  @override
  Widget build(BuildContext context) {
    return _ExplanationView(
      lessonId: lessonId,
      topicId: topicId,
      topicName: topicName,
      lessonName: lessonName,
    );
  }
}

class _ExplanationView extends StatefulWidget {
  final String lessonId;
  final String topicId;
  final String topicName;
  final String lessonName;

  const _ExplanationView({
    required this.lessonId,
    required this.topicId,
    required this.topicName,
    required this.lessonName,
  });

  @override
  State<_ExplanationView> createState() => _ExplanationViewState();
}

class _ExplanationViewState extends State<_ExplanationView> {
  int _currentSectionIndex = 0;
  
  // ⚡ OPTIMIZED: Future'ı bir kez oluştur, her build'de yeniden oluşturma
  late final Future<TopicExplanationModel?> _explanationFuture;
  
  // ⚡ SINGLETON: Repository instance'ı bir kez oluştur
  static final _repository = CachedExplanationRepository(
    firestore: FirebaseFirestore.instance,
  );
  
  // ScrollController for auto-scroll to top
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Kullanıcı içerik görüntülediğinde streak'i işaretle
    StreakService.markTodayAsStudied();
    // ⚡ Future'ı initState'de oluştur
    _explanationFuture = _repository.getTopicExplanation(widget.topicId);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  // ⚡ Scroll to top when section changes
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: FutureBuilder<TopicExplanationModel?>(
          future: _explanationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 3),
              );
            }

            if (snapshot.hasError) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Center(
                child: Text(
                  'Hata: ${snapshot.error}',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  ),
                ),
              );
            }

            final explanation = snapshot.data;
            if (explanation == null || explanation.sections.isEmpty) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Anlatım bulunamadı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Geri Dön'),
                    ),
                  ],
                ),
              );
            }

            final sections = explanation.sections;
            final section = sections[_currentSectionIndex];
            final totalSections = sections.length;
            final progress = (_currentSectionIndex + 1) / totalSections;

            return Container(
              color: const Color(0xFFFAFAFA),
              child: Column(
              children: [
                // Modern Header
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkBackground : AppColors.surfaceHover,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.topicName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Bölüm ${_currentSectionIndex + 1} / $totalSections',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Progress indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '%${(progress * 100).round()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: isDark ? AppColors.darkBackground : AppColors.surfaceHover,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Content Area
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController, // ⚡ Add controller
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    physics: const BouncingScrollPhysics(),
                    child: _buildSectionContent(section),
                  ),
                ),

                // Navigation Buttons
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Previous Button
                          if (_currentSectionIndex > 0)
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _currentSectionIndex--;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkBackground : AppColors.surfaceHover,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_back_rounded,
                                        size: 18,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Önceki',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          if (_currentSectionIndex > 0) const SizedBox(width: 12),

                          // Next Button
                          Expanded(
                            flex: _currentSectionIndex > 0 ? 1 : 2,
                            child: GestureDetector(
                              onTap: () {
                                if (_currentSectionIndex + 1 < totalSections) {
                                  setState(() {
                                    _currentSectionIndex++;
                                  });
                                  // ⚡ Scroll to top when moving to next section
                                  _scrollToTop();
                                } else {
                                  // ⚡ Konu anlatımı tamamlandı
                                  DailyProgressService.incrementExplanations();
                                  context.pop();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentSectionIndex + 1 < totalSections
                                          ? 'Devam Et'
                                          : 'Tamamla',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      _currentSectionIndex + 1 < totalSections
                                          ? Icons.arrow_forward_rounded
                                          : Icons.check_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ));
          },
        ),
      ),
    );
  }

  Widget _buildSectionContent(ExplanationSection section) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colorScheme = Theme.of(context).colorScheme;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? AppColors.darkBorder : AppColors.border).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ana Başlık - Simple with left accent
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  section.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ).animate().fadeIn(duration: 250.ms),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildContentByType(section),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentByType(ExplanationSection section) {
    // Paragraphs varsa text olarak render et (bullet'lar da paragraphs içinde)
    if (section.paragraphs.isNotEmpty) {
      return _buildText(section);
    }
    
    switch (section.type) {
      case SectionType.bulletList:
        return _buildBulletList(section);
      case SectionType.numbered:
        return _buildNumberedList(section);
      case SectionType.highlighted:
        return _buildHighlighted(section);
      case SectionType.tip:
        return _buildTip(section);
      case SectionType.warning:
        return _buildWarning(section);
      case SectionType.example:
        return _buildExample(section);
      default:
        return _buildText(section);
    }
  }

  Widget _buildText(ExplanationSection section) {
    final headingSet = section.headingIndexes.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < section.paragraphs.length; i++)
          _buildParagraphWidget(
            section.paragraphs[i],
            isHeading: headingSet.contains(i),
          ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  /// Tipografi odaklı paragraf renderı
  Widget _buildParagraphWidget(String paragraph, {bool isHeading = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    // Alt başlık
    if (isHeading || paragraph.startsWith('## ')) {
      final text = isHeading ? paragraph : paragraph.substring(3);
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
            height: 1.3,
          ),
        ),
      );
    }

    // Bullet - • ile başlayan
    if (paragraph.startsWith('• ')) {
      final text = paragraph.substring(2);
      final colonIndex = text.indexOf(':');

      // Başlık:İçerik formatı
      if (colonIndex > 0 && colonIndex < 50) {
        final title = text.substring(0, colonIndex);
        final content = text.substring(colonIndex + 1).trim();

        return Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$title: ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          height: 1.6,
                        ),
                      ),
                      TextSpan(
                        text: content,
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Normal bullet
      return Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Önemli - ** ile çevrili
    if (paragraph.startsWith('**') && paragraph.endsWith('**')) {
      final text = paragraph.substring(2, paragraph.length - 2);
      return InfoBox(
        icon: Icons.push_pin_outlined,
        label: 'Önemli',
        text: text,
        accentColor: colorScheme.primary,
      );
    }

    // İpucu - 💡
    if (paragraph.startsWith('💡 ')) {
      final text = paragraph.substring(2).trim();
      return InfoBox(
        icon: Icons.lightbulb_outline,
        label: 'İpucu',
        text: text,
        accentColor: colorScheme.secondary,
        italic: true,
      );
    }

    // Dikkat - ⚠️
    if (paragraph.startsWith('⚠️ ')) {
      final text = paragraph.substring(2).trim();
      return InfoBox(
        icon: Icons.error_outline,
        label: 'Dikkat',
        text: text,
        accentColor: colorScheme.error,
      );
    }

    // Örnek - 📝
    if (paragraph.startsWith('📝 ')) {
      final text = paragraph.substring(2).trim();
      return InfoBox(
        icon: Icons.menu_book_outlined,
        label: 'Örnek',
        text: text,
        accentColor: colorScheme.tertiary,
      );
    }
    
    // Normal metin
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        paragraph,
        style: TextStyle(
          fontSize: 15,
          height: 1.7,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildBulletList(ExplanationSection section) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.paragraphs.isNotEmpty)
          ...section.paragraphs.map((p) => _buildParagraphWidget(p)),
        ...section.bullets.map((bullet) => Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•', style: TextStyle(fontSize: 16, color: colorScheme.primary, height: 1.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bullet,
                  style: TextStyle(fontSize: 15, height: 1.55, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        )),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildNumberedList(ExplanationSection section) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.paragraphs.isNotEmpty)
          ...section.paragraphs.map((p) => _buildParagraphWidget(p)),
        ...section.bullets.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${entry.key + 1}.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.primary)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.value,
                  style: TextStyle(fontSize: 15, height: 1.55, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        )),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildHighlighted(ExplanationSection section) {
    final text = section.paragraphs.join('\n\n').trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return InfoBox(
      icon: Icons.push_pin_outlined,
      label: 'Öne Çıkan',
      text: text,
      accentColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildTip(ExplanationSection section) {
    final tipText = section.tip?.trim();
    if (tipText == null || tipText.isEmpty) return const SizedBox.shrink();
    return InfoBox(
      icon: Icons.lightbulb_outline,
      label: 'İpucu',
      text: tipText,
      accentColor: Theme.of(context).colorScheme.secondary,
      italic: true,
    );
  }

  Widget _buildWarning(ExplanationSection section) {
    final text = section.tip?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return InfoBox(
      icon: Icons.error_outline,
      label: 'Dikkat',
      text: text,
      accentColor: Theme.of(context).colorScheme.error,
    );
  }

  Widget _buildExample(ExplanationSection section) {
    final text = section.tip?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return InfoBox(
      icon: Icons.menu_book_outlined,
      label: 'Örnek',
      text: text,
      accentColor: Theme.of(context).colorScheme.tertiary,
    );
  }

}

class InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color accentColor;
  final bool italic;

  const InfoBox({
    super.key,
    required this.icon,
    required this.label,
    required this.text,
    required this.accentColor,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.6,
                fontStyle: italic ? FontStyle.italic : null,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
