import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme provider - Academic Premium style
/// ⚡ OPTIMIZED: Singleton SharedPreferences + Deferred loading
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;
  
  // ⚡ SINGLETON: SharedPreferences instance
  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  /// ⚡ DEFERRED INIT: Arka planda yükle, UI'ı bloklamaz
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // Arka planda yükle
    _loadThemeAsync();
  }
  
  Future<void> _loadThemeAsync() async {
    try {
      final prefs = await _instance; // ⚡ Singleton
      final cached = prefs.getString('theme_mode');
      if (cached != null) {
        final newMode = ThemeMode.values.firstWhere(
          (mode) => mode.name == cached,
          orElse: () => ThemeMode.light,
        );
        if (newMode != _themeMode) {
          _themeMode = newMode;
          notifyListeners();
        }
      }
    } catch (_) {
      // Hata durumunda default tema kullan
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // Gereksiz rebuild önle
    
    _themeMode = mode;
    notifyListeners();
    
    // Arka planda kaydet
    try {
      final prefs = await _instance; // ⚡ Singleton
      await prefs.setString('theme_mode', mode.name);
    } catch (_) {}
  }

  /// Toggle theme
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await setThemeMode(newMode);
  }
}
