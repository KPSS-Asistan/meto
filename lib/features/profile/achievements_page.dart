import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kpss_2026/core/services/streak_service.dart';
import 'package:kpss_2026/core/services/quiz_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  bool _isLoading = true;
  
  // İstatistikler
  int _totalSolved = 0;
  int _maxStreak = 0;
  int _totalCorrect = 0;
  int _totalStudyDays = 0;
  int _totalFlashcards = 0;
  int _totalExplanations = 0;
  int _totalQuizzes = 0;
  int _successRate = 0; // Yüzde olarak

  static const _primaryBlue = Color(0xFF6366F1);
  static const _successGreen = Color(0xFF10B981);

  final List<_Badge> _badges = [
    // ═══════════════════════════════════════════════════════════════════════════
    // 🎯 SORU ÇÖZME ROZETLERİ (12 adet)
    // ═══════════════════════════════════════════════════════════════════════════
    _Badge(id: 'first', title: 'İlk Adım', desc: 'İlk soruyu çöz', icon: Icons.play_arrow_rounded, color: Color(0xFF10B981), req: 1, type: 'solved'),
    _Badge(id: 's10', title: 'Başlangıç', desc: '10 soru çöz', icon: Icons.star_outline_rounded, color: Color(0xFF6366F1), req: 10, type: 'solved'),
    _Badge(id: 's25', title: 'Kararlı', desc: '25 soru çöz', icon: Icons.trending_up_rounded, color: Color(0xFF8B5CF6), req: 25, type: 'solved'),
    _Badge(id: 's50', title: 'Azimli', desc: '50 soru çöz', icon: Icons.star_half_rounded, color: Color(0xFF7C3AED), req: 50, type: 'solved'),
    _Badge(id: 's100', title: 'Çalışkan', desc: '100 soru çöz', icon: Icons.star_rounded, color: Color(0xFFF59E0B), req: 100, type: 'solved'),
    _Badge(id: 's250', title: 'Gayretli', desc: '250 soru çöz', icon: Icons.auto_awesome_rounded, color: Color(0xFFD946EF), req: 250, type: 'solved'),
    _Badge(id: 's500', title: 'Uzman', desc: '500 soru çöz', icon: Icons.workspace_premium_rounded, color: Color(0xFFEC4899), req: 500, type: 'solved'),
    _Badge(id: 's750', title: 'Profesyonel', desc: '750 soru çöz', icon: Icons.military_tech_rounded, color: Color(0xFFE11D48), req: 750, type: 'solved'),
    _Badge(id: 's1000', title: 'Usta', desc: '1000 soru çöz', icon: Icons.emoji_events_rounded, color: Color(0xFFDC2626), req: 1000, type: 'solved'),
    _Badge(id: 's2000', title: 'Büyük Usta', desc: '2000 soru çöz', icon: Icons.diamond_rounded, color: Color(0xFF0891B2), req: 2000, type: 'solved'),
    _Badge(id: 's5000', title: 'Efsane Çözücü', desc: '5000 soru çöz', icon: Icons.bolt_rounded, color: Color(0xFFCA8A04), req: 5000, type: 'solved'),
    _Badge(id: 's10000', title: 'Zirve Performans', desc: '10000 soru çöz', icon: Icons.all_inclusive_rounded, color: Color(0xFF7C2D12), req: 10000, type: 'solved'),
    
    // ═══════════════════════════════════════════════════════════════════════════
    // 🔥 STREAK ROZETLERİ (10 adet)
    // ═══════════════════════════════════════════════════════════════════════════
    _Badge(id: 'str3', title: 'Düzenli', desc: '3 gün üst üste çalış', icon: Icons.local_fire_department_rounded, color: Color(0xFFF97316), req: 3, type: 'streak'),
    _Badge(id: 'str5', title: 'Tutarlı', desc: '5 gün üst üste çalış', icon: Icons.local_fire_department_rounded, color: Color(0xFFEA580C), req: 5, type: 'streak'),
    _Badge(id: 'str7', title: 'Haftalık', desc: '7 gün üst üste çalış', icon: Icons.whatshot_rounded, color: Color(0xFFEF4444), req: 7, type: 'streak'),
    _Badge(id: 'str14', title: 'İki Haftalık', desc: '14 gün üst üste çalış', icon: Icons.whatshot_rounded, color: Color(0xFFDC2626), req: 14, type: 'streak'),
    _Badge(id: 'str21', title: 'Üç Haftalık', desc: '21 gün üst üste çalış', icon: Icons.local_fire_department_rounded, color: Color(0xFFB91C1C), req: 21, type: 'streak'),
    _Badge(id: 'str30', title: 'Aylık', desc: '30 gün üst üste çalış', icon: Icons.whatshot_rounded, color: Color(0xFF991B1B), req: 30, type: 'streak'),
    _Badge(id: 'str60', title: 'İki Aylık', desc: '60 gün üst üste çalış', icon: Icons.local_fire_department_rounded, color: Color(0xFF7F1D1D), req: 60, type: 'streak'),
    _Badge(id: 'str90', title: 'Üç Aylık', desc: '90 gün üst üste çalış', icon: Icons.whatshot_rounded, color: Color(0xFF450A0A), req: 90, type: 'streak'),
    _Badge(id: 'str180', title: 'Altı Aylık', desc: '180 gün üst üste çalış', icon: Icons.local_fire_department_rounded, color: Color(0xFF78350F), req: 180, type: 'streak'),
    _Badge(id: 'str365', title: 'Yıllık Efsane', desc: '365 gün üst üste çalış', icon: Icons.auto_awesome_rounded, color: Color(0xFF92400E), req: 365, type: 'streak'),
    
    // ═══════════════════════════════════════════════════════════════════════════
    // ✅ DOĞRU CEVAP ROZETLERİ (10 adet)
    // ═══════════════════════════════════════════════════════════════════════════
    _Badge(id: 'c10', title: 'Dikkatli', desc: '10 doğru cevap', icon: Icons.check_circle_outline_rounded, color: Color(0xFF22C55E), req: 10, type: 'correct'),
    _Badge(id: 'c25', title: 'Odaklı', desc: '25 doğru cevap', icon: Icons.check_circle_rounded, color: Color(0xFF16A34A), req: 25, type: 'correct'),
    _Badge(id: 'c50', title: 'Keskin', desc: '50 doğru cevap', icon: Icons.verified_outlined, color: Color(0xFF14B8A6), req: 50, type: 'correct'),
    _Badge(id: 'c100', title: 'Mükemmel', desc: '100 doğru cevap', icon: Icons.verified_rounded, color: Color(0xFF0EA5E9), req: 100, type: 'correct'),
    _Badge(id: 'c250', title: 'Hassas', desc: '250 doğru cevap', icon: Icons.gpp_good_rounded, color: Color(0xFF0284C7), req: 250, type: 'correct'),
    _Badge(id: 'c500', title: 'Hatasız', desc: '500 doğru cevap', icon: Icons.shield_rounded, color: Color(0xFF075985), req: 500, type: 'correct'),
    _Badge(id: 'c1000', title: 'Bilge', desc: '1000 doğru cevap', icon: Icons.psychology_rounded, color: Color(0xFF1E3A5F), req: 1000, type: 'correct'),
    _Badge(id: 'c2500', title: 'Dahi', desc: '2500 doğru cevap', icon: Icons.lightbulb_rounded, color: Color(0xFF4338CA), req: 2500, type: 'correct'),
    _Badge(id: 'c5000', title: 'Deha', desc: '5000 doğru cevap', icon: Icons.school_rounded, color: Color(0xFF6D28D9), req: 5000, type: 'correct'),
    _Badge(id: 'c10000', title: 'Ansiklopedi', desc: '10000 doğru cevap', icon: Icons.menu_book_rounded, color: Color(0xFF7E22CE), req: 10000, type: 'correct'),
    
    // ═══════════════════════════════════════════════════════════════════════════
    // 📅 TOPLAM ÇALIŞMA GÜNÜ ROZETLERİ (8 adet)
    // ═══════════════════════════════════════════════════════════════════════════
    _Badge(id: 'd1', title: 'Hoş Geldin', desc: 'İlk çalışma günün', icon: Icons.waving_hand_rounded, color: Color(0xFF06B6D4), req: 1, type: 'studyDays'),
    _Badge(id: 'd7', title: 'Bir Hafta', desc: '7 gün çalış', icon: Icons.calendar_today_rounded, color: Color(0xFF0891B2), req: 7, type: 'studyDays'),
    _Badge(id: 'd14', title: 'İki Hafta', desc: '14 gün çalış', icon: Icons.calendar_view_week_rounded, color: Color(0xFF0E7490), req: 14, type: 'studyDays'),
    _Badge(id: 'd30', title: 'Bir Ay', desc: '30 gün çalış', icon: Icons.calendar_month_rounded, color: Color(0xFF155E75), req: 30, type: 'studyDays'),
    _Badge(id: 'd60', title: 'İki Ay', desc: '60 gün çalış', icon: Icons.date_range_rounded, color: Color(0xFF164E63), req: 60, type: 'studyDays'),
    _Badge(id: 'd90', title: 'Üç Ay', desc: '90 gün çalış', icon: Icons.event_available_rounded, color: Color(0xFF134E4A), req: 90, type: 'studyDays'),
    _Badge(id: 'd180', title: 'Altı Ay', desc: '180 gün çalış', icon: Icons.event_note_rounded, color: Color(0xFF115E59), req: 180, type: 'studyDays'),
    _Badge(id: 'd365', title: 'Tam Bir Yıl', desc: '365 gün çalış', icon: Icons.celebration_rounded, color: Color(0xFF0F766E), req: 365, type: 'studyDays'),
    
    // ═══════════════════════════════════════════════════════════════════════════
    // 🃏 FLASHCARD ROZETLERİ (8 adet)
    // ═══════════════════════════════════════════════════════════════════════════
    _Badge(id: 'f10', title: 'Kartçı', desc: '10 flashcard çalış', icon: Icons.style_rounded, color: Color(0xFFA855F7), req: 10, type: 'flashcard'),
    _Badge(id: 'f50', title: 'Kart Ustası', desc: '50 flashcard çalış', icon: Icons.layers_rounded, color: Color(0xFF9333EA), req: 50, type: 'flashcard'),
    _Badge(id: 'f100', title: 'Hafıza Ustası', desc: '100 flashcard çalış', icon: Icons.view_carousel_rounded, color: Color(0xFF7E22CE), req: 100, type: 'flashcard'),
    _Badge(id: 'f250', title: 'Kart Koleksiyoncusu', desc: '250 flashcard çalış', icon: Icons.collections_bookmark_rounded, color: Color(0xFF6B21A8), req: 250, type: 'flashcard'),
    _Badge(id: 'f500', title: 'Flashcard Ninja', desc: '500 flashcard çalış', icon: Icons.auto_stories_rounded, color: Color(0xFF581C87), req: 500, type: 'flashcard'),
    _Badge(id: 'f1000', title: 'Hafıza Şampiyonu', desc: '1000 flashcard çalış', icon: Icons.psychology_alt_rounded, color: Color(0xFF4C1D95), req: 1000, type: 'flashcard'),
    _Badge(id: 'f2500', title: 'Kart Efsanesi', desc: '2500 flashcard çalış', icon: Icons.hub_rounded, color: Color(0xFF3B0764), req: 2500, type: 'flashcard'),
    _Badge(id: 'f5000', title: 'Hafıza Ustabaşı', desc: '5000 flashcard çalış', icon: Icons.all_inclusive_rounded, color: Color(0xFF2E1065), req: 5000, type: 'flashcard'),
    
    // ═══════════════════════════════════════════════════════════════════════════
    // 📖 KONU ANLATIMI ROZETLERİ (8 adet)
    // ═══════════════════════════════════════════════════════════════════════════
    _Badge(id: 'e5', title: 'Öğrenci', desc: '5 konu anlatımı oku', icon: Icons.menu_book_rounded, color: Color(0xFF3B82F6), req: 5, type: 'explanation'),
    _Badge(id: 'e15', title: 'Meraklı', desc: '15 konu anlatımı oku', icon: Icons.auto_stories_rounded, color: Color(0xFF2563EB), req: 15, type: 'explanation'),
    _Badge(id: 'e30', title: 'Araştırmacı', desc: '30 konu anlatımı oku', icon: Icons.library_books_rounded, color: Color(0xFF1D4ED8), req: 30, type: 'explanation'),
    _Badge(id: 'e50', title: 'Akademisyen', desc: '50 konu anlatımı oku', icon: Icons.school_rounded, color: Color(0xFF1E40AF), req: 50, type: 'explanation'),
    _Badge(id: 'e100', title: 'Profesör', desc: '100 konu anlatımı oku', icon: Icons.history_edu_rounded, color: Color(0xFF1E3A8A), req: 100, type: 'explanation'),
    _Badge(id: 'e200', title: 'Bilim İnsanı', desc: '200 konu anlatımı oku', icon: Icons.science_rounded, color: Color(0xFF172554), req: 200, type: 'explanation'),
    _Badge(id: 'e350', title: 'Ansiklopedist', desc: '350 konu anlatımı oku', icon: Icons.import_contacts_rounded, color: Color(0xFF0F172A), req: 350, type: 'explanation'),
    _Badge(id: 'e500', title: 'Bilge Kral', desc: '500 konu anlatımı oku', icon: Icons.castle_rounded, color: Color(0xFF020617), req: 500, type: 'explanation'),
    
    // ═══════════════════════════════════════════════════════════════════════════
    // 📝 TEST/QUIZ ROZETLERİ (8 adet)
    // ═══════════════════════════════════════════════════════════════════════════
    _Badge(id: 'q1', title: 'İlk Deneme', desc: 'İlk testini tamamla', icon: Icons.quiz_rounded, color: Color(0xFFF472B6), req: 1, type: 'quiz'),
    _Badge(id: 'q5', title: 'Test Sever', desc: '5 test tamamla', icon: Icons.assignment_rounded, color: Color(0xFFEC4899), req: 5, type: 'quiz'),
    _Badge(id: 'q10', title: 'Deneme Avcısı', desc: '10 test tamamla', icon: Icons.fact_check_rounded, color: Color(0xFFDB2777), req: 10, type: 'quiz'),
    _Badge(id: 'q25', title: 'Test Makinesi', desc: '25 test tamamla', icon: Icons.grading_rounded, color: Color(0xFFC026D3), req: 25, type: 'quiz'),
    _Badge(id: 'q50', title: 'Sınav Ustası', desc: '50 test tamamla', icon: Icons.task_alt_rounded, color: Color(0xFFA21CAF), req: 50, type: 'quiz'),
    _Badge(id: 'q100', title: 'Test Efsanesi', desc: '100 test tamamla', icon: Icons.workspace_premium_rounded, color: Color(0xFF86198F), req: 100, type: 'quiz'),
    _Badge(id: 'q200', title: 'Deneme Uzmanı', desc: '200 test tamamla', icon: Icons.military_tech_rounded, color: Color(0xFF701A75), req: 200, type: 'quiz'),
    _Badge(id: 'q500', title: 'Test Şampiyonu', desc: '500 test tamamla', icon: Icons.emoji_events_rounded, color: Color(0xFF4A044E), req: 500, type: 'quiz'),
    
    // ═══════════════════════════════════════════════════════════════════════════
    // 🎯 BAŞARI ORANI ROZETLERİ (6 adet)
    // ═══════════════════════════════════════════════════════════════════════════
    _Badge(id: 'r50', title: 'Yarı Yolda', desc: '%50 başarı oranı', icon: Icons.speed_rounded, color: Color(0xFFFBBF24), req: 50, type: 'successRate'),
    _Badge(id: 'r60', title: 'Gelişen', desc: '%60 başarı oranı', icon: Icons.trending_up_rounded, color: Color(0xFFF59E0B), req: 60, type: 'successRate'),
    _Badge(id: 'r70', title: 'İyi Gidiyor', desc: '%70 başarı oranı', icon: Icons.thumb_up_rounded, color: Color(0xFFD97706), req: 70, type: 'successRate'),
    _Badge(id: 'r80', title: 'Başarılı', desc: '%80 başarı oranı', icon: Icons.star_rounded, color: Color(0xFFB45309), req: 80, type: 'successRate'),
    _Badge(id: 'r90', title: 'Mükemmeliyetçi', desc: '%90 başarı oranı', icon: Icons.diamond_rounded, color: Color(0xFF92400E), req: 90, type: 'successRate'),
    _Badge(id: 'r95', title: 'Kusursuz', desc: '%95 başarı oranı', icon: Icons.auto_awesome_rounded, color: Color(0xFF78350F), req: 95, type: 'successRate'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Mevcut servislerden
      final solved = await QuizStatsService.getTotalSolved();
      final streak = await StreakService.getLongestStreak();
      final correct = await QuizStatsService.getTotalCorrect();
      final studyDays = await StreakService.getTotalStudiedDays();
      final rate = await QuizStatsService.getSuccessRate();
      
      // SharedPreferences'tan toplam değerler
      final flashcards = prefs.getInt('total_flashcards_studied') ?? 0;
      final explanations = prefs.getInt('total_explanations_read') ?? 0;
      final quizzes = prefs.getInt('total_quizzes_completed') ?? 0;
      
      if (mounted) {
        setState(() {
          _totalSolved = solved;
          _maxStreak = streak;
          _totalCorrect = correct;
          _totalStudyDays = studyDays;
          _totalFlashcards = flashcards;
          _totalExplanations = explanations;
          _totalQuizzes = quizzes;
          _successRate = rate.round();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isUnlocked(_Badge b) {
    switch (b.type) {
      case 'solved': return _totalSolved >= b.req;
      case 'streak': return _maxStreak >= b.req;
      case 'correct': return _totalCorrect >= b.req;
      case 'studyDays': return _totalStudyDays >= b.req;
      case 'flashcard': return _totalFlashcards >= b.req;
      case 'explanation': return _totalExplanations >= b.req;
      case 'quiz': return _totalQuizzes >= b.req;
      case 'successRate': return _successRate >= b.req && _totalSolved >= 50; // En az 50 soru çözmüş olmalı
      default: return false;
    }
  }

  int _getProgress(_Badge b) {
    switch (b.type) {
      case 'solved': return _totalSolved;
      case 'streak': return _maxStreak;
      case 'correct': return _totalCorrect;
      case 'studyDays': return _totalStudyDays;
      case 'flashcard': return _totalFlashcards;
      case 'explanation': return _totalExplanations;
      case 'quiz': return _totalQuizzes;
      case 'successRate': return _successRate;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final unlocked = _badges.where((b) => _isUnlocked(b)).length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Başarılar', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSummary(unlocked, textColor, subtextColor),
                  const SizedBox(height: 20),
                  _buildBadgeList(cardColor, textColor, subtextColor),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSummary(int unlocked, Color textColor, Color subtextColor) {
    final percent = _badges.isNotEmpty ? (unlocked / _badges.length) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, _primaryBlue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Sol: İkon ve metin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                    const SizedBox(height: 16),
                    const Text('Kazanılan Rozetler', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$unlocked',
                            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: ' / ${_badges.length}',
                            style: const TextStyle(color: Colors.white60, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Sağ: Progress Ring - DÜZGÜN
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '%${(percent * 100).round()}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildBadgeList(Color cardColor, Color textColor, Color subtextColor) {
    // Kazanılanları üste, kilitlileri alta sırala
    final sortedBadges = List<_Badge>.from(_badges)
      ..sort((a, b) {
        final aUnlocked = _isUnlocked(a);
        final bUnlocked = _isUnlocked(b);
        if (aUnlocked && !bUnlocked) return -1;
        if (!aUnlocked && bUnlocked) return 1;
        // Aynı durumda olanları ilerleme yüzdesine göre sırala
        final aPct = _getProgress(a) / a.req;
        final bPct = _getProgress(b) / b.req;
        return bPct.compareTo(aPct);
      });

    final unlockedCount = sortedBadges.where((b) => _isUnlocked(b)).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Tüm Rozetler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unlockedCount Kazanıldı',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _successGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedBadges.asMap().entries.map((e) {
            final i = e.key;
            final b = e.value;
            final unlocked = _isUnlocked(b);
            final progress = _getProgress(b);
            final pct = (progress / b.req).clamp(0.0, 1.0);

            return Container(
              margin: EdgeInsets.only(bottom: i < sortedBadges.length - 1 ? 16 : 0),
              child: Row(
                children: [
                  // Badge Icon with glow effect for unlocked
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: unlocked ? b.color.withValues(alpha: 0.15) : subtextColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(b.icon, color: unlocked ? b.color : subtextColor.withValues(alpha: 0.4), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: unlocked ? textColor : subtextColor)),
                        const SizedBox(height: 2),
                        Text(b.desc, style: TextStyle(fontSize: 13, color: subtextColor)),
                        if (!unlocked) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 4,
                                    backgroundColor: subtextColor.withValues(alpha: 0.15),
                                    valueColor: AlwaysStoppedAnimation(b.color.withValues(alpha: 0.6)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$progress/${b.req}', style: TextStyle(fontSize: 11, color: subtextColor)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (unlocked)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _successGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, color: _successGreen, size: 18),
                    )
                  else
                    Icon(Icons.lock_outline_rounded, color: subtextColor.withValues(alpha: 0.4), size: 22),
                ],
              ),
            ).animate().fadeIn(delay: (30 * i).ms);
          }),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.03, end: 0);
  }
}

class _Badge {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final int req;
  final String type;
  const _Badge({required this.id, required this.title, required this.desc, required this.icon, required this.color, required this.req, required this.type});
}
