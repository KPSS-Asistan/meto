import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../animations/app_animations.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/dashboard/dashboard_shell.dart';
import '../../features/lessons/module_selection_page.dart';
import '../../features/lessons/topic_explanation_page.dart';
import '../../features/lessons/topic_list_page.dart';
import '../../features/stories/topic_story_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/productivity/technique_category_page.dart';
import '../../features/productivity/technique_detail_page.dart';
import '../../features/profile/display_name_setup_page.dart';
import '../../features/quiz/quiz_page.dart';
import '../../features/quiz/test_results_page.dart';
import '../../features/ai_coach/ai_coach_chat_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/settings/help_page.dart';
import '../../features/settings/about_page.dart';
import '../../features/settings/feedback_page.dart';
import '../../features/games/matching_game_page.dart';
import '../../features/games/mnemonics_page.dart';
import '../../features/games/mnemonics_selection_page.dart';
import '../../features/premium/premium_page.dart';
// quiz_classic_page.dart kaldırıldı - ana quiz_page.dart kullanılıyor
import '../../features/flashcards/presentation/pages/flashcard_page.dart';
import '../../features/lessons/visual_summary_page.dart';
import '../../features/settings/privacy_policy_page.dart';
import '../../features/settings/terms_of_service_page.dart';
import '../../features/dev_tools/dev_tools_page.dart';
import '../../features/streak/streak_calendar_page.dart';
import '../../features/quiz/presentation/pages/quiz_hardcoded_page.dart';
import '../../features/favorites/favorites_page.dart';
import '../../features/wrong_answers/wrong_answers_page.dart';
import '../../features/study_schedule/study_schedule_page.dart';

class AuthNotifier extends ValueNotifier<User?> {
  AuthNotifier() : super(FirebaseAuth.instance.currentUser) {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      value = user;
    });
  }
}

final authNotifier = AuthNotifier();

final appRouter = GoRouter(
  initialLocation: '/dashboard',  // ⚡ Direkt dashboard'a git
  redirect: (BuildContext context, GoRouterState state) {
    final bool isLoggedIn = authNotifier.value != null;
    
    // Auth gerektiren sayfalar
    final authRequiredRoutes = ['/dashboard', '/ai-coach', '/settings', '/premium'];
    final isAuthRequiredRoute = authRequiredRoutes.any((route) => state.matchedLocation.startsWith(route));
    
    // Giriş yapmamışsa ve auth gerekliyse → giriş sayfasına
    if (!isLoggedIn && isAuthRequiredRoute) {
      return '/auth';
    }
    
    // Giriş yapmışsa ve auth sayfasındaysa → dashboard'a
    if (isLoggedIn && state.matchedLocation == '/auth') {
      return '/dashboard';
    }
    
    return null; // Normal navigation
  },
  refreshListenable: authNotifier,
  routes: [
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingPage(),
        transitionsBuilder: AppPageTransition.fadeTransition,
      ),
    ),
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginPage(),
        transitionsBuilder: AppPageTransition.slideTransition,
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RegisterPage(),
        transitionsBuilder: AppPageTransition.slideTransition,
      ),
    ),
    GoRoute(
      path: '/setup-name',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const DisplayNameSetupPage(),
        transitionsBuilder: AppPageTransition.fadeTransition,
      ),
    ),
    GoRoute(
      path: '/dashboard',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const DashboardShell(),
        transitionsBuilder: AppPageTransition.scaleTransition,
      ),
    ),
    GoRoute(
      path: '/productivity/category/:category',
      builder: (context, state) {
        final category = state.pathParameters['category']!;
        return TechniqueCategoryPage(category: category);
      },
    ),
    GoRoute(
      path: '/productivity/technique/:techniqueId',
      builder: (context, state) {
        final techniqueId = state.pathParameters['techniqueId']!;
        return TechniqueDetailPage(techniqueId: techniqueId);
      },
    ),
    GoRoute(
      path: '/lessons/:lessonId/topics',
      builder: (context, state) {
        final lessonId = state.pathParameters['lessonId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final lessonName = extra?['lessonName'] as String? ?? 'Ders';

        return TopicListPage(
          lessonId: lessonId,
          lessonName: lessonName,
        );
      },
    ),
    GoRoute(
      path: '/lessons/:lessonId/topics/:topicId/modules',
      builder: (context, state) {
        final lessonId = state.pathParameters['lessonId']!;
        final topicId = state.pathParameters['topicId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final topicName = extra?['topicName'] as String? ?? 'Konu';
        final lessonName = extra?['lessonName'] as String? ?? 'Ders';

        return ModuleSelectionPage(
          lessonId: lessonId,
          topicId: topicId,
          topicName: topicName,
          lessonName: lessonName,
        );
      },
    ),
    GoRoute(
      path: '/lessons/:lessonId/topics/:topicId/explanation',
      builder: (context, state) {
        final lessonId = state.pathParameters['lessonId']!;
        final topicId = state.pathParameters['topicId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final topicName = extra?['topicName'] as String? ?? 'Konu Anlatımı';
        final lessonName = extra?['lessonName'] as String? ?? 'Ders';

        return TopicExplanationPage(
          lessonId: lessonId,
          topicId: topicId,
          topicName: topicName,
          lessonName: lessonName,
        );
      },
    ),
    GoRoute(
      path: '/lessons/:lessonId/topics/:topicId/story',
      builder: (context, state) {
        final lessonId = state.pathParameters['lessonId']!;
        final topicId = state.pathParameters['topicId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final topicName = extra?['topicName'] as String? ?? 'Hikaye';
        final lessonName = extra?['lessonName'] as String? ?? 'Ders';

        return TopicStoryPage(
          lessonId: lessonId,
          topicId: topicId,
          topicName: topicName,
          lessonName: lessonName,
        );
      },
    ),
    GoRoute(
      path: '/lessons/:lessonId/topics/:topicId/visual-summary',
      builder: (context, state) {
        final lessonId = state.pathParameters['lessonId']!;
        final topicId = state.pathParameters['topicId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final topicName = extra?['topicName'] as String? ?? 'Görsel Özet';
        final lessonName = extra?['lessonName'] as String? ?? 'Ders';

        return VisualSummaryPage(
          lessonId: lessonId,
          topicId: topicId,
          topicName: topicName,
          lessonName: lessonName,
        );
      },
    ),
    GoRoute(
      path: '/lessons/:lessonId/topics/:topicId/quiz',
      builder: (context, state) {
        final lessonId = state.pathParameters['lessonId']!;
        final topicId = state.pathParameters['topicId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final topicName = extra?['topicName'] as String? ?? 'Test';

        return QuizPage(
          lessonId: lessonId,
          topicId: topicId,
          topicName: topicName,
        );
      },
    ),
    GoRoute(
      path: '/quiz-results',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return TestResultsPage(
          totalQuestions: extra['totalQuestions'] as int,
          correctAnswers: extra['correctAnswers'] as int,
          wrongAnswers: extra['wrongAnswers'] as int,
          timeSpent: extra['timeSpent'] as int,
          topicId: extra['topicId'] as String? ?? '',
          topicName: extra['topicName'] as String,
        );
      },
    ),
    GoRoute(
      path: '/ai-coach',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AICoachChatPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpPage(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
    GoRoute(
      path: '/terms-of-service',
      builder: (context, state) => const TermsOfServicePage(),
    ),
    GoRoute(
      path: '/feedback',
      builder: (context, state) => const FeedbackPage(),
    ),
    GoRoute(
      path: '/lessons/:lessonId/topics/:topicId/matching',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return MatchingGamePage(
          lessonId: state.pathParameters['lessonId']!,
          topicId: state.pathParameters['topicId']!,
          topicName: extra['topicName'] as String,
        );
      },
    ),
    GoRoute(
      path: '/lessons/:lessonId/topics/:topicId/mnemonics',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return MnemonicsPage(
          lessonId: state.pathParameters['lessonId']!,
          topicId: state.pathParameters['topicId']!,
          topicName: extra['topicName'] as String,
        );
      },
    ),
    // /quiz/:setId route kaldırıldı - ana quiz sayfası kullanılıyor
    GoRoute(
      path: '/flashcards/:topicId',
      builder: (context, state) {
        final topicId = state.pathParameters['topicId']!;
        return FlashcardPage(topicId: topicId);
      },
    ),
    GoRoute(
      path: '/dev-tools',
      builder: (context, state) => const DevToolsPage(),
    ),
    GoRoute(
      path: '/streak-calendar',
      builder: (context, state) => const StreakCalendarPage(),
    ),
    GoRoute(
      path: '/mnemonics',
      builder: (context, state) => const MnemonicsSelectionPage(),
    ),
    GoRoute(
      path: '/quiz-hardcoded',
      builder: (context, state) => const QuizHardcodedPage(),
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumPage(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
      path: '/wrong-answers',
      builder: (context, state) => const WrongAnswersPage(),
    ),
    GoRoute(
      path: '/study-schedule',
      builder: (context, state) => const StudySchedulePage(),
    ),
  ],
);
