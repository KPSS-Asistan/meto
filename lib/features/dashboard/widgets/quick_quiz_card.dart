import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kpss_2026/core/data/questions_data.dart';

/// Hızlı Quiz Kartı - Dashboard'da 5 soruluk hızlı quiz başlatma
/// Rastgele konulardan 5 soru ile hızlı pratik
class QuickQuizCard extends StatelessWidget {
  const QuickQuizCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _startQuickQuiz(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF7C3AED), const Color(0xFF5B21B6)]
                : [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sol: İkon ve içerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık
                  const Text(
                    'Hızlı Quiz',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  
                  const SizedBox(height: 2),
                  
                  Text(
                    'Karma sorularla test et',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            
            // Sağ: Play butonu
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.play,
                color: Colors.white,
                size: 24,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(
               begin: const Offset(1, 1),
               end: const Offset(1.05, 1.05),
               duration: 1000.ms,
             ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  void _startQuickQuiz(BuildContext context) {
    // Rastgele bir topic seç (mevcut topicler'den)
    final availableTopics = _getAvailableTopics();
    
    if (availableTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Henüz soru yüklenmemiş'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Rastgele bir topic seç
    final random = Random();
    final selectedTopic = availableTopics[random.nextInt(availableTopics.length)];
    
    // Quiz sayfasına yönlendir - 5 soruluk hızlı quiz
    context.push(
      '/lessons/quick/topics/$selectedTopic/quiz',
      extra: {
        'topicName': 'Hızlı Quiz',
        'lessonName': 'Karma Sorular',
        'quickQuiz': true,
        'questionCount': 5,
      },
    );
  }

  List<String> _getAvailableTopics() {
    // 1. Önce dinamik olarak yüklenmiş (cache'deki) konulara bak
    final cachedTopicIds = QuestionsData.getAllTopicIds();
    
    if (cachedTopicIds.isNotEmpty) {
      return cachedTopicIds;
    }
    
    // 2. Cache henüz boşsa (örn: ilk açılış), bilinen temel konuları fallback olarak kullan
    // Bu konuların Firebase'de soruları olma ihtimali yüksek
    final knownTopics = [
      'anlatim_bozukluklari',
      'cumlede_anlam',
      'paragrafta_anlam',
      'ses_bilgisi',
      'anayasa_hukuku',
      'devlet_organlari', 
      'hukuka_giris',
      'idare_hukuku',
      'konum_ve_cografi_ozellikler',
      'turkiyenin_iklimi',
      'temel_kavramlar',
      'tarih_osmanli_kurulus',
    ];
    
    return knownTopics;
  }
}
