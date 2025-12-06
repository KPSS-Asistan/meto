import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Şifreler Sayfası - KPSS Ezberleme Teknikleri
/// Akrostiş, kodlama ve hafıza teknikleri
class MnemonicsPage extends StatefulWidget {
  final String lessonId;
  final String topicId;
  final String topicName;

  const MnemonicsPage({
    super.key,
    required this.lessonId,
    required this.topicId,
    required this.topicName,
  });

  @override
  State<MnemonicsPage> createState() => _MnemonicsPageState();
}

class _MnemonicsPageState extends State<MnemonicsPage> {
  final Set<int> _revealedIndices = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mnemonics = _getMnemonicsForTopic(widget.lessonId, widget.topicId);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),
            
            // İçerik
            Expanded(
              child: mnemonics.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildMnemonicsList(mnemonics, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 20,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Şifreler & Kodlamalar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.topicName,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Tümünü göster/gizle
          TextButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                final mnemonics = _getMnemonicsForTopic(widget.lessonId, widget.topicId);
                if (_revealedIndices.length == mnemonics.length) {
                  _revealedIndices.clear();
                } else {
                  _revealedIndices.addAll(List.generate(mnemonics.length, (i) => i));
                }
              });
            },
            icon: Icon(
              _revealedIndices.isEmpty ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 18,
            ),
            label: Text(_revealedIndices.isEmpty ? 'Göster' : 'Gizle'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lightbulb_outline_rounded, size: 36, color: AppColors.warning),
            ),
            const SizedBox(height: 20),
            Text(
              'Henüz şifre eklenmemiş',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu konu için ezberleme teknikleri yakında eklenecek.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMnemonicsList(List<MnemonicItem> mnemonics, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: mnemonics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = mnemonics[index];
        final isRevealed = _revealedIndices.contains(index);

        return _MnemonicCard(
          item: item,
          index: index,
          isRevealed: isRevealed,
          isDark: isDark,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isRevealed) {
                _revealedIndices.remove(index);
              } else {
                _revealedIndices.add(index);
              }
            });
          },
        );
      },
    );
  }

  /// Konu bazlı şifreleri getir
  List<MnemonicItem> _getMnemonicsForTopic(String lessonId, String topicId) {
    // TARİH dersi şifreleri
    if (lessonId == 'BRhOEZEWRJSjcRcTWVUf') {
      return _tarihMnemonics;
    }
    // COĞRAFYA dersi şifreleri
    if (lessonId == 'JlCZGN9wlbLVPpGqTgHM') {
      return _cografyaMnemonics;
    }
    // VATANDAŞLIK dersi şifreleri
    if (lessonId == '2ztkqV35cWjGRkhYRutg') {
      return _vatandaslikMnemonics;
    }
    // TÜRKÇE dersi şifreleri
    if (lessonId == 'gvdNPWLhpLqXbXZVJQbQ') {
      return _turkceMnemonics;
    }
    return [];
  }
}

/// Şifre kartı widget'ı
class _MnemonicCard extends StatelessWidget {
  final MnemonicItem item;
  final int index;
  final bool isRevealed;
  final bool isDark;
  final VoidCallback onTap;

  const _MnemonicCard({
    required this.item,
    required this.index,
    required this.isRevealed,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRevealed 
                  ? AppColors.warning.withValues(alpha: 0.5)
                  : (isDark ? AppColors.darkBorder : AppColors.border),
              width: isRevealed ? 2 : 1,
            ),
            boxShadow: isRevealed ? [
              BoxShadow(
                color: AppColors.warning.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık satırı
              Row(
                children: [
                  // Numara
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isRevealed 
                          ? AppColors.warning 
                          : (isDark ? AppColors.darkBackground : AppColors.background),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isRevealed 
                              ? Colors.white 
                              : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Konu başlığı
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Göster/gizle ikonu
                  Icon(
                    isRevealed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  ),
                ],
              ),
              
              // Şifre (açıksa)
              if (isRevealed) ...[
                const SizedBox(height: 16),
                // Şifre kutusu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Şifre metni
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.key_rounded,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.mnemonic,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning.withValues(alpha: 0.9),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Açıklama
                if (item.explanation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    item.explanation,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                
                // Öğeler listesi
                if (item.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...item.items.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Şifre veri modeli
class MnemonicItem {
  final String title;
  final String mnemonic;
  final String explanation;
  final List<String> items;

  const MnemonicItem({
    required this.title,
    required this.mnemonic,
    this.explanation = '',
    this.items = const [],
  });
}

// ============================================
// TARİH ŞİFRELERİ
// ============================================
const _tarihMnemonics = <MnemonicItem>[
  MnemonicItem(
    title: 'İlk Türk Devletleri',
    mnemonic: 'HUGA BİTTİ',
    explanation: 'Orta Asya\'da kurulan ilk Türk devletlerinin sırasını hatırlamak için:',
    items: [
      'H - Hun İmparatorluğu',
      'U - Uygur Devleti',
      'G - Göktürk Devleti',
      'A - Avar Devleti',
      'B - Bulgar Devleti',
      'İ - İskit (Saka) Devleti',
      'T - Türgiş Devleti',
      'T - Tabgaç Devleti',
      'İ - İdil Bulgarları',
    ],
  ),
  MnemonicItem(
    title: 'Osmanlı Kuruluş Dönemi Padişahları',
    mnemonic: 'OOM BİM',
    explanation: 'Kuruluş dönemi padişahlarını sırasıyla hatırlamak için:',
    items: [
      'O - Osman Bey',
      'O - Orhan Bey',
      'M - I. Murad',
      'B - I. Bayezid (Yıldırım)',
      'İ - Fetret Devri (İnterregnum)',
      'M - I. Mehmed (Çelebi)',
    ],
  ),
  MnemonicItem(
    title: 'Osmanlı Yükselme Dönemi Padişahları',
    mnemonic: 'MU FA SE SÜ',
    explanation: 'Yükselme dönemi padişahlarını hatırlamak için:',
    items: [
      'MU - II. Murad',
      'FA - Fatih Sultan Mehmed',
      'SE - II. Bayezid (Sofu)',
      'SÜ - I. Selim (Yavuz) & Süleyman (Kanuni)',
    ],
  ),
  MnemonicItem(
    title: 'Kurtuluş Savaşı Cepheleri',
    mnemonic: 'BATI DOĞU GÜNEY',
    explanation: 'Kurtuluş Savaşı\'nda açılan cepheler:',
    items: [
      'BATI - Yunan işgaline karşı (İnönü, Sakarya, Büyük Taarruz)',
      'DOĞU - Ermeni işgaline karşı (Gümrü Antlaşması)',
      'GÜNEY - Fransız işgaline karşı (Antep, Maraş, Urfa)',
    ],
  ),
  MnemonicItem(
    title: 'Atatürk İlkeleri',
    mnemonic: 'CİHAN LİDERİ',
    explanation: '6 temel Atatürk ilkesini hatırlamak için:',
    items: [
      'C - Cumhuriyetçilik',
      'İ - İnkılapçılık',
      'H - Halkçılık',
      'A - Atatürk Milliyetçiliği',
      'N - (boş)',
      'L - Laiklik',
      'İ - İnkılapçılık',
      'D - Devletçilik',
      'E - (boş)',
      'R - (boş)',
      'İ - (boş)',
    ],
  ),
  MnemonicItem(
    title: 'Mondros Ateşkes Antlaşması Maddeleri',
    mnemonic: 'BOĞAZ TÜNEL SİLAH',
    explanation: 'Mondros\'un önemli maddelerini hatırlamak için:',
    items: [
      'BOĞAZ - Boğazlar İtilaf Devletlerine açılacak',
      'TÜNEL - Tünel, demiryolu ve haberleşme İtilaf kontrolüne geçecek',
      'SİLAH - Silahlar teslim edilecek, ordu terhis edilecek',
    ],
  ),
];

// ============================================
// COĞRAFYA ŞİFRELERİ
// ============================================
const _cografyaMnemonics = <MnemonicItem>[
  MnemonicItem(
    title: 'Türkiye\'nin Komşuları',
    mnemonic: 'GİS BAY GÜ',
    explanation: 'Türkiye\'nin sınır komşularını hatırlamak için:',
    items: [
      'G - Gürcistan',
      'İ - İran',
      'S - Suriye',
      'B - Bulgaristan',
      'A - Azerbaycan (Nahçıvan)',
      'Y - Yunanistan',
      'GÜ - Gürcistan',
    ],
  ),
  MnemonicItem(
    title: 'Akdeniz İklimi Bitki Örtüsü',
    mnemonic: 'MAKİ ZEYTİN',
    explanation: 'Akdeniz ikliminin karakteristik bitkileri:',
    items: [
      'Maki (kızılçam, sandal, defne, mersin)',
      'Zeytin ağacı',
      'Turunçgiller (portakal, limon)',
      'Bağ (üzüm)',
    ],
  ),
  MnemonicItem(
    title: 'Karadeniz Bölgesi Ürünleri',
    mnemonic: 'ÇAY FINDIK MISIR',
    explanation: 'Karadeniz\'in önemli tarım ürünleri:',
    items: [
      'Çay (Rize)',
      'Fındık (Ordu, Giresun)',
      'Mısır',
      'Tütün (Samsun)',
    ],
  ),
  MnemonicItem(
    title: 'Türkiye\'nin Gölleri (Büyükten Küçüğe)',
    mnemonic: 'VAN TUZ BEY EĞİR',
    explanation: 'Türkiye\'nin en büyük göllerini sırasıyla hatırlamak için:',
    items: [
      'VAN - Van Gölü (tektonik, tuzlu)',
      'TUZ - Tuz Gölü (tektonik, tuzlu)',
      'BEY - Beyşehir Gölü (tektonik, tatlı)',
      'EĞİR - Eğirdir Gölü (tektonik, tatlı)',
    ],
  ),
  MnemonicItem(
    title: 'Ege Bölgesi Ovaları',
    mnemonic: 'GEDİZ KÜÇÜK BÜYÜK',
    explanation: 'Ege\'nin önemli ovalarını hatırlamak için:',
    items: [
      'Gediz Ovası (Manisa)',
      'Küçük Menderes Ovası (İzmir)',
      'Büyük Menderes Ovası (Aydın)',
      'Bakırçay Ovası',
    ],
  ),
];

// ============================================
// VATANDAŞLIK ŞİFRELERİ
// ============================================
const _vatandaslikMnemonics = <MnemonicItem>[
  MnemonicItem(
    title: 'Anayasa Mahkemesi Görevleri',
    mnemonic: 'İPTAL YÜCE',
    explanation: 'Anayasa Mahkemesi\'nin temel görevleri:',
    items: [
      'İPTAL - Kanunların anayasaya uygunluğunu denetler',
      'YÜCE - Yüce Divan sıfatıyla yargılama yapar',
      'Bireysel başvuruları inceler',
      'Siyasi parti kapatma davalarına bakar',
    ],
  ),
  MnemonicItem(
    title: 'TBMM Görevleri',
    mnemonic: 'KANUN BÜTÇE SAVAŞ',
    explanation: 'TBMM\'nin temel görev ve yetkileri:',
    items: [
      'KANUN - Kanun yapmak, değiştirmek, kaldırmak',
      'BÜTÇE - Bütçe ve kesin hesap kanunlarını kabul etmek',
      'SAVAŞ - Savaş ilanına karar vermek',
      'Af ilan etmek',
      'Uluslararası antlaşmaları onaylamak',
    ],
  ),
  MnemonicItem(
    title: 'Cumhurbaşkanının Görevleri',
    mnemonic: 'YÜRÜTME TEMSİL ATAMA',
    explanation: 'Cumhurbaşkanının anayasal görevleri:',
    items: [
      'YÜRÜTME - Yürütme yetkisini kullanır',
      'TEMSİL - Devleti temsil eder',
      'ATAMA - Üst düzey yöneticileri atar',
      'Kanunları yayımlar veya veto eder',
      'Kararname çıkarır',
    ],
  ),
  MnemonicItem(
    title: 'Temel Hak ve Özgürlükler',
    mnemonic: 'YAŞAM ÖZGÜRLÜK EŞİTLİK',
    explanation: 'Anayasadaki temel haklar:',
    items: [
      'Yaşam hakkı',
      'Kişi özgürlüğü ve güvenliği',
      'Özel hayatın gizliliği',
      'Din ve vicdan özgürlüğü',
      'Düşünce ve ifade özgürlüğü',
      'Eşitlik ilkesi',
    ],
  ),
  MnemonicItem(
    title: 'Yargı Organları',
    mnemonic: 'ANAYASA YARGITAY DANIŞTAY',
    explanation: 'Türkiye\'deki yüksek yargı organları:',
    items: [
      'Anayasa Mahkemesi - Anayasaya uygunluk denetimi',
      'Yargıtay - Adli yargının son mercii',
      'Danıştay - İdari yargının son mercii',
      'Sayıştay - Mali denetim',
      'Uyuşmazlık Mahkemesi - Görev uyuşmazlıkları',
    ],
  ),
];

// ============================================
// TÜRKÇE ŞİFRELERİ
// ============================================
const _turkceMnemonics = <MnemonicItem>[
  MnemonicItem(
    title: 'Büyük Ünlü Uyumu',
    mnemonic: 'KALIN-İNCE',
    explanation: 'Türkçe\'de büyük ünlü uyumu kuralı:',
    items: [
      'Kalın ünlüler: a, ı, o, u',
      'İnce ünlüler: e, i, ö, ü',
      'Bir sözcükte ya hep kalın ya hep ince ünlü bulunur',
      'Örnek: kitap (kalın), gözlük (ince)',
    ],
  ),
  MnemonicItem(
    title: 'Küçük Ünlü Uyumu',
    mnemonic: 'DÜZ-YUVARLAK',
    explanation: 'Türkçe\'de küçük ünlü uyumu kuralı:',
    items: [
      'Düz ünlüler: a, e, ı, i',
      'Yuvarlak ünlüler: o, ö, u, ü',
      'Yuvarlak ünlüden sonra düz-geniş veya dar-yuvarlak gelir',
    ],
  ),
  MnemonicItem(
    title: 'Ünsüz Yumuşaması',
    mnemonic: 'FıSTıKÇı ŞaHaP',
    explanation: 'Sert ünsüzleri hatırlamak için (p, ç, t, k):',
    items: [
      'F-S-T-K-Ç-Ş-H-P sert ünsüzlerdir',
      'Sözcük sonundaki p, ç, t, k ünlü ile başlayan ek alınca yumuşar',
      'p → b, ç → c, t → d, k → ğ',
      'Örnek: kitap → kitabı, ağaç → ağacı',
    ],
  ),
  MnemonicItem(
    title: 'Ünsüz Benzeşmesi',
    mnemonic: 'FıSTıKÇı ŞaHaP',
    explanation: 'Sert ünsüzlerden sonra gelen yumuşak ünsüzler sertleşir:',
    items: [
      'c → ç, d → t, g → k',
      'Örnek: Türkçe (Türk+ce → Türkçe)',
      'Örnek: seçti (seç+di → seçti)',
    ],
  ),
  MnemonicItem(
    title: 'Sözcük Türleri',
    mnemonic: 'İSİM SIFAT ZAMİR ZARF',
    explanation: 'Türkçe\'deki temel sözcük türleri:',
    items: [
      'İsim (Ad) - Varlıkları karşılar',
      'Sıfat (Önad) - İsimleri niteler',
      'Zamir (Adıl) - İsimlerin yerine geçer',
      'Zarf (Belirteç) - Fiilleri niteler',
      'Fiil (Eylem) - Hareket bildirir',
      'Edat, Bağlaç, Ünlem',
    ],
  ),
  MnemonicItem(
    title: 'Cümlenin Öğeleri',
    mnemonic: 'ÖZNE YÜKLEM NESNE',
    explanation: 'Cümlenin temel öğeleri:',
    items: [
      'Özne - Yüklemin bildirdiği işi yapan',
      'Yüklem - Cümlenin temel öğesi',
      'Nesne - Yüklemden etkilenen (belirtili/belirtisiz)',
      'Dolaylı Tümleç - Yüklemi yer, yön, zaman yönünden tamamlar',
      'Zarf Tümleci - Yüklemi durum, zaman, miktar yönünden tamamlar',
    ],
  ),
];
