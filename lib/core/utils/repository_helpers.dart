import 'package:kpss_2026/core/utils/app_logger.dart';
import 'package:kpss_2026/core/utils/error_handler.dart';

/// Repository helper functions for consistent error handling
class RepositoryHelpers {
  /// Execute operation with error handling and return Result
  static Future<Result<T>> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      final data = await operation();
      return Result.success(data);
    } catch (e, stack) {
      if (operationName != null) {
        AppLogger.error('$operationName failed', e, stack);
      } else {
        AppLogger.error('Repository operation failed', e, stack);
      }
      final message = ErrorHandler.handleGenericError(e);
      return Result.failure(message, e);
    }
  }

  /// Execute operation with default value on error
  static Future<T> executeWithDefault<T>(
    Future<T> Function() operation,
    T defaultValue, {
    String? operationName,
  }) async {
    try {
      return await operation();
    } catch (e, stack) {
      if (operationName != null) {
        AppLogger.error('$operationName failed, using default', e, stack);
      }
      return defaultValue;
    }
  }

  /// Execute operation and return null on error
  static Future<T?> executeOrNull<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      return await operation();
    } catch (e, stack) {
      if (operationName != null) {
        AppLogger.error('$operationName failed', e, stack);
      }
      return null;
    }
  }
}

/// Extension for easier Result handling in UI
extension ResultExtension<T> on Result<T> {
  /// Show error snackbar if failure
  void showErrorIfFailure(dynamic context) {
    if (this case Failure(:final message)) {
      ErrorHandler.showErrorSnackbar(context, message);
    }
  }

  /// Get data or throw
  T get dataOrThrow {
    return switch (this) {
      Success(:final data) => data,
      Failure(:final message) => throw Exception(message),
    };
  }

  /// Fold with async handlers
  Future<R> foldAsync<R>({
    required Future<R> Function(T data) onSuccess,
    required Future<R> Function(String message) onFailure,
  }) async {
    return switch (this) {
      Success(:final data) => await onSuccess(data),
      Failure(:final message) => await onFailure(message),
    };
  }
}
