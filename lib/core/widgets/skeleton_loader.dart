import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

/// Skeleton loader widget'ları
/// Academic Premium tasarımına uygun, temiz ve minimal
class SkeletonLoader {
  /// Temel skeleton container
  static Widget container({
    required double width,
    required double height,
    double borderRadius = 12,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// Shimmer efekti ile skeleton
  static Widget shimmer({
    required Widget child,
  }) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.background,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }

  /// Kart skeleton (Dashboard için)
  static Widget card({
    double width = double.infinity,
    double height = 120,
    double borderRadius = 16,
  }) {
    return shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Ders kartı skeleton
  static Widget lessonCard() {
    return shimmer(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Mevcut alana göre elemanları orantılı şekilde yerleştir
            final availableHeight = constraints.maxHeight - 24; // padding çıkarıldı
            final iconSize = (availableHeight * 0.4).clamp(20.0, 32.0);
            final titleHeight = (availableHeight * 0.18).clamp(10.0, 14.0);
            final subtitleHeight = (availableHeight * 0.14).clamp(8.0, 11.0);
            final spacing = (availableHeight * 0.1).clamp(4.0, 10.0);
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Icon placeholder
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(iconSize * 0.3),
                  ),
                ),
                SizedBox(height: spacing),
                // Title placeholder
                Container(
                  width: double.infinity,
                  height: titleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(titleHeight / 2),
                  ),
                ),
                SizedBox(height: spacing * 0.5),
                // Subtitle placeholder
                Container(
                  width: constraints.maxWidth * 0.6,
                  height: subtitleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(subtitleHeight / 2),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Liste item skeleton
  static Widget listItem({
    bool hasLeading = true,
    bool hasTrailing = false,
  }) {
    return shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            if (hasLeading) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            if (hasTrailing) ...[
              const SizedBox(width: 12),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Text skeleton (tek satır)
  static Widget text({
    double width = 100,
    double height = 14,
  }) {
    return shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }

  /// Paragraph skeleton (çok satırlı)
  static Widget paragraph({
    int lines = 3,
    double spacing = 8,
  }) {
    return shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          lines,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < lines - 1 ? spacing : 0),
            child: Container(
              width: index == lines - 1 ? 200 : double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Avatar skeleton
  static Widget avatar({
    double size = 40,
  }) {
    return shimmer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.border,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Grid skeleton (Dashboard dersler için)
  static Widget grid({
    int itemCount = 6,
    int crossAxisCount = 2,
    double crossAxisSpacing = 12,
    double mainAxisSpacing = 12,
    double childAspectRatio = 1.5,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => lessonCard(),
    );
  }

  /// Horizontal scroll skeleton (Badge cards için)
  static Widget horizontalScroll({
    int itemCount = 3,
    double itemWidth = 140,
    double itemHeight = 120,
  }) {
    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(
            left: index == 0 ? 0 : 12,
            right: index == itemCount - 1 ? 0 : 0,
          ),
          child: card(
            width: itemWidth,
            height: itemHeight,
          ),
        ),
      ),
    );
  }

  /// Dashboard home skeleton (tam sayfa)
  static Widget dashboardHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak Card
          card(height: 180),
          
          const SizedBox(height: 20),
          
          // Hızlı Erişim başlık
          text(width: 120, height: 14),
          const SizedBox(height: 12),
          
          // Badge cards
          horizontalScroll(itemCount: 4),
          
          const SizedBox(height: 20),
          
          // Dersler başlık
          text(width: 80, height: 14),
          const SizedBox(height: 12),
          
          // Dersler grid
          grid(itemCount: 6),
          
          const SizedBox(height: 20),
          
          // Pratik Yap başlık
          text(width: 100, height: 14),
          const SizedBox(height: 12),
          
          // Pratik kartları
          card(height: 100),
          const SizedBox(height: 12),
          card(height: 100),
        ],
      ),
    );
  }

  /// Konu anlatımı skeleton
  static Widget topicExplanation() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          text(width: 250, height: 24),
          const SizedBox(height: 24),
          
          // Paragraflar
          paragraph(lines: 5),
          const SizedBox(height: 16),
          paragraph(lines: 4),
          const SizedBox(height: 16),
          paragraph(lines: 3),
        ],
      ),
    );
  }
}
