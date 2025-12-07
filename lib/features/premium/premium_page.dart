import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Premium Üyelik Sayfası - Enhanced Version
/// Detaylı özellikler, Social Proof, SSS ve Stratejik Urgency
class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  int _selectedPlan = 1;
  bool _showAllFeatures = false; // Tüm özellikleri göster/gizle

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }



  // Modern Renk Paleti
  static const Color _accentPrimary = Color(0xFF6366F1);
  static const Color _accentSuccess = Color(0xFF10B981);
  // ignore: unused_field
  static const Color _accentWarning = Color(0xFFF59E0B);

  final List<Map<String, dynamic>> _plans = [
    {
      'period': '1 Aylık',
      'monthlyPrice': '₺49,99',
      'totalInfo': 'Aylık yenilenir',
      'oldPrice': null,
      'badge': null,
      'icon': Icons.calendar_today_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'period': '3 Aylık',
      'monthlyPrice': '₺33,33',
      'totalInfo': 'Toplam ₺99,99',
      'oldPrice': '₺49,99',
      'badge': 'EN POPÜLER',
      'icon': Icons.star_rounded,
      'color': Color(0xFF6366F1),
    },
    {
      'period': '12 Aylık',
      'monthlyPrice': '₺25,00',
      'totalInfo': 'Toplam ₺299,99',
      'oldPrice': '₺49,99',
      'badge': '%50 İNDİRİM',
      'isDiscount': true,
      'icon': Icons.workspace_premium_rounded,
      'color': Color(0xFF10B981),
    },
  ];

  // Genişletilmiş özellikler listesi
  final List<Map<String, dynamic>> _allFeatures = [
    {
      'icon': Icons.auto_graph_rounded,
      'title': 'AI Destekli Çalışma Planı',
      'subtitle': 'Sana özel haftalık program',
      'color': Color(0xFF6366F1),
    },
    {
      'icon': Icons.quiz_rounded,
      'title': 'Sınırsız Deneme Sınavı',
      'subtitle': 'Gerçek sınav deneyimi',
      'color': Color(0xFFF59E0B),
    },
    {
      'icon': Icons.psychology_rounded,
      'title': 'AI Koç Desteği',
      'subtitle': 'Sorularına anında cevap',
      'color': Color(0xFF8B5CF6),
    },
    {
      'icon': Icons.trending_up_rounded,
      'title': 'Detaylı Performans Analizi',
      'subtitle': 'Zayıf konularını keşfet',
      'color': Color(0xFF10B981),
    },
    {
      'icon': Icons.download_rounded,
      'title': 'Offline Mod',
      'subtitle': 'İnternetsiz çalış',
      'color': Color(0xFF06B6D4),
    },
    {
      'icon': Icons.block_rounded,
      'title': 'Reklamsız Deneyim',
      'subtitle': 'Kesintisiz odaklan',
      'color': Color(0xFFEF4444),
    },
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
        title: const Text('Premium', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              physics: const BouncingScrollPhysics(),
              children: [

                // Header Title & Slogan
                _buildHeader(textColor, subtextColor),
                const SizedBox(height: 20),

                // Features Section
                _buildFeaturesSection(cardColor, textColor, subtextColor),
                const SizedBox(height: 16),

                // Plan Selection Section
                _buildSection(
                  title: 'Plan Seçin',
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  children: _plans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final plan = entry.value;
                    return _buildPlanTile(
                      index: index,
                      plan: plan,
                      isDark: isDark,
                      textColor: textColor,
                      subtextColor: subtextColor,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),

          // Fixed Bottom CTA
          _buildBottomSection(isDark, cardColor, subtextColor),
        ],
      ),
    );
  }





  Widget _buildFeaturesSection(Color cardColor, Color textColor, Color subtextColor) {
    final featuresToShow = _showAllFeatures ? _allFeatures : _allFeatures.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Premium Avantajları',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: subtextColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ...featuresToShow.map((f) => _buildFeatureTile(
                icon: f['icon'] as IconData,
                title: f['title'] as String,
                subtitle: f['subtitle'] as String,
                color: f['color'] as Color,
                textColor: textColor,
                subtextColor: subtextColor,
              )),
              // Daha Fazla Butonu
              if (!_showAllFeatures)
                InkWell(
                  onTap: () => setState(() => _showAllFeatures = true),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: subtextColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Daha Fazla',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _accentPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _accentPrimary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }



  Widget _buildHeader(Color textColor, Color subtextColor) {
    return Column(
      children: [
        // Title
        Text(
          'Başarını Şansa Bırakma',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSection({
    required String title,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: subtextColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color textColor,
    required Color subtextColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: subtextColor),
      ),
      trailing: Icon(
        Icons.check_circle_rounded,
        color: _accentSuccess,
        size: 20,
      ),
    );
  }

  Widget _buildPlanTile({
    required int index,
    required Map<String, dynamic> plan,
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
  }) {
    final isSelected = _selectedPlan == index;
    final color = plan['color'] as Color;
    final isPopular = index == 1;
    
    return InkWell(
      onTap: () => setState(() => _selectedPlan = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: isPopular ? const EdgeInsets.symmetric(vertical: 4) : EdgeInsets.zero,
        padding: EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: isPopular ? 16 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: isPopular ? BorderRadius.circular(12) : null,
          border: isSelected
              ? Border(left: BorderSide(color: color, width: 3))
              : isPopular
                  ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
                  : null,
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : isPopular
                  ? color.withValues(alpha: 0.03)
                  : Colors.transparent,
          boxShadow: isPopular && isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : subtextColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(plan['icon'] as IconData, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan['period'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (plan['badge'] != null) ...[
                        const SizedBox(width: 8),
                        _buildBadge(
                          plan['badge'] as String,
                          plan['isDiscount'] == true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan['totalInfo'] as String,
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (plan['oldPrice'] != null)
                  Text(
                    plan['oldPrice'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtextColor,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan['monthlyPrice'] as String,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? color : textColor,
                      ),
                    ),
                    Text(
                      '/ay',
                      style: TextStyle(fontSize: 11, color: subtextColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, bool isDiscount) {
    final color = isDiscount ? _accentSuccess : _accentPrimary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildLegalLinks(Color subtextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => context.push('/terms-of-service'),
          child: Text(
            'Kullanım Şartları',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: subtextColor,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('•', style: TextStyle(color: subtextColor, fontSize: 12)),
        ),
        GestureDetector(
          onTap: () => context.push('/privacy-policy'),
          child: Text(
            'Gizlilik Politikası',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: subtextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(bool isDark, Color cardColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _accentPrimary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _handlePurchase,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '7 Gün Ücretsiz Dene',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Memnun kalmazsan anında iptal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(
              duration: 3.seconds,
              color: Colors.white.withValues(alpha: 0.15),
              delay: 2.seconds,
            ),
            
            const SizedBox(height: 12),
            _buildTrustBadges(subtextColor),
            const SizedBox(height: 8),
            _buildLegalLinks(subtextColor),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildTrustBadges(Color subtextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded, size: 12, color: subtextColor),
        const SizedBox(width: 4),
        Text(
          'Güvenli Ödeme',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: subtextColor),
        ),
        Container(
          height: 3, width: 3, 
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: subtextColor, shape: BoxShape.circle),
        ),
        Icon(Icons.cancel_outlined, size: 12, color: subtextColor),
        const SizedBox(width: 4),
        Text(
          'İstediğin Zaman İptal',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: subtextColor),
        ),
      ],
    );
  }

  void _handlePurchase() {
    final selectedPlan = _plans[_selectedPlan];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedPlan['period']} planı yakında aktif olacak'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _FAQTile extends StatefulWidget {
  final String question;
  final String answer;
  final Color textColor;
  final Color subtextColor;

  const _FAQTile({
    required this.question,
    required this.answer,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        leading: Icon(
          _isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
          color: const Color(0xFF6366F1),
          size: 20,
        ),
        title: Text(
          widget.question,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.textColor,
          ),
        ),
        onExpansionChanged: (v) => setState(() => _isExpanded = v),
        children: [
          Text(
            widget.answer,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: widget.subtextColor,
            ),
          ),
        ],
      ),
    );
  }
}
