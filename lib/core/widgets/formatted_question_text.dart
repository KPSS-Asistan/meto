import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soru metnini madde madde formatlayan widget
/// I., II., III. veya 1., 2., 3. gibi maddeleri algılar ve düzgün gösterir
class FormattedQuestionText extends StatelessWidget {
  final String text;
  final int? maxLines;
  final TextOverflow? overflow;
  final double fontSize;
  final bool showBulletCard;

  const FormattedQuestionText({
    super.key,
    required this.text,
    this.maxLines,
    this.overflow,
    this.fontSize = 17,
    this.showBulletCard = true,
  });

  /// Metni maddelere ayırır (I. II. III. veya 1. 2. 3. formatında)
  List<String> _splitIntoBullets(String input) {
    // Sadece geçerli roma rakamları: I, II, III, IV, V, VI, VII, VIII, IX, X
    // ÖNEMLİ: Tek nokta (.) madde DEĞİL, en az bir harf/rakam olmalı
    final romanRegex = RegExp(r'(I{1,3}|IV|VI{0,3}|IX|X)\.\s+');
    
    // Sayı pattern: 1. 2. 3. vb. (en az bir rakam)
    final numberRegex = RegExp(r'(\d+)\.\s+');
    
    // En az 3 roma rakamı maddesi var mı? (I., II., III. gibi)
    // ÖNEMLİ: En az 3 madde olmalı ki yanlış algılama olmasın
    final romanMatches = romanRegex.allMatches(input).toList();
    if (romanMatches.length >= 3) {
      // İlk madde I. ile başlamıyorsa bölme
      if (romanMatches.first.group(1) != 'I') return [input];

      final result = <String>[];
      
      // İlk madde öncesi metin
      if (romanMatches.first.start > 0) {
        final before = input.substring(0, romanMatches.first.start).trim();
        if (before.isNotEmpty) result.add(before);
      }
      
      // Maddeleri ayır
      for (int i = 0; i < romanMatches.length; i++) {
        final start = romanMatches[i].start;
        final end = i < romanMatches.length - 1 ? romanMatches[i + 1].start : input.length;
        final part = input.substring(start, end).trim();
        if (part.isNotEmpty) result.add(part);
      }
      
      return result;
    }
    
    // En az 3 sayı maddesi var mı? (1., 2., 3. gibi)
    // ÖNEMLİ: En az 3 madde olmalı - "1920 yılında..." gibi metinleri ayırmasın
    final numberMatches = numberRegex.allMatches(input).toList();
    if (numberMatches.length >= 3) {
      // İlk madde 1. ile başlamıyorsa bölme
      if (numberMatches.first.group(1) != '1') return [input];

      final result = <String>[];
      
      if (numberMatches.first.start > 0) {
        final before = input.substring(0, numberMatches.first.start).trim();
        if (before.isNotEmpty) result.add(before);
      }
      
      for (int i = 0; i < numberMatches.length; i++) {
        final start = numberMatches[i].start;
        final end = i < numberMatches.length - 1 ? numberMatches[i + 1].start : input.length;
        final part = input.substring(start, end).trim();
        if (part.isNotEmpty) result.add(part);
      }
      
      return result;
    }
    
    return [input];
  }

  /// Nokta+harf arasına boşluk ekler (madde numaraları hariç)
  /// Örn: "devletidir.II." → "devletidir. II."
  String _addSpaceAfterPeriod(String input) {
    // Nokta + büyük/küçük harf (ama madde numarası değilse)
    // Madde numaraları: I., II., III., IV., V., VI., 1., 2., 3. vb.
    final normalized = input.replaceAllMapped(
      RegExp(r'\.([A-Za-zÇĞİÖŞÜçğıöşü])'),
      (match) {
        final nextChar = match.group(1)!;
        // Eğer sonraki karakter madde başlangıcı olabilecek I, V, X veya rakam ise
        // ve arkasından nokta geliyorsa, bu bir madde numarasıdır - boşluk ekleme
        // Aksi halde boşluk ekle
        return '. $nextChar';
      },
    );

    return _insertMissingSpaces(normalized);
  }

  /// Küçük harfi doğrudan izleyen büyük harflerde (örn. "yaygınlaşmasıYukarıdaki")
  /// araya otomatik boşluk veya satır sonu ekler.
  /// Soru kökleri (Yukarıdaki, Aşağıdaki, Buna göre vb.) için satır sonu kullanır.
  String _insertMissingSpaces(String input) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1B1F);
    
    // Nokta sonrası boşluk ekle
    final processedText = _addSpaceAfterPeriod(text);
    
    // maxLines varsa kısaltılmış mod - düz metin göster
    if (maxLines != null) {
      return Text(
        processedText,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.ellipsis,
        style: GoogleFonts.merriweather(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.4,
          letterSpacing: -0.3,
        ),
      );
    }
    
    // Madde pattern'leri: I., II., III. veya 1., 2., 3.
    final bulletPattern = RegExp(r'^(I{1,3}|IV|VI{0,3}|IX|X|\d+)\.\s*');
    
    // Önce satırlara böl, sonra inline maddeleri ayır
    final lines = processedText.split('\n');
    final List<String> processedLines = [];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      // Inline maddeleri ayır (örn: "I. xxx II. yyy III. zzz")
      final bullets = _splitIntoBullets(trimmed);
      processedLines.addAll(bullets.map((b) => b.trim()));
    }
    
    // Ana soru, maddeler ve soru kökü ayrımı
    final List<Widget> widgets = [];
    String mainQuestion = '';
    final List<String> bulletItems = [];
    String questionRoot = '';
    
    int firstBulletIndex = -1;
    for (int i = 0; i < processedLines.length; i++) {
      final match = bulletPattern.firstMatch(processedLines[i]);
      if (match != null) {
        final bulletNum = match.group(1);
        // Sadece 1. veya I. ile başlıyorsa liste olarak kabul et
        if (bulletNum == '1' || bulletNum == 'I') {
          firstBulletIndex = i;
          break;
        }
      }
    }
    
    if (firstBulletIndex == -1) {
      // Hiç madde yok
      mainQuestion = processedLines.join('\n');
    } else {
      // Giriş kısmı (ilk maddeden öncekiler)
      if (firstBulletIndex > 0) {
        mainQuestion = processedLines.sublist(0, firstBulletIndex).join('\n').trim();
      }
      
      // Maddeler ve Soru Kökü analizi
      for (int i = firstBulletIndex; i < processedLines.length; i++) {
        final line = processedLines[i];
        if (line.trim().isEmpty) continue;
        
        if (bulletPattern.hasMatch(line)) {
          bulletItems.add(line);
        } else {
          // Madde değil. Bu satır bir maddenin devamı mı yoksa soru kökü mü?
          // Kontrol: Kendinden sonra gelen satırlarda hiç madde var mı?
          bool hasNextBullet = false;
          for (int j = i + 1; j < processedLines.length; j++) {
             if (bulletPattern.hasMatch(processedLines[j])) {
               hasNextBullet = true;
               break;
             }
          }
          
          if (hasNextBullet) {
            // Sonra madde var -> Demek ki bu satır mevcut maddenin devamı
            if (bulletItems.isNotEmpty) {
              bulletItems[bulletItems.length - 1] += ' $line'; // Boşlukla ekle
            }
          } else {
            // Sonra madde yok -> Demek ki bu satır (ve sonrakiler) soru kökü
            questionRoot += (questionRoot.isEmpty ? '' : '\n') + line;
          }
        }
      }
    }
    
    // Ana soru varsa ekle
    if (mainQuestion.isNotEmpty) {
      widgets.add(
        Text(
          mainQuestion,
          style: GoogleFonts.merriweather(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1.5,
            letterSpacing: -0.2,
          ),
        ),
      );
    }
    
    // Maddeler varsa göster - sade tasarım
    if (bulletItems.isNotEmpty && showBulletCard) {
      if (mainQuestion.isNotEmpty) {
        widgets.add(const SizedBox(height: 12));
      }
      
      for (int i = 0; i < bulletItems.length; i++) {
        final item = bulletItems[i];
        final isLastItem = i == bulletItems.length - 1;
        
        // Madde numarasını çıkar
        final match = bulletPattern.firstMatch(item);
        final bulletNumber = match?.group(1) ?? '';
        final bulletContent = item.replaceFirst(bulletPattern, '');
        
        // Madde item - sade tasarım
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: isLastItem ? 0 : 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Madde numarası - sade gri badge
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF374151) 
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      bulletNumber,
                      style: TextStyle(
                        fontSize: fontSize - 5,
                        fontWeight: FontWeight.w700,
                        color: isDark 
                            ? const Color(0xFF9CA3AF) 
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      bulletContent,
                      style: GoogleFonts.merriweather(
                        fontSize: fontSize - 2,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else if (bulletItems.isNotEmpty) {
      // Kart olmadan sadece metin
      for (final item in bulletItems) {
        widgets.add(
          Text(
            item,
            style: GoogleFonts.merriweather(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: textColor,
              height: 1.6,
            ),
          ),
        );
      }
    }
    
    // Soru kökü varsa en alta ekle (vurgulu)
    if (questionRoot.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        Text(
          questionRoot.trim(),
          style: GoogleFonts.merriweather(
            fontSize: fontSize,
            fontWeight: FontWeight.w700, // Soru kökü daha kalın
            color: textColor,
            height: 1.5,
          ),
        ),
      );
    }
    
    // Madde yoksa düz metin göster
    if (widgets.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.merriweather(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.5,
          letterSpacing: -0.2,
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
