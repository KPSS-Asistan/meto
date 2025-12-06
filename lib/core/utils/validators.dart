/// Input validators for forms
/// XSS prevention and security best practices
class Validators {
  Validators._();

  /// Email validator
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email boş olamaz';
    }

    final trimmed = value.trim();

    // Basic format check
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Geçersiz email formatı';
    }

    // XSS prevention
    if (_containsXSS(trimmed)) {
      return 'Geçersiz karakterler';
    }

    // Length check
    if (trimmed.length > 254) {
      return 'Email çok uzun';
    }

    return null;
  }

  /// Password validator
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre boş olamaz';
    }

    if (value.length < 8) {
      return 'Şifre en az 8 karakter olmalı';
    }

    if (value.length > 128) {
      return 'Şifre çok uzun';
    }

    // Complexity requirements
    final hasUpper = value.contains(RegExp(r'[A-Z]'));
    final hasLower = value.contains(RegExp(r'[a-z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));

    if (!hasUpper || !hasLower || !hasDigit) {
      return 'Şifre büyük harf, küçük harf ve rakam içermeli';
    }

    return null;
  }

  /// Password confirmation validator
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Şifre tekrarı boş olamaz';
      }

      if (value != password) {
        return 'Şifreler eşleşmiyor';
      }

      return null;
    };
  }

  /// Display name validator
  static String? displayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'İsim boş olamaz';
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return 'İsim en az 2 karakter olmalı';
    }

    if (trimmed.length > 50) {
      return 'İsim çok uzun';
    }

    // Only letters, spaces, and Turkish characters
    final nameRegex = RegExp(r'^[a-zA-ZğüşöçıİĞÜŞÖÇ\s]+$');
    if (!nameRegex.hasMatch(trimmed)) {
      return 'İsim sadece harf içermeli';
    }

    // XSS prevention
    if (_containsXSS(trimmed)) {
      return 'Geçersiz karakterler';
    }

    return null;
  }

  /// Required field validator
  static String? required(String? value, [String fieldName = 'Bu alan']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName boş olamaz';
    }
    return null;
  }

  /// Minimum length validator
  static String? Function(String?) minLength(int length, [String fieldName = 'Bu alan']) {
    return (String? value) {
      if (value == null || value.length < length) {
        return '$fieldName en az $length karakter olmalı';
      }
      return null;
    };
  }

  /// Maximum length validator
  static String? Function(String?) maxLength(int length, [String fieldName = 'Bu alan']) {
    return (String? value) {
      if (value != null && value.length > length) {
        return '$fieldName en fazla $length karakter olabilir';
      }
      return null;
    };
  }

  /// Phone number validator (Turkish format)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası boş olamaz';
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');

    // Turkish phone format: 05XX XXX XX XX or +90 5XX XXX XX XX
    final phoneRegex = RegExp(r'^(\+90|0)?5[0-9]{9}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Geçersiz telefon numarası';
    }

    return null;
  }

  /// Numeric only validator
  static String? numeric(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Sadece rakam girilmeli';
    }

    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Check for XSS attack patterns
  static bool _containsXSS(String value) {
    final xssPatterns = [
      '<script',
      '</script',
      'javascript:',
      'onerror=',
      'onload=',
      'onclick=',
      '<img',
      '<iframe',
      '<svg',
      'eval(',
      'alert(',
    ];

    final lowerValue = value.toLowerCase();
    return xssPatterns.any((pattern) => lowerValue.contains(pattern));
  }
}
