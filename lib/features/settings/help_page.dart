import 'package:flutter/material.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final faqs = <_FaqItem>[
      const _FaqItem(
        question: 'Uygulamayı nasıl kullanırım?',
        answer:
            'Ana sayfadan dersler, konular ve modüller arasında gezinebilirsiniz. Quiz çözmek, konu anlatımı okumak veya flashcard çalışmak için ilgili modülü seçin.',
      ),
      const _FaqItem(
        question: 'İlerleme nasıl takip edilir?',
        answer:
            'Profil > İstatistikler bölümünden toplam çözülen soru sayınızı, başarı oranınızı ve ders bazlı performansınızı görebilirsiniz.',
      ),
      const _FaqItem(
        question: 'Seri (Streak) sistemi nedir?',
        answer:
            'Her gün en az bir quiz çözdüğünüzde seriniz devam eder. Günü kaçırırsanız seri sıfırlanır. Düzenli çalışma için harika bir motivasyon kaynağı!',
      ),
      const _FaqItem(
        question: 'Favorilere nasıl eklenir?',
        answer:
            'Quiz sırasında soru üzerindeki yıldız ikonuna tıklayarak o soruyu favorilere ekleyebilirsiniz. Favoriler sayfasından istediğiniz zaman tekrar çözebilirsiniz.',
      ),
      const _FaqItem(
        question: 'Yanlış cevaplarımı nasıl görebilirim?',
        answer:
            'Quiz tamamlandıktan sonra sonuç ekranında yanlış cevaplarınızı inceleyebilirsiniz. Ayrıca Profil > Yanlış Cevaplar bölümünden tüm yanlışlarınızı görebilirsiniz.',
      ),
      const _FaqItem(
        question: 'Bildirimler nasıl ayarlanır?',
        answer:
            'Ayarlar > Bildirimler bölümünden günlük hatırlatıcı ve seri uyarılarını açıp kapatabilirsiniz.',
      ),
      const _FaqItem(
        question: 'Verilerim güvende mi?',
        answer:
            'Evet! Tüm verileriniz güvenli sunucularda şifreli olarak saklanır. Gizlilik Politikası sayfasından detaylı bilgi alabilirsiniz.',
      ),
      const _FaqItem(
        question: 'Hesabımı nasıl silerim?',
        answer:
            'Ayarlar > Hesabı Sil seçeneğinden hesabınızı ve tüm verilerinizi kalıcı olarak silebilirsiniz. Bu işlem geri alınamaz.',
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Yardım Merkezi'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nasıl Yardımcı Olabiliriz?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sık sorulan soruları inceleyin',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // FAQ List
          ...faqs.map((faq) => _FaqTile(faq: faq, isDark: isDark)),

          const SizedBox(height: 24),

          // Contact Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sorunuz mu var?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bize ulaşın: destek@kpss2026.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });
}

class _FaqTile extends StatefulWidget {
  final _FaqItem faq;
  final bool isDark;

  const _FaqTile({
    required this.faq,
    required this.isDark,
  });

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Icon(
            _isExpanded ? Icons.help_rounded : Icons.help_outline_rounded,
            color: AppColors.primary,
          ),
          title: Text(
            widget.faq.question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: widget.isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          trailing: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: widget.isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          onExpansionChanged: (v) => setState(() => _isExpanded = v),
          children: [
            Text(
              widget.faq.answer,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
