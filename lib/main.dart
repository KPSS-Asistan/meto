import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kpss_2026/core/repositories/lesson_repository.dart';
import 'package:kpss_2026/core/repositories/progress_repository.dart';
import 'package:kpss_2026/core/repositories/question_repository.dart';
import 'package:kpss_2026/core/repositories/topic_repository.dart';
import 'package:kpss_2026/core/services/notification_service.dart';
import 'package:kpss_2026/core/services/purchase_service.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'firebase_options.dart';

void main() async {
  // ═══════════════════════════════════════════════════════════════════════════
  // FLUTTER & FIREBASE INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════
  WidgetsFlutterBinding.ensureInitialized();
  
  // ⚡ Firebase MUTLAKA await edilmeli - Auth için gerekli
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CRASHLYTICS - Hata Takibi
  // ═══════════════════════════════════════════════════════════════════════════
  if (!kDebugMode) {
    // Production'da Crashlytics aktif
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    
    // Flutter hatalarını Crashlytics'e gönder
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    
    // Async hataları yakala
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } else {
    // Debug modda Crashlytics kapalı
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PERFORMANCE MONITORING
  // ═══════════════════════════════════════════════════════════════════════════
  if (!kDebugMode) {
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS - Bildirim Servisi
  // ═══════════════════════════════════════════════════════════════════════════
  await NotificationService.initialize();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // IN-APP PURCHASE - Satın Alma Servisi
  // ═══════════════════════════════════════════════════════════════════════════
  await PurchaseService.initialize();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // RUN APP
  // ═══════════════════════════════════════════════════════════════════════════
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider()..init(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MultiRepositoryProvider(
            providers: [
              // ⚡ HARDCODED REPOSITORIES - Firebase bağımlılığı yok, anında yüklenir
              RepositoryProvider(create: (_) => LessonRepository()),
              RepositoryProvider(create: (_) => TopicRepository()),
              RepositoryProvider(create: (_) => QuestionRepository()),
              RepositoryProvider(create: (_) => ProgressRepository()),
            ],
            child: MaterialApp.router(
              title: 'KPSS ASİSTAN 2026',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              routerConfig: appRouter,
              locale: const Locale('tr', 'TR'),
              supportedLocales: const [
                Locale('tr', 'TR'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          );
        },
      ),
    );
  }
}
