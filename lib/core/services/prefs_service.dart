import 'package:shared_preferences/shared_preferences.dart';

/// ⚡ GLOBAL SINGLETON: SharedPreferences
/// Tüm uygulama tek instance kullanır - disk I/O minimize
class PrefsService {
  static SharedPreferences? _instance;
  static bool _isInitializing = false;
  
  /// ⚡ LAZY SINGLETON: İlk kullanımda init
  static Future<SharedPreferences> get instance async {
    if (_instance != null) return _instance!;
    
    if (!_isInitializing) {
      _isInitializing = true;
      _instance = await SharedPreferences.getInstance();
      _isInitializing = false;
    } else {
      // Başka bir init çalışıyorsa bekle
      while (_instance == null) {
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }
    return _instance!;
  }
  
  /// Senkron erişim (init yapıldıysa)
  static SharedPreferences? get instanceSync => _instance;
  
  /// Pre-warm (optional - splash screen'de çağrılabilir)
  static Future<void> init() async {
    await instance;
  }
}
