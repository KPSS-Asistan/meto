import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Şifreler - Ders Seçim Sayfası
class MnemonicsSelectionPage extends StatelessWidget {
  const MnemonicsSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final lessons = [
      {
        'id': 'BRhOEZEWRJSjcRcTWVUf',
        'name': 'Tarih',
        'icon': Icons.history_edu_rounded,
        'color': const Color(0xFFEF4444),
        'count': 10,
        'desc': 'Osmanlı, Cumhuriyet, Antlaşmalar',
      },
      {
        'id': 'JlCZGN9wlbLVPpGqTgHM',
        'name': 'Coğrafya',
        'icon': Icons.public_rounded,
        'color': const Color(0xFF22C55E),
        'count': 9,
        'desc': 'Bölgeler, İklimler, Göller',
      },
      {
        'id': '2ztkqV35cWjGRkhYRutg',
        'name': 'Vatandaşlık',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFF3B82F6),
        'count': 9,
        'desc': 'Anayasa, Yargı, Haklar',
      },
      {
        'id': 'gvdNPWLhpLqXbXZVJQbQ',
        'name': 'Türkçe',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFFF59E0B),
        'count': 10,
        'desc': 'Ses bilgisi, Sözcük türleri',
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.lightbulb_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Şifreler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Açıklama
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    const Color(0xFFF59E0B).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tips_and_updates_rounded,
                      color: Color(0xFFF59E0B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hafıza Teknikleri',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Zor konuları kolay hatırlamak için şifreler',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Ders kartları
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final lesson = lessons[index];
                  return _buildLessonCard(context, lesson, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, Map<String, dynamic> lesson, bool isDark) {
    final color = lesson['color'] as Color;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(
            '/lessons/${lesson['id']}/topics/all/mnemonics',
            extra: {'topicName': lesson['name']},
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İkon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  lesson['icon'] as IconData,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              
              // Başlık
              Text(
                lesson['name'] as String,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              
              // Açıklama
              Text(
                lesson['desc'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Şifre sayısı
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${lesson['count']} şifre',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
