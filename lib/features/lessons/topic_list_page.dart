import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import 'package:kpss_2026/core/models/topic_model.dart';
import 'package:kpss_2026/core/repositories/topic_repository.dart';
import 'package:kpss_2026/core/utils/string_extensions.dart';
import 'package:kpss_2026/core/widgets/error_state.dart';

class TopicListPage extends StatefulWidget {
  final String lessonId;
  final String lessonName;

  const TopicListPage({
    super.key,
    required this.lessonId,
    required this.lessonName,
  });

  @override
  State<TopicListPage> createState() => _TopicListPageState();
}

class _TopicListPageState extends State<TopicListPage> {
  final TextEditingController _searchController = TextEditingController();
  
  List<TopicModel> _allTopics = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<TopicRepository>();
      final topics = await repo.getTopicsByLesson(widget.lessonId);
      
      if (mounted) {
        setState(() {
          _allTopics = topics;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchQuery != _searchController.text) {
      setState(() {
        _searchQuery = _searchController.text;
      });
    }
  }

  List<TopicModel> get _visibleTopics {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _allTopics;
    return _allTopics.where((t) {
      final name = t.name.toLowerCase();
      final desc = (t.description ?? '').toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  Color _getLessonColor(String lessonName) {
    return AppColors.getLessonColor(lessonName);
  }

  @override
  Widget build(BuildContext context) {
    final lessonColor = _getLessonColor(widget.lessonName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.lessonName.toTitleCase()),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: lessonColor.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined, size: 16, color: lessonColor),
                const SizedBox(width: 6),
                Text(
                  '${_allTopics.length}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: lessonColor),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(lessonColor, isDark, colorScheme),
    );
  }

  Widget _buildBody(Color lessonColor, bool isDark, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_allTopics.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return _buildTopicsList(lessonColor, isDark, colorScheme);
  }

  Widget _buildTopicsList(Color lessonColor, bool isDark, ColorScheme colorScheme) {
    if (_visibleTopics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Eşleşen konu bulunamadı.',
            style: TextStyle(
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadTopics();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        itemCount: _visibleTopics.length,
        itemBuilder: (context, index) {
          final topic = _visibleTopics[index];
          final isLast = index == _visibleTopics.length - 1;
          
          return _TopicPathItem(
            topic: topic,
            subjectColor: lessonColor,
            lessonName: widget.lessonName,
            isDark: isDark,
            colorScheme: colorScheme,
            index: index,
            isLast: isLast,
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return ErrorState(
      title: 'Konular yüklenirken hata oluştu',
      onRetry: () => setState(() {}),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz konu eklenmedi',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Yol tarzı konu kartı - modüller gibi aşağı inen yol
class _TopicPathItem extends StatelessWidget {
  final TopicModel topic;
  final Color subjectColor;
  final String lessonName;
  final bool isDark;
  final ColorScheme colorScheme;
  final int index;
  final bool isLast;

  const _TopicPathItem({
    required this.topic,
    required this.subjectColor,
    required this.lessonName,
    required this.isDark,
    required this.colorScheme,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToTopic(context),
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
            // İkon container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: subjectColor.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 24,
                color: subjectColor,
              ),
            ),
            const SizedBox(width: 14),
            
            // Konu adı
            Expanded(
              child: Text(
                topic.name.toTitleCase(),
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
    );
  }

  void _navigateToTopic(BuildContext context) {
    context.push(
      '/lessons/${topic.lessonId}/topics/${topic.id}/modules',
      extra: {
        'lessonId': topic.lessonId,
        'topicId': topic.id,
        'topicName': topic.name,
        'lessonName': lessonName,
      },
    );
  }
}
