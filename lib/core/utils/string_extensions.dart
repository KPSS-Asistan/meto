extension StringExtensions on String {
  /// Turkish-aware uppercase conversion
  /// Handles Turkish characters correctly: i → İ, ı → I
  String toUpperCaseTurkish() {
    const turkishMap = {
      'i': 'İ',
      'ı': 'I',
      'ş': 'Ş',
      'ğ': 'Ğ',
      'ü': 'Ü',
      'ö': 'Ö',
      'ç': 'Ç',
    };

    return split('').map((char) {
      return turkishMap[char] ?? char.toUpperCase();
    }).join('');
  }

  /// Turkish-aware lowercase conversion
  /// Handles Turkish characters correctly: İ → i, I → ı
  String toLowerCaseTurkish() {
    const turkishMap = {
      'İ': 'i',
      'I': 'ı',
      'Ş': 'ş',
      'Ğ': 'ğ',
      'Ü': 'ü',
      'Ö': 'ö',
      'Ç': 'ç',
    };

    return split('').map((char) {
      return turkishMap[char] ?? char.toLowerCase();
    }).join('');
  }

  /// Converts string to title case (first letter of each word capitalized)
  /// Uses Turkish-aware character conversion
  /// Example: "osmanlı tarihi" -> "Osmanlı Tarihi"
  String toTitleCase() {
    if (isEmpty) return this;

    return split(' ').map((word) {
      if (word.isEmpty) return word;
      final firstChar = word[0].toUpperCaseTurkish();
      final rest = word.substring(1).toLowerCaseTurkish();
      return firstChar + rest;
    }).join(' ');
  }
}
