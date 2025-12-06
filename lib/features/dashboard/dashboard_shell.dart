import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kpss_2026/core/repositories/lesson_repository.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import 'package:kpss_2026/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:kpss_2026/features/dashboard/cubit/dashboard_state.dart';
import 'package:kpss_2026/features/dashboard/pages/home_page.dart';
import 'package:kpss_2026/features/dashboard/pages/productivity_page.dart';
import 'package:kpss_2026/features/dashboard/pages/profile_page.dart';
import 'package:kpss_2026/features/ai_coach/ai_coach_chat_page.dart';



/// Dashboard Shell - Ana container
/// Nav bar ve header her zaman aktif, sayfalar değişiyor
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {


  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit(
        lessonRepository: context.read<LessonRepository>(),
      )..init(), // ⚡ Initialize all data on startup
      child: const _DashboardContent(),
    );
  }
}


class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  // ⚡ LAZY LOADING: Sayfalar sadece ilk ziyarette oluşturulur
  final Map<int, Widget> _loadedPages = {};
  
  Widget _getPage(int index, DashboardState state) {
    if (_loadedPages.containsKey(index)) {
      // Profil sayfası displayName değişebilir
      if (index == 3) {
        return ProfilePage(displayName: state.displayName);
      }
      return _loadedPages[index]!;
    }
    
    // İlk kez yükle
    final page = switch (index) {
      0 => const HomePage(),
      1 => const AICoachChatPage(),
      2 => const ProductivityPage(),
      3 => ProfilePage(displayName: state.displayName),
      _ => const HomePage(),
    };
    _loadedPages[index] = page;
    return page;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              // Header - Her zaman görünür
              _buildHeader(context, state),
              
              // ⚡ LAZY: Sadece aktif sayfa yüklenir
              Expanded(
                child: _getPage(state.selectedIndex, state),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(context, state),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DashboardState state) {
    final displayName = state.displayName;
    final isGuest = displayName == null || displayName.isEmpty || displayName == 'Misafir';
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Sol taraf - Selamlama
            Expanded(
              child: displayName == null
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : Text(
                      isGuest 
                          ? '${_getGreeting()} 👋'
                          : '${_getGreeting()}, $displayName 👋',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            
            const SizedBox(width: 12),
            
            // Sağ taraf - İkonlar
            // Premium (Taç) ikonu - Altın rengi
            InkWell(
              onTap: () => context.push('/premium'),
              borderRadius: BorderRadius.circular(8),
              child: Tooltip(
                message: 'Premium',
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Bildirimler
            InkWell(
              onTap: () {
                // TODO: Navigate to notifications
              },
              borderRadius: BorderRadius.circular(8),
              child: Tooltip(
                message: 'Bildirimler',
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 22,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, DashboardState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                0,
                Icons.home_outlined,
                Icons.home_rounded,
                'Ana Sayfa',
                state.selectedIndex == 0,
              ),
              _buildNavItem(
                context,
                1,
                Icons.smart_toy_outlined,
                Icons.smart_toy_rounded,
                'AI Koç',
                state.selectedIndex == 1,
              ),
              _buildNavItem(
                context,
                2,
                Icons.trending_up_outlined,
                Icons.trending_up_rounded,
                'Verimlilik',
                state.selectedIndex == 2,
              ),
              _buildNavItem(
                context,
                3,
                Icons.person_outline,
                Icons.person,
                'Profil',
                state.selectedIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    bool isSelected,
  ) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GestureDetector(
          onTap: () {
            final cubit = context.read<DashboardCubit>();
            cubit.changeTab(index);
            // ⚡ Ana Sayfa'ya dönünce istatistikleri yenile
            if (index == 0) {
              cubit.refreshStats();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            transform: isSelected
                ? Matrix4.translationValues(0, -2, 0)  // Hafif yukarı kayma
                : Matrix4.identity(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ] : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Icon(
                      isSelected ? filledIcon : outlinedIcon,
                      key: ValueKey(isSelected), // AnimatedSwitcher için gerekli
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Saat bazlı selamlama
  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Günaydın';
    } else if (hour >= 12 && hour < 18) {
      return 'İyi günler';
    } else if (hour >= 18 && hour < 22) {
      return 'İyi akşamlar';
    } else {
      return 'İyi geceler';
    }
  }
}
