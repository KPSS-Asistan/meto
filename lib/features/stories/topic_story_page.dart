import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/topic_story_model.dart';
import '../../core/repositories/cached_story_repository.dart';
import '../../core/theme/app_colors.dart';

class TopicStoryPage extends StatelessWidget {
  final String lessonId;
  final String topicId;
  final String topicName;
  final String lessonName;

  const TopicStoryPage({
    super.key,
    required this.lessonId,
    required this.topicId,
    required this.topicName,
    required this.lessonName,
  });

  @override
  Widget build(BuildContext context) {
    return _StoryView(
      lessonId: lessonId,
      topicId: topicId,
      topicName: topicName,
      lessonName: lessonName,
    );
  }
}

class _StoryView extends StatefulWidget {
  final String lessonId;
  final String topicId;
  final String topicName;
  final String lessonName;

  const _StoryView({
    required this.lessonId,
    required this.topicId,
    required this.topicName,
    required this.lessonName,
  });

  @override
  State<_StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<_StoryView> {
  int _currentSectionIndex = 0;
  
  // ⚡ OPTIMIZED: Future'ı bir kez oluştur, her build'de yeniden oluşturma
  late final Future<TopicStoryModel?> _storyFuture;
  
  // ⚡ SINGLETON: Repository instance'ı bir kez oluştur
  static final _repository = CachedStoryRepository();
  
  // ⚡ ScrollController - sayfa değiştiğinde başa dön
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // ⚡ Future'ı initState'de oluştur
    _storyFuture = _repository.getTopicStory(widget.topicId);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  // ⚡ Sayfa değiştiğinde scroll'u sıfırla
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  void _goToSection(int index) {
    setState(() {
      _currentSectionIndex = index;
    });
    _scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<TopicStoryModel?>(
          future: _storyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 3),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Hata: ${snapshot.error}',
                  style: const TextStyle(color: Color(0xFF757575)),
                ),
              );
            }

            final story = snapshot.data;
            if (story == null || story.sections.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_stories_outlined,
                      size: 64,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hikaye bulunamadı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F41BB),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Geri Dön'),
                    ),
                  ],
                ),
              );
            }

            return _buildStoryContent(context, story);
          },
        ),
      ),
    );
  }

  Widget _buildStoryContent(BuildContext context, TopicStoryModel story) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSection = story.sections[_currentSectionIndex];

    return Column(
      children: [
        // Header
        _buildHeader(context, isDark),
        
        // Content
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Bölüm ${_currentSectionIndex + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms),
                
                const SizedBox(height: 16),
                
                // Section Title - Daha büyük ve güçlü
                Text(
                  currentSection.title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A1A2E),
                    height: 1.25,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0),
                
                const SizedBox(height: 28),
                
                // Story Content - Daha okunabilir tipografi
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    currentSection.content,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.85,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF374151),
                      letterSpacing: 0.15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                
                const SizedBox(height: 32),
                
                // Key Points (if any)
                if (currentSection.keyPoints.isNotEmpty) ...[
                  // Önemli Noktalar Başlığı
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          size: 20,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Önemli Noktalar',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A1A2E),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                  
                  const SizedBox(height: 18),
                  
                  ...currentSection.keyPoints.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.success.withValues(alpha: isDark ? 0.15 : 0.08),
                              AppColors.success.withValues(alpha: isDark ? 0.08 : 0.03),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF374151),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: (300 + entry.key * 80).ms)
                        .slideX(begin: 0.05, end: 0),
                    );
                  }),
                  
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
        
        // Navigation
        _buildNavigation(context, story, isDark),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Hikaye',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(BuildContext context, TopicStoryModel story, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              child: OutlinedButton(
                onPressed: () => _goToSection(_currentSectionIndex - 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Önceki',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          
          const SizedBox(width: 12),
          
          // Section Indicator
          Text(
            '${_currentSectionIndex + 1} / ${story.sections.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Next Button
          if (_currentSectionIndex < story.sections.length - 1)
            Expanded(
              child: FilledButton(
                onPressed: () => _goToSection(_currentSectionIndex + 1),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Devam Et',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            Expanded(
              child: FilledButton(
                onPressed: () => context.pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tamamla',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
