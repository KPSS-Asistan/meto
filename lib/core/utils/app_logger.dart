import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// AppLogger - Production-ready logging
/// Debug mode'da print, production'da Crashlytics
class AppLogger {
  static void debug(String message, [Object? data]) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message${data != null ? ' | $data' : ''}');
    }
  }

  static void info(String message, [Object? data]) {
    if (kDebugMode) {
      debugPrint('[INFO] $message${data != null ? ' | $data' : ''}');
    }
  }

  static void success(String message, [Object? data]) {
    if (kDebugMode) {
      debugPrint('[SUCCESS] $message${data != null ? ' | $data' : ''}');
    }
  }

  static void warning(String message, [Object? data]) {
    if (kDebugMode) {
      debugPrint('[WARN] $message${data != null ? ' | $data' : ''}');
    }
    // Production'da Crashlytics'e log yaz
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.log('[WARN] $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('  -> $error');
      if (stackTrace != null) debugPrint('  -> $stackTrace');
    }
    // Production'da Crashlytics'e gönder
    if (kReleaseMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
    }
  }
  
  /// Fatal error - App crash
  static void fatal(String message, Object error, [StackTrace? stackTrace]) {
    debugPrint('[FATAL] $message');
    debugPrint('  -> $error');
    // Her zaman Crashlytics'e gönder
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: message,
      fatal: true,
    );
  }

  /// Network işlemleri için
  static void network(String method, String url, [int? statusCode]) {
    if (kDebugMode) {
      final status = statusCode != null ? ' [$statusCode]' : '';
      debugPrint('[NET] $method $url$status');
    }
  }

  /// Firebase işlemleri için
  static void firebase(String operation, String collection, [String? docId]) {
    if (kDebugMode) {
      final doc = docId != null ? '/$docId' : '';
      debugPrint('[FB] $operation $collection$doc');
    }
  }
}
