import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Yardım Merkezi Sayfası - Modern ve Minimalist
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'Quiz nasıl çözülür?',
      answer: 'Ana sayfadan veya Dersler sayfasından bir konu seçin. Quiz otomatik olarak başlayacak ve 20 rastgele soru sorulacaktır.',
    ),
    _FaqItem(
      question: 'Seri (Streak) sistemi nasıl çalışır?',
      answer: 'Her gün en az bir quiz çözdüğünüzde seri devam eder. Günü kaçırırsanız seri sıfırlanır. Düzenli çalışma için harika bir motivasyon kaynağı!',
    ),
    _FaqItem(
      question: 'İlerleme nasıl takip edilir?',
      answer: 'Profil > İstatistikler bölümünden toplam çözülen soru, başarı yüzdesi ve ders bazlı performansınızı görebilirsiniz.',
    ),
    _FaqItem(
      question: 'Yanlış cevapları nasıl görebilirim?',
      answer: 'Quiz tamamlandıktan sonra sonuç ekranında yanlış cevaplarınızı inceleyebilirsiniz. Her sorunun doğru cevabı ve açıklaması gösterilir.',
    ),
    _FaqItem(
      question: 'Favorilere nasıl eklenir?',
      answer: 'Quiz sırasında soru üzerindeki kalp ikonuna tıklayarak o soruyu favorilere ekleyebilirsiniz. Favoriler sayfasından istediğiniz zaman tekrar çözebilirsiniz.',
    ),
    _FaqItem(
      question: 'Rozetler ve başarılar nasıl kazanılır?',
      answer: 'Belirli hedeflere ulaştığınızda rozetler otomatik olarak açılır. Örneğin: 100 soru çözmek, 7 gün üst üste çalışmak gibi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Yardım Merkezi', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF10B981), const Color(0xFF10B981).withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text('Nasıl Yardımcı Olabiliriz?',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('Sık sorulan soruları inceleyin',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 24),

          // FAQ
          Text('Sık Sorulan Sorular', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 12),

          ...(_faqs.asMap().entries.map((e) {
            final i = e.key;
            final faq = e.value;
            return _FaqTile(
              faq: faq,
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ).animate().fadeIn(delay: (100 + i * 50).ms);
          })),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  _FaqItem({required this.question, required this.answer});
}

class _FaqTile extends StatefulWidget {
  final _FaqItem faq;
  final Color cardColor;
  final Color textColor;
  final Color subtextColor;

  const _FaqTile({
    required this.faq,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
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
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Icon(
            _isExpanded ? Icons.help_rounded : Icons.help_outline_rounded,
            color: const Color(0xFF6366F1),
          ),
          title: Text(
            widget.faq.question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: widget.textColor,
            ),
          ),
          trailing: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: widget.subtextColor),
          ),
          onExpansionChanged: (v) => setState(() => _isExpanded = v),
          children: [
            Text(
              widget.faq.answer,
              style: TextStyle(fontSize: 14, color: widget.subtextColor, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
