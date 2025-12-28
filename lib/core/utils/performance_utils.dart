import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// ⚡ Performance Utilities
/// Uygulama performansını optimize etmek için yardımcı fonksiyonlar
class PerformanceUtils {
  PerformanceUtils._();

  /// Frame callback sonrası çalıştır (UI block'unu önler)
  static void runAfterFrame(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) => callback());
  }

  /// Debounce - Belirli süre içinde tekrar çağrılırsa iptal et
  static final Map<String, DateTime> _debounceTimers = {};
  
  static bool shouldDebounce(String key, Duration duration) {
    final now = DateTime.now();
    final lastCall = _debounceTimers[key];
    
    if (lastCall != null && now.difference(lastCall) < duration) {
      return true; // Debounce - işlemi atla
    }
    
    _debounceTimers[key] = now;
    return false;
  }

  /// Throttle - Belirli sürede maksimum 1 kez çalıştır
  static final Map<String, DateTime> _throttleTimers = {};
  
  static bool shouldThrottle(String key, Duration duration) {
    final now = DateTime.now();
    final lastCall = _throttleTimers[key];
    
    if (lastCall != null && now.difference(lastCall) < duration) {
      return true; // Throttle - işlemi atla
    }
    
    _throttleTimers[key] = now;
    return false;
  }

  /// Clear all timers
  static void clearTimers() {
    _debounceTimers.clear();
    _throttleTimers.clear();
  }
}

/// ⚡ Optimized Widget Builders
class OptimizedWidgets {
  OptimizedWidgets._();

  /// Memory-optimized ListView with auto-dispose
  static Widget lazyList({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    EdgeInsets? padding,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    ScrollController? controller,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      controller: controller,
      addAutomaticKeepAlives: false, // Memory optimization
      addRepaintBoundaries: true, // Paint optimization
    );
  }

  /// Optimized GridView
  static Widget lazyGrid({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required SliverGridDelegate gridDelegate,
    EdgeInsets? padding,
    ScrollPhysics? physics,
  }) {
    return GridView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      gridDelegate: gridDelegate,
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
    );
  }

  /// Wrap with RepaintBoundary for animations
  static Widget repaintBoundary({required Widget child}) {
    return RepaintBoundary(child: child);
  }
}

/// ⚡ Mixin for optimized StatefulWidget
mixin OptimizedStateMixin<T extends StatefulWidget> on State<T> {
  /// Debounced setState - prevents rapid rebuilds
  void setStateDebounced(VoidCallback fn, {Duration delay = const Duration(milliseconds: 100)}) {
    if (PerformanceUtils.shouldDebounce('setState_$hashCode', delay)) return;
    if (mounted) setState(fn);
  }

  /// Safe setState that checks mounted
  void setStateSafe(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  /// Run after current frame completes
  void runAfterBuild(VoidCallback callback) {
    PerformanceUtils.runAfterFrame(callback);
  }
}

/// ⚡ Extension for BuildContext optimizations
extension ContextOptimizations on BuildContext {
  /// Get theme without rebuilding on theme changes
  ThemeData get themeData => Theme.of(this);
  
  /// Check if dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// Get screen size
  Size get screenSize => MediaQuery.sizeOf(this);
  
  /// Get safe area padding
  EdgeInsets get safePadding => MediaQuery.paddingOf(this);
}
