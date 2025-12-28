import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kpss_2026/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:kpss_2026/features/dashboard/cubit/dashboard_state.dart';
import 'package:kpss_2026/features/dashboard/widgets/lesson_card.dart';

/// Dersler Sayfası - Header Kaldırıldı, Performans Optimizasyonlu
class LessonsPage extends StatelessWidget {
  const LessonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF101C22) : const Color(0xFFF5F7F8);

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocBuilder<DashboardCubit, DashboardState>(
        buildWhen: (prev, curr) => prev.lessons != curr.lessons,
        builder: (context, state) {
          if (state.lessons.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            itemCount: state.lessons.length,
            itemBuilder: (context, index) {
              return LessonCard(lesson: state.lessons[index]);
            },
          );
        },
      ),
    );
  }
}
