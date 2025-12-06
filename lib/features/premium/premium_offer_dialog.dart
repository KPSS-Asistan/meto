import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Kullanıcıya premium teklifi sunan dialog - Sales Psychology Edition (Matching PremiumPage)
class PremiumOfferDialog extends StatelessWidget {
  const PremiumOfferDialog({super.key});

  // PremiumPage ile Birebir Uyumlu Renk Paleti
  static const Color _colActionStart = Color(0xFFFF6D00); // Canlı Turuncu
  static const Color _colActionEnd = Color(0xFFFF3D00);   // Kırmızıya çalan Turuncu
  static const Color _colTrust = Color(0xFF0D47A1);       // Derin Mavi
  static const Color _colValue = Color(0xFF00C853);       // Zümrüt Yeşili

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PremiumOfferDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header (Turuncu Gradient - Aciliyet)
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_colActionStart, _colActionEnd],
                    ),
                  ),
                ),
                
                // Dekoratif Daireler
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),

                // Ana İkon (Timer)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    size: 48,
                    color: _colActionEnd,
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

                // İndirim Rozeti
                Positioned(
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _colValue,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '%50 İNDİRİM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5, end: 0),
                ),

                // Kapat Butonu
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ],
            ),

            // 2. İçerik
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  // Başlık
                  Text(
                    'Fırsatı Kaçırma! 🔥',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 8),
                  
                  // Sayaç (Placeholder - Logic raporda anlatılacak)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _colActionEnd.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _colActionEnd.withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      'Kalan Süre: 59:59', // Dinamik olacak
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _colActionEnd,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Bu teklif sadece 1 saat geçerli! Premium özelliklere %50 indirimle sahip ol.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Özellikler
                  _buildFeatureItem(Icons.rocket_launch_rounded, 'Hızlandırılmış AI Planı', isDark),
                  _buildFeatureItem(Icons.all_inclusive_rounded, 'Sınırsız Soru Çözümü', isDark),
                  _buildFeatureItem(Icons.block_rounded, 'Reklamsız Kesintisiz Odak', isDark),
                  
                  const SizedBox(height: 24),
                  
                  // CTA Button
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_colActionStart, _colActionEnd],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _colActionEnd.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/premium');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'İNDİRİMİ YAKALA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.03, duration: 1.seconds, curve: Curves.easeInOut),
                  
                  const SizedBox(height: 12),
                  
                  // Secondary Action
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    child: const Text(
                      'Fırsatı Kaçırıyorum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildFeatureItem(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _colTrust.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: _colTrust),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
