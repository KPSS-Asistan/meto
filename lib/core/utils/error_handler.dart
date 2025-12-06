import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';

/// Global error handler - Academic Premium style
class ErrorHandler {
  /// Handle Firebase Auth errors
  static String handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Hatalı şifre';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalı';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda kullanılamıyor';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri';
      case 'account-exists-with-different-credential':
        return 'Bu e-posta farklı bir giriş yöntemi ile kayıtlı';
      case 'requires-recent-login':
        return 'Bu işlem için tekrar giriş yapmanız gerekiyor';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin';
      default:
        return 'Bir hata oluştu: ${error.message ?? "Bilinmeyen hata"}';
    }
  }

  /// Handle Firestore errors
  static String handleFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok';
      case 'unavailable':
        return 'Servis şu anda kullanılamıyor. Lütfen daha sonra deneyin';
      case 'not-found':
        return 'İstenen veri bulunamadı';
      case 'already-exists':
        return 'Bu veri zaten mevcut';
      case 'resource-exhausted':
        return 'Kaynak limiti aşıldı';
      case 'failed-precondition':
        return 'İşlem gereksinimleri karşılanmadı';
      case 'aborted':
        return 'İşlem iptal edildi';
      case 'out-of-range':
        return 'Geçersiz değer aralığı';
      case 'unimplemented':
        return 'Bu özellik henüz desteklenmiyor';
      case 'internal':
        return 'Sunucu hatası oluştu';
      case 'deadline-exceeded':
        return 'İşlem zaman aşımına uğradı';
      case 'cancelled':
        return 'İşlem iptal edildi';
      default:
        return 'Veri işlemi sırasında hata oluştu: ${error.message ?? "Bilinmeyen hata"}';
    }
  }

  /// Handle generic errors
  static String handleGenericError(dynamic error) {
    if (error is FirebaseAuthException) {
      return handleAuthError(error);
    } else if (error is FirebaseException) {
      return handleFirestoreError(error);
    } else if (error is FormatException) {
      return 'Geçersiz veri formatı';
    } else if (error is TypeError) {
      return 'Veri tipi hatası oluştu';
    } else {
      return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  /// Show error snackbar
  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info snackbar
  static void showInfoSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Log error with Crashlytics
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    AppLogger.error('ErrorHandler caught', error, stackTrace);
  }

  /// Handle and log error, return user-friendly message
  static String handle(dynamic error, [StackTrace? stackTrace]) {
    logError(error, stackTrace);
    return handleGenericError(error);
  }
}

/// Result type for error handling - Either success or failure
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(String message, [Object? error]) = Failure<T>;

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Get data or null
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };

  /// Get error message or null
  String? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final message) => message,
  };

  /// Map success value
  Result<R> map<R>(R Function(T data) mapper) => switch (this) {
    Success(:final data) => Result.success(mapper(data)),
    Failure(:final message, :final error) => Result.failure(message, error),
  };

  /// Handle both cases
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) => switch (this) {
    Success(:final data) => success(data),
    Failure(:final message) => failure(message),
  };
}

/// Success result
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Failure result
final class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  const Failure(this.message, [this.error]);
}
