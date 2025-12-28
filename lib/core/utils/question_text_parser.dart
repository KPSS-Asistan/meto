/// Soru metinlerini parse eden yardımcı sınıf
/// FormattedQuestionText widget'ından ayrıştırılmış iş mantığı
class QuestionTextParser {
  
  /// Metni maddelere ayırır (I. II. III. veya 1. 2. 3. formatında)
  static List<String> splitIntoBullets(String input) {
    // Önce metni ön işle: Roma rakamlarının önüne newline ekle
    var processed = input;
    
    // Uzundan kısaya sırayla işle
    for (final numeral in ['VIII', 'VII', 'III', 'II', 'IV', 'VI', 'IX', 'V', 'X', 'I']) {
      final pattern = '$numeral. ';
      int pos = 0;
      while ((pos = processed.indexOf(pattern, pos)) != -1) {
        // Önceki karakter harf veya rakam olmamalı (Roma rakamının parçası değil)
        if (pos > 0) {
          final prevChar = processed[pos - 1];
          // I, V, X harfleri Roma rakamının parçası olabilir
          if (RegExp(r'[A-Za-z0-9]').hasMatch(prevChar)) {
            pos++;
            continue;
          }
          // Önceki karakterden sonra newline ekle
          processed = '${processed.substring(0, pos)}\n${processed.substring(pos)}';
          pos += 2; // newline eklendi, 1 karakter atla
        } else {
          // Metin bu numeral ile başlıyor
          pos++;
        }
      }
    }
    
    // Newline'lara göre böl
    final lines = processed.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    
    if (lines.length < 2) {
      return splitByNumbers(input);
    }
    
    // İlk maddenin I. ile başladığını kontrol et
    bool hasValidStart = false;
    int bulletStartIndex = 0;
    
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('I. ')) {
        hasValidStart = true;
        bulletStartIndex = i;
        break;
      }
    }
    
    if (!hasValidStart) {
      return splitByNumbers(input);
    }
    
    // En az 3 madde olmalı
    final bulletCount = lines.length - bulletStartIndex;
    if (bulletCount < 3) {
      return splitByNumbers(input);
    }
    
    // Giriş metninin sonundaki noktalamayı temizle
    if (bulletStartIndex > 0) {
      var intro = lines.sublist(0, bulletStartIndex).join(' ').trim();
      while (intro.isNotEmpty && '?!.;:,'.contains(intro[intro.length - 1])) {
        intro = intro.substring(0, intro.length - 1).trim();
      }
      if (intro.isNotEmpty) {
        return [intro, ...lines.sublist(bulletStartIndex)];
      }
    }
    
    return lines.sublist(bulletStartIndex);
  }
  
  /// Sayı formatında maddeleri ayır (1. 2. 3. vb.)
  static List<String> splitByNumbers(String input) {
    final numberPattern = RegExp(r'(?:^|\s)(\d+)\.\s');
    final numberMatches = numberPattern.allMatches(input).toList();
    
    if (numberMatches.length >= 3) {
      final firstMatch = numberMatches.first;
      if (firstMatch.group(1) != '1') return [input];
      
      final result = <String>[];
      
      final beforeFirst = input.substring(0, firstMatch.start).trim();
      if (beforeFirst.isNotEmpty) {
        result.add(beforeFirst);
      }
      
      for (int i = 0; i < numberMatches.length; i++) {
        int start = numberMatches[i].start;
        if (input[start] == ' ' || input[start] == '\n') start++;
        
        final end = i < numberMatches.length - 1 
            ? numberMatches[i + 1].start 
            : input.length;
        
        final part = input.substring(start, end).trim();
        if (part.isNotEmpty) result.add(part);
      }
      
      return result;
    }
    
    return [input];
  }

  /// Nokta+harf arasına boşluk ekler (madde numaraları hariç)
  /// Örn: "devletidir.II." → "devletidir. II."
  static String addSpaceAfterPeriod(String input) {
    // Nokta + büyük/küçük harf (ama madde numarası değilse)
    final normalized = input.replaceAllMapped(
      RegExp(r'\.([A-Za-zÇĞİÖŞÜçğıöşü])'),
      (match) {
        final nextChar = match.group(1)!;
        return '. $nextChar';
      },
    );

    return insertMissingSpaces(normalized);
  }

  /// Küçük harfi doğrudan izleyen büyük harflerde araya boşluk ekler
  static String insertMissingSpaces(String input) {
    // Soru kökü başlangıçları - bunlardan önce satır sonu ekle
    final questionStarters = [
      'Yukarıdaki', 'Yukarıda', 'Aşağıdaki', 'Aşağıda',
      'Buna', 'Bununla', 'Bu', 'Hangisi', 'Hangileri',
      'Verilen', 'Parçaya', 'Metne', 'Tabloya',
    ];
    
    var result = input;
    
    // Önce soru kökü başlangıçlarını kontrol et
    for (final starter in questionStarters) {
      // küçük harf + starter pattern
      final pattern = RegExp('([a-zçğıöşü])($starter)', unicode: true);
      result = result.replaceAllMapped(pattern, (match) {
        return '${match.group(1)}\n${match.group(2)}';
      });
    }
    
    // Kalan küçük+büyük harf kombinasyonlarına boşluk ekle
    final spacePattern = RegExp(r'(?<=[a-zçğıöşü])(?=[A-ZÇĞİÖŞÜ])', unicode: true);
    result = result.replaceAll(spacePattern, ' ');
    
    return result;
  }

  /// Soru metnini bağlam ve soru kökü olarak ayırır
  /// Sadece 250+ karakterli uzun sorularda ayrım yapar
  static Map<String, String> splitContextAndQuestion(String input) {
    // Kısa sorularda ayrım yapma
    if (input.length < 250) {
      return {'context': '', 'question': input};
    }
    
    // Soru kökü pattern'leri
    final questionPatterns = [
      r'Bu bağlamda[,\s]',
      r'Buna göre[,\s]',
      r'Yukarıdaki bilgilere göre[,\s]',
      r'Yukarıda verilen bilgilere göre[,\s]',
      r'Aşağıdakilerden hangisi',
      r'Hangisi',
      r'Hangileri',
    ];
    
    // Cümlelere ayır
    final sentences = input.split(RegExp(r'(?<=[.?!])\s+'));
    
    if (sentences.length <= 1) {
      return {'context': '', 'question': input};
    }
    
    // Soru pattern'i ile başlayan cümleyi bul (sondan başa)
    for (int i = sentences.length - 1; i >= 0; i--) {
      final sentence = sentences[i].trim();
      if (questionPatterns.any((p) => RegExp(p, caseSensitive: false).hasMatch(sentence))) {
        final context = sentences.sublist(0, i).join(' ').trim();
        final question = sentences.sublist(i).join(' ').trim();
        // Bağlam en az 100 karakter olmalı
        if (context.length >= 100) {
          return {'context': context, 'question': question};
        }
      }
    }
    
    return {'context': '', 'question': input};
  }

  /// Madde satırı mı kontrol et
  static bool isBulletLine(String line) {
    final romanBulletPattern = RegExp(r'^(I{1,3}|IV|VI{0,3}|IX|X)\.\s+');
    final numberBulletPattern = RegExp(r'^(\d+)\.\s+');
    return romanBulletPattern.hasMatch(line) || numberBulletPattern.hasMatch(line);
  }

  /// Madde numarasını çıkar
  static String? extractBulletNumber(String line) {
    final romanBulletPattern = RegExp(r'^(I{1,3}|IV|VI{0,3}|IX|X)\.\s+');
    final numberBulletPattern = RegExp(r'^(\d+)\.\s+');
    
    var match = romanBulletPattern.firstMatch(line);
    if (match != null) return match.group(1);
    
    match = numberBulletPattern.firstMatch(line);
    if (match != null) return match.group(1);
    
    return null;
  }

  /// Madde içeriğini çıkar (numara hariç)
  static String extractBulletContent(String line) {
    final romanBulletPattern = RegExp(r'^(I{1,3}|IV|VI{0,3}|IX|X)\.\s+');
    final numberBulletPattern = RegExp(r'^(\d+)\.\s+');
    
    if (romanBulletPattern.hasMatch(line)) {
      return line.replaceFirst(romanBulletPattern, '');
    }
    if (numberBulletPattern.hasMatch(line)) {
      return line.replaceFirst(numberBulletPattern, '');
    }
    return line;
  }
}

/// Parse edilmiş soru verisi
class ParsedQuestionData {
  final String mainQuestion;
  final List<BulletItem> bulletItems;
  final String questionRoot;
  final String context;

  const ParsedQuestionData({
    required this.mainQuestion,
    required this.bulletItems,
    required this.questionRoot,
    required this.context,
  });

  bool get hasBullets => bulletItems.length >= 3;
  bool get hasContext => context.isNotEmpty;
}

/// Madde item modeli
class BulletItem {
  final String number;
  final String content;

  const BulletItem({
    required this.number,
    required this.content,
  });
}
