import 'package:firebase_auth/firebase_auth.dart';

/// Geliştirici Modu Servisi
/// Sadece belirli e-posta adreslerine test/debug özelliklerini gösterir
class DevModeService {
  DevModeService._();
  
  /// Geliştirici e-posta adresleri
  static const List<String> _developerEmails = [
    '6378226cilingir@gmail.com',
    // Gerekirse başka e-postalar da eklenebilir
  ];
  
  /// Mevcut kullanıcı geliştirici mi?
  static bool get isDeveloper {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return false;
    
    return _developerEmails.contains(user.email!.toLowerCase());
  }
  
  /// Belirli bir e-posta geliştirici mi?
  static bool isEmailDeveloper(String? email) {
    if (email == null) return false;
    return _developerEmails.contains(email.toLowerCase());
  }
  
  /// Geliştirici bilgisini logla (debug)
  static void logDevStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('👤 User: ${user.email}');
      print('🔧 Dev Mode: ${isDeveloper ? 'ENABLED' : 'DISABLED'}');
    }
  }
}
