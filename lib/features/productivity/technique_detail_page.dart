import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/study_techniques_data.dart';
import '../../core/models/study_technique_model.dart';
import '../../core/theme/app_colors.dart';

class TechniqueDetailPage extends StatefulWidget {
  final String techniqueId;

  const TechniqueDetailPage({
    required this.techniqueId,
    super.key,
  });

  @override
  State<TechniqueDetailPage> createState() => _TechniqueDetailPageState();
}

class _TechniqueDetailPageState extends State<TechniqueDetailPage> {
  int _currentPageIndex = 0;
  late List<_TechniquePage> _pages;
  late StudyTechnique _technique;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _technique = StudyTechniquesData.all.firstWhere(
      (t) => t.id == widget.techniqueId,
    );
    _color = _getCategoryColor(_technique.category);
    _buildPages();
  }

  void _buildPages() {
    _pages = [
      _TechniquePage(
        title: 'Açıklama',
        icon: Icons.info_outline_rounded,
        content: _technique.fullDescription,
      ),
      _TechniquePage(
        title: 'Adımlar',
        icon: Icons.format_list_numbered_rounded,
        steps: _technique.steps,
      ),
      _TechniquePage(
        title: 'Faydaları',
        icon: Icons.check_circle_outline_rounded,
        bullets: _technique.benefits,
      ),
      _TechniquePage(
        title: 'İpuçları',
        icon: Icons.tips_and_updates_outlined,
        bullets: _technique.tips,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _pages.length;
    final progress = (_currentPageIndex + 1) / totalPages;
    final currentPage = _pages[_currentPageIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, totalPages, progress, isDark),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: _buildPageContent(currentPage, isDark)
                    .animate(key: ValueKey(_currentPageIndex))
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.03, end: 0),
              ),
            ),

            // Navigation
            _buildNavigationButtons(context, totalPages, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalPages, double progress, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Close Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 14),
              
              // Title & Progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _technique.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_currentPageIndex + 1} / $totalPages',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Page Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _pages[_currentPageIndex].icon,
                  color: _color,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, int totalPages, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentPageIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentPageIndex--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: _color.withValues(alpha: 0.5), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Önceki', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          
          if (_currentPageIndex > 0) const SizedBox(width: 12),
          
          // Next/Complete Button
          Expanded(
            flex: _currentPageIndex > 0 ? 1 : 2,
            child: FilledButton(
              onPressed: () {
                if (_currentPageIndex < totalPages - 1) {
                  setState(() => _currentPageIndex++);
                } else {
                  context.pop();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: _color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPageIndex < totalPages - 1 ? 'Devam Et' : 'Tamamla',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _currentPageIndex < totalPages - 1
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(_TechniquePage page, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_color, _color.withValues(alpha: 0.75)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(page.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              page.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Content
        if (page.content != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Text(
              page.content!,
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),

        // Steps
        if (page.steps != null)
          ...page.steps!.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          step,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

        // Bullets
        if (page.bullets != null)
          ...page.bullets!.map((bullet) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: _color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bullet,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'examHacks':
        return const Color(0xFFF43F5E);
      case 'bioHacking':
        return const Color(0xFF8B5CF6);
      case 'breakGuide':
        return const Color(0xFF10B981);
      case 'noteTaking':
        return const Color(0xFF14B8A6);
      case 'memory':
        return const Color(0xFFF59E0B);
      case 'reading':
        return const Color(0xFFEC4899);
      case 'timeManagement':
        return const Color(0xFF6366F1);
      case 'studyPlanning':
        return const Color(0xFF0EA5E9);
      case 'concentration':
        return const Color(0xFFEF4444);
      case 'motivation':
        return const Color(0xFF22C55E);
      case 'stressManagement':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6366F1);
    }
  }
}

class _TechniquePage {
  final String title;
  final IconData icon;
  final String? content;
  final List<String>? steps;
  final List<String>? bullets;

  _TechniquePage({
    required this.title,
    required this.icon,
    this.content,
    this.steps,
    this.bullets,
  });
}
