import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import 'package:kpss_2026/core/theme/app_sizes.dart';
import 'package:kpss_2026/core/widgets/skeleton_loader.dart';
import 'package:kpss_2026/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:kpss_2026/features/dashboard/cubit/dashboard_state.dart';
import '../mixins/dashboard_logic_mixin.dart';
import '../widgets/action_buttons_grid.dart';
import '../widgets/curve_divider.dart';
import '../widgets/daily_goals_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_states.dart';
import '../widgets/exam_selection_sheet.dart';
import '../widgets/home_background_painter.dart';
import '../widgets/lesson_card.dart';

/// Ana sayfa - Dersler, streak, rozetler
/// ⚡ OPTIMIZED: Refactored & Modularized (1200+ Lines -> ~100 Lines)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver, DashboardLogicMixin {
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      buildWhen: (prev, curr) => 
          prev.lessons != curr.lessons ||
          prev.isLoadingLessons != curr.isLoadingLessons ||
          prev.lessonsError != curr.lessonsError,
      builder: (context, state) {
        if (state.lessonsError != null) {
          return DashboardErrorState(error: state.lessonsError!);
        }

        if (!state.isLoadingLessons && state.lessons.isEmpty) {
          return const DashboardEmptyState();
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Stack(
          children: [
            // Arka plan
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: HomeBackgroundPainter(isDark: isDark),
                  size: Size.infinite,
                ),
              ),
            ),
            
            // İçerik
            RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().refreshLessons(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (Welcome / Resume)
                    DashboardHeader(lastStudyFuture: lastStudyFuture),
                    
                    const SizedBox(height: 8),
                    const CurveDivider(),
                    const SizedBox(height: 8),
                    
                    // Daily Goals
                    const DailyGoalsCard(),
                    
                    const SizedBox(height: 8),
                    const CurveDivider(),
                    const SizedBox(height: 8),
                    
                    // Action Buttons
                    ActionButtonsGrid(
                      onDenemeTap: () => showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => const ExamSelectionSheet(),
                      ),
                      onHatalarTap: () => context.push('/wrong-answers'),
                      onFavorilerTap: () => context.push('/favorites'),
                    ),
                    
                    const SizedBox(height: 8),
                    const CurveDivider(),
                    const SizedBox(height: 8),
                    
                    // Lessons Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: state.isLoadingLessons ? 6 : state.lessons.length,
                      itemBuilder: (context, index) {
                        if (state.isLoadingLessons) {
                          return RepaintBoundary(
                            child: SkeletonLoader.lessonCard(),
                          );
                        }
                        
                        return RepaintBoundary(
                          child: LessonCard(lesson: state.lessons[index]),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
