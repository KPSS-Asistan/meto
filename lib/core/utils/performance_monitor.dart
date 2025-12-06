import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Performance monitoring utility - Firebase Performance entegrasyonu
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<int>> _metrics = {};
  static final Map<String, Trace> _traces = {};
  static final FirebasePerformance _performance = FirebasePerformance.instance;

  /// Start measuring performance
  static Future<void> start(String operationName) async {
    _startTimes[operationName] = DateTime.now();
    
    // Firebase Performance Trace
    if (kReleaseMode) {
      try {
        final trace = _performance.newTrace(operationName);
        await trace.start();
        _traces[operationName] = trace;
      } catch (_) {
        // Silent fail for performance tracking
      }
    }
    
    if (kDebugMode) {
      debugPrint('⏱️ PERFORMANCE: Started - $operationName');
    }
  }

  /// Stop measuring and log performance
  static Future<void> stop(String operationName) async {
    final startTime = _startTimes[operationName];
    if (startTime == null) {
      return;
    }

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _startTimes.remove(operationName);

    // Store metric
    if (!_metrics.containsKey(operationName)) {
      _metrics[operationName] = [];
    }
    _metrics[operationName]!.add(duration);

    // Firebase Performance Trace
    if (kReleaseMode) {
      try {
        final trace = _traces.remove(operationName);
        await trace?.stop();
      } catch (_) {
        // Silent fail
      }
    }

    if (kDebugMode) {
      debugPrint('⏱️ PERFORMANCE: $operationName took ${duration}ms');
      if (duration > 1000) {
        debugPrint('⚠️ PERFORMANCE WARNING: $operationName is slow');
      }
    }
  }

  /// Measure async operation
  static Future<T> measure<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    await start(operationName);
    try {
      final result = await operation();
      await stop(operationName);
      return result;
    } catch (e) {
      await stop(operationName);
      if (kDebugMode) {
        debugPrint('❌ PERFORMANCE: $operationName failed - $e');
      }
      rethrow;
    }
  }

  /// Get average duration for an operation
  static double? getAverageDuration(String operationName) {
    final metrics = _metrics[operationName];
    if (metrics == null || metrics.isEmpty) return null;

    final sum = metrics.reduce((a, b) => a + b);
    return sum / metrics.length;
  }

  /// Get metrics summary
  static Map<String, Map<String, dynamic>> getSummary() {
    final summary = <String, Map<String, dynamic>>{};

    for (final entry in _metrics.entries) {
      final operationName = entry.key;
      final durations = entry.value;

      if (durations.isEmpty) continue;

      final sorted = List<int>.from(durations)..sort();
      final min = sorted.first;
      final max = sorted.last;
      final avg = durations.reduce((a, b) => a + b) / durations.length;
      final median = sorted[sorted.length ~/ 2];

      summary[operationName] = {
        'count': durations.length,
        'min': min,
        'max': max,
        'avg': avg.toInt(),
        'median': median,
      };
    }

    return summary;
  }

  /// Print metrics summary
  static void printSummary() {
    final summary = getSummary();
    if (summary.isEmpty) {
      debugPrint('📊 PERFORMANCE: No metrics collected');
      return;
    }

    debugPrint('📊 PERFORMANCE SUMMARY:');
    for (final entry in summary.entries) {
      final name = entry.key;
      final metrics = entry.value;
      debugPrint('  $name:');
      debugPrint('    Count: ${metrics['count']}');
      debugPrint('    Min: ${metrics['min']}ms');
      debugPrint('    Max: ${metrics['max']}ms');
      debugPrint('    Avg: ${metrics['avg']}ms');
      debugPrint('    Median: ${metrics['median']}ms');
    }
  }

  /// Clear all metrics
  static void clear() {
    _startTimes.clear();
    _metrics.clear();
    debugPrint('🗑️ PERFORMANCE: Metrics cleared');
  }

  /// Clear specific operation metrics
  static void clearOperation(String operationName) {
    _startTimes.remove(operationName);
    _metrics.remove(operationName);
    debugPrint('🗑️ PERFORMANCE: Cleared metrics for $operationName');
  }
}

/// Performance tracking mixin
mixin PerformanceTracking {
  /// Track widget build performance (sync - no Firebase trace)
  void trackBuild(String widgetName, VoidCallback build) {
    final start = DateTime.now();
    build();
    final duration = DateTime.now().difference(start).inMilliseconds;
    if (kDebugMode && duration > 16) {
      debugPrint('⚠️ Slow build: $widgetName took ${duration}ms');
    }
  }

  /// Track async operation
  Future<T> trackAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) {
    return PerformanceMonitor.measure(operationName, operation);
  }
}
