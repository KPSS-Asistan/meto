import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kpss_2026/core/services/premium_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Dashboard altı için ÖZEL TASARIM Premium Kartı
/// Diğer kartlardan farklılaşması için "Black & Gold" teması kullanıldı.
class DashboardPremiumCard extends StatelessWidget {
  const DashboardPremiumCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = PremiumService().isPremium;

    // Premium Değilse: Siyah/Koyu Gri zemin üzerine Altın detaylar (Lüks hissi)
    // Premium ise: Yeşil/Teal zemin (Huzur ve başarı hissi)
    
    return GestureDetector(
      onTap: () => isPremium ? _showPremiumBenefitsDialog(context) : context.push('/premium'),
      child: Container(
        height: 70, // Biraz daha ince ve zarif
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // ZEMİN RENGİ
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPremium 
              ? [ const Color(0xFF059669), const Color(0xFF10B981) ] // Zümrüt Yeşili (Aktif)
              : [ const Color(0xFF1A1A1A), const Color(0xFF2D2D2D) ], // Mat Siyah (Pasif)
          ),
          boxShadow: [
            BoxShadow(
              color: (isPremium ? const Color(0xFF10B981) : Colors.black).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          // KENARLIK (Border)
          border: Border.all(
            color: isPremium 
               ? Colors.white.withValues(alpha: 0.2)
               : const Color(0xFFFFD700).withValues(alpha: 0.3), // Altın kenarlık
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // SOL TARAF: İKON
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isPremium 
                    ? Colors.white.withValues(alpha: 0.2) 
                    : const Color(0xFFFFD700).withValues(alpha: 0.2), // Altın sarısı bg
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPremium ? LucideIcons.badgeCheck : LucideIcons.crown, // Taç veya Rozet
                color: isPremium ? Colors.white : const Color(0xFFFFD700), // Altın Rengi İkon
                size: 20,
              ),
            ),
            
            const SizedBox(width: 14),
            
            // ORTA TARAF: METİN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isPremium ? 'Premium Üyesiniz' : 'Premium\'a Yükselt',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPremium 
                      ? 'Tüm özellikler aktif ✨' 
                      : 'Reklamsız ve sınırsız deneyim',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // SAĞ TARAF: OK veya AKSİYON
            Icon(
              LucideIcons.chevronRight,
              color: Colors.white.withValues(alpha: 0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumBenefitsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryGreen, primaryGreen.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.crown, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Aktif 🎉',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Tüm özelliklere erişiminiz var',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Benefits Grid
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildCompactBenefitRow(
                      context,
                      [
                        _BenefitData(LucideIcons.sparkles, 'AI Koç', 'Limitsiz'),
                        _BenefitData(LucideIcons.library, 'Konular', 'Tümü Açık'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildCompactBenefitRow(
                      context,
                      [
                        _BenefitData(LucideIcons.ban, 'Reklamlar', 'Yok'),
                        _BenefitData(LucideIcons.zap, 'Quiz', 'Hızlı Mod'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildCompactBenefitRow(
                      context,
                      [
                        _BenefitData(LucideIcons.bookOpen, 'Hikayeler', 'Açık'),
                        _BenefitData(LucideIcons.image, 'Özetler', 'Görsel'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildCompactBenefitRow(
                      context,
                      [
                        _BenefitData(LucideIcons.gamepad2, 'Oyunlar', 'Açık'),
                        _BenefitData(LucideIcons.calendar, 'Plan', 'Çalışma'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: primaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tamam',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/subscription-management');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Abonelik Yönetimi',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBenefitRow(BuildContext context, List<_BenefitData> benefits) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
    
    return Row(
      children: benefits.map((benefit) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: benefit == benefits.last ? 0 : 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(benefit.icon, size: 18, color: primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF374151),
                      ),
                    ),
                    Text(
                      benefit.subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white60 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

/// Helper sınıf - özellik verisi
class _BenefitData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitData(this.icon, this.title, this.subtitle);
}
