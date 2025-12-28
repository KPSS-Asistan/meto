/// 🔒 Password Validation Helper
/// Güçlü şifre kontrolü için yardımcı fonksiyonlar
class PasswordValidator {
  /// Minimum şifre uzunluğu
  static const int minLength = 8;
  
  /// Şifre gereksinimleri
  static const List<PasswordRequirement> requirements = [
    PasswordRequirement(
      id: 'length',
      description: 'En az 8 karakter',
      validator: _hasMinLength,
    ),
    PasswordRequirement(
      id: 'uppercase',
      description: 'En az 1 büyük harf',
      validator: _hasUppercase,
    ),
    PasswordRequirement(
      id: 'lowercase',
      description: 'En az 1 küçük harf',
      validator: _hasLowercase,
    ),
    PasswordRequirement(
      id: 'number',
      description: 'En az 1 rakam',
      validator: _hasNumber,
    ),
  ];
  
  /// Şifre geçerli mi?
  static bool isValid(String password) {
    return requirements.every((req) => req.validator(password));
  }
  
  /// Şifre gücü (0.0 - 1.0)
  static double getStrength(String password) {
    if (password.isEmpty) return 0.0;
    
    int score = 0;
    
    // Uzunluk puanı (max 30)
    score += (password.length * 3).clamp(0, 30);
    
    // Karakter çeşitliliği (max 40)
    if (_hasUppercase(password)) score += 10;
    if (_hasLowercase(password)) score += 10;
    if (_hasNumber(password)) score += 10;
    if (_hasSpecialChar(password)) score += 10;
    
    // Karmaşıklık puanı (max 30)
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;
    if (_hasConsecutiveChars(password)) score -= 10;
    
    return (score / 100).clamp(0.0, 1.0);
  }
  
  /// Şifre gücü metni
  static String getStrengthText(String password) {
    final strength = getStrength(password);
    if (strength < 0.3) return 'Çok Zayıf';
    if (strength < 0.5) return 'Zayıf';
    if (strength < 0.7) return 'Orta';
    if (strength < 0.9) return 'Güçlü';
    return 'Çok Güçlü';
  }
  
  /// Şifre gücü rengi
  static int getStrengthColor(String password) {
    final strength = getStrength(password);
    if (strength < 0.3) return 0xFFE53935; // Kırmızı
    if (strength < 0.5) return 0xFFFF9800; // Turuncu
    if (strength < 0.7) return 0xFFFFC107; // Sarı
    if (strength < 0.9) return 0xFF8BC34A; // Açık yeşil
    return 0xFF4CAF50; // Yeşil
  }
  
  /// Karşılanmayan gereksinimleri listele
  static List<PasswordRequirement> getUnmetRequirements(String password) {
    return requirements.where((req) => !req.validator(password)).toList();
  }
  
  /// Karşılanan gereksinimleri listele
  static List<PasswordRequirement> getMetRequirements(String password) {
    return requirements.where((req) => req.validator(password)).toList();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static bool _hasMinLength(String password) => password.length >= minLength;
  
  static bool _hasUppercase(String password) => password.contains(RegExp(r'[A-Z]'));
  
  static bool _hasLowercase(String password) => password.contains(RegExp(r'[a-z]'));
  
  static bool _hasNumber(String password) => password.contains(RegExp(r'[0-9]'));
  
  static bool _hasSpecialChar(String password) => 
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  
  /// Ardışık karakter kontrolü (abc, 123 gibi)
  static bool _hasConsecutiveChars(String password) {
    if (password.length < 3) return false;
    
    for (int i = 0; i < password.length - 2; i++) {
      final c1 = password.codeUnitAt(i);
      final c2 = password.codeUnitAt(i + 1);
      final c3 = password.codeUnitAt(i + 2);
      
      // Ardışık artış veya azalış
      if ((c2 - c1 == 1 && c3 - c2 == 1) || (c1 - c2 == 1 && c2 - c3 == 1)) {
        return true;
      }
    }
    return false;
  }
}

/// Şifre gereksinimi
class PasswordRequirement {
  final String id;
  final String description;
  final bool Function(String) validator;
  
  const PasswordRequirement({
    required this.id,
    required this.description,
    required this.validator,
  });
  
  bool isMet(String password) => validator(password);
}
