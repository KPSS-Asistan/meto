import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import 'package:kpss_2026/core/theme/app_sizes.dart';

/// Enhanced loading shimmer widgets - Academic Premium style
class LoadingShimmer {
  /// Card shimmer
  static Widget card({
    double? width,
    double height = 120,
    double borderRadius = AppSizes.radiusLarge,
  }) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.background,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// List item shimmer
  static Widget listItem({
    double height = 80,
  }) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.background,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: AppSizes.space12),
        padding: const EdgeInsets.all(AppSizes.space16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
            const SizedBox(width: AppSizes.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space8),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Grid item shimmer
  static Widget gridItem() {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.background,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
            const SizedBox(height: AppSizes.space12),
            Container(
              height: 14,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSizes.space4),
            Container(
              height: 10,
              width: 50,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Text line shimmer
  static Widget textLine({
    double? width,
    double height = 16,
  }) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.background,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Circle shimmer (for avatars)
  static Widget circle({
    double size = 48,
  }) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.background,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Full page shimmer (for topic list, etc.)
  static Widget page() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.space20),
      itemCount: 6,
      itemBuilder: (context, index) => listItem(),
    );
  }

  /// Grid page shimmer (for lessons, etc.)
  static Widget gridPage({int itemCount = 6}) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.space20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: AppSizes.space12,
        mainAxisSpacing: AppSizes.space12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => gridItem(),
    );
  }
}
