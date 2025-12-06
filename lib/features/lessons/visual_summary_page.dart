import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import 'package:kpss_2026/core/theme/app_sizes.dart';
import 'package:kpss_2026/core/utils/string_extensions.dart';

/// Görsel Özet Sayfası - İnfografikler, şemalar, haritalar
class VisualSummaryPage extends StatefulWidget {
  final String topicId;
  final String topicName;
  final String lessonName;
  final String lessonId;

  const VisualSummaryPage({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.lessonName,
    required this.lessonId,
  });

  @override
  State<VisualSummaryPage> createState() => _VisualSummaryPageState();
}

class _VisualSummaryPageState extends State<VisualSummaryPage> {
  List<VisualSummaryItem> _items = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadVisualSummaries();
  }

  /// Sonraki resmi önceden yükle
  void _preloadNextImage() {
    if (_currentIndex < _items.length - 1) {
      final nextItem = _items[_currentIndex + 1];
      precacheImage(
        CachedNetworkImageProvider(nextItem.imageUrl),
        context,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVisualSummaries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Topic dokümanından images array'ini çek
      final doc = await FirebaseFirestore.instance
          .collection('topics')
          .doc(widget.topicId)
          .get();

      if (!doc.exists) {
        setState(() {
          _items = [];
          _isLoading = false;
        });
        return;
      }

      final data = doc.data();
      final images = data?['images'] as List<dynamic>? ?? [];

      final items = images.asMap().entries.map((entry) {
        final index = entry.key;
        final img = entry.value;
        
        // String ise sadece URL, Map ise detaylı veri
        if (img is String) {
          return VisualSummaryItem(
            id: '$index',
            title: '',
            description: '',
            imageUrl: img,
            order: index,
          );
        } else if (img is Map) {
          return VisualSummaryItem(
            id: '$index',
            title: img['title'] ?? '',
            description: img['description'] ?? '',
            imageUrl: img['url'] ?? img['image_url'] ?? '',
            order: img['order'] ?? index,
          );
        }
        return null;
      }).whereType<VisualSummaryItem>().toList();

      setState(() {
        _items = items;
        _isLoading = false;
      });

      // İlk ve ikinci resimleri önceden yükle
      if (items.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _preloadNextImage();
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lessonColor = AppColors.getLessonColor(widget.lessonName);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(widget.topicName.toTitleCase()),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_items.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: lessonColor.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1}/${_items.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: lessonColor,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(isDark, lessonColor),
    );
  }

  Widget _buildBody(bool isDark, Color lessonColor) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState(isDark);
    }

    if (_items.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Column(
      children: [
        // Page View
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _preloadNextImage();
            },
            itemBuilder: (context, index) {
              return _buildImageCard(_items[index], isDark, lessonColor);
            },
          ),
        ),

        // Bottom Navigation
        _buildBottomNav(isDark, lessonColor),
      ],
    );
  }

  Widget _buildImageCard(VisualSummaryItem item, bool isDark, Color lessonColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (item.title.isNotEmpty) ...[
            Text(
              item.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Description
          if (item.description.isNotEmpty) ...[
            Text(
              item.description,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onTap: () => _showFullScreenImage(item),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 200),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.contain,
                  // Sıkıştırma yok - orijinal boyut korunuyor
                  placeholder: (context, url) => Container(
                    height: 300,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      color: lessonColor,
                      strokeWidth: 2,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Görsel yüklenemedi',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Zoom hint
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: lessonColor.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.zoom_in_rounded,
                    size: 16,
                    color: lessonColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Büyütmek için dokun',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: lessonColor,
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

  Widget _buildBottomNav(bool isDark, Color lessonColor) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous Button
            Expanded(
              child: _NavButton(
                icon: Icons.arrow_back_rounded,
                label: 'Önceki',
                onTap: _currentIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                isDark: isDark,
              ),
            ),

            const SizedBox(width: 12),

            // Page Indicators
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_items.length, (index) {
                final isActive = index == _currentIndex;
                return Container(
                  width: isActive ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? lessonColor
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(width: 12),

            // Next Button
            Expanded(
              child: _NavButton(
                icon: Icons.arrow_forward_rounded,
                label: 'Sonraki',
                onTap: _currentIndex < _items.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                isDark: isDark,
                isNext: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(VisualSummaryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageView(
          imageUrl: item.imageUrl,
          title: item.title,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.image_rounded,
                size: 40,
                color: Color(0xFF0EA5E9),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Görsel Özet Bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu konu için henüz görsel özet eklenmemiş.\nYakında eklenecek!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Görsel özetler yüklenirken bir sorun oluştu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadVisualSummaries,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isNext;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isEnabled
                ? (isDark ? AppColors.darkSurface : AppColors.surface)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? (isDark ? AppColors.darkBorder : AppColors.border)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isNext) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isEnabled
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                      : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isEnabled
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                      : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                ),
              ),
              if (isNext) ...[
                const SizedBox(width: 6),
                Icon(
                  icon,
                  size: 18,
                  color: isEnabled
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                      : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenImageView extends StatefulWidget {
  final String imageUrl;
  final String title;

  const _FullScreenImageView({
    required this.imageUrl,
    required this.title,
  });

  @override
  State<_FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<_FullScreenImageView> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a1a),
        elevation: 2,
        shadowColor: Colors.black,
        foregroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: widget.title.isNotEmpty
            ? Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              )
            : null,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              onPressed: () {
                _transformationController.value = Matrix4.identity();
              },
              tooltip: 'Sıfırla',
            ),
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.contain,
            // Sıkıştırma yok - orijinal kalite
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(
                Icons.broken_image_rounded,
                size: 64,
                color: Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VisualSummaryItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int order;

  VisualSummaryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.order,
  });
}
