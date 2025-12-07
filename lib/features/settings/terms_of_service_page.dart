import 'package:flutter/material.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sections = <_TermSection>[
      const _TermSection(
        title: '1. Kabul',
        body:
            'KPSS 2026 uygulamasını kullanarak bu koşulları kabul etmiş sayılırsınız.',
      ),
      const _TermSection(
        title: '2. Hizmet',
        body:
            'KPSS sınavına hazırlık için eğitim içerikleri, testler ve performans takibi sunuyoruz.',
      ),
      const _TermSection(
        title: '3. Hesap',
        body:
            'Hesap güvenliğinden siz sorumlusunuz. Doğru bilgiler sağlamalı ve şifrenizi kimseyle paylaşmamalısınız.',
      ),
      const _TermSection(
        title: '4. Kullanım Kuralları',
        body:
            'Uygulamayı yalnızca kişisel eğitim amaçlı kullanabilirsiniz:',
        bulletPoints: [
          'İçerikleri kopyalayamaz veya dağıtamazsınız',
          'Ticari amaçla kullanamazsınız',
          'Güvenliği tehlikeye atamazsınız',
          'Diğer kullanıcılara zarar veremezsiniz',
        ],
      ),
      const _TermSection(
        title: '5. Fikri Mülkiyet',
        body:
            'Tüm içerikler telif hakkıyla korunmaktadır ve KPSS 2026\'ya aittir.',
      ),
      const _TermSection(
        title: '6. Sorumluluk',
        body:
            'İçeriklerin doğruluğu için çaba gösteririz ancak garanti veremeyiz. Sınav sonuçlarınızdan sorumlu değiliz.',
      ),
      const _TermSection(
        title: '7. Hizmet Kesintileri',
        body:
            'Uygulama "olduğu gibi" sunulmaktadır. Kesintisiz hizmet garantisi yoktur.',
      ),
      const _TermSection(
        title: '8. Hesap Kapatma',
        body:
            'Kuralları ihlal ederseniz hesabınız kapatılabilir.',
      ),
      const _TermSection(
        title: '9. Değişiklikler',
        body:
            'Bu koşullar güncellenebilir. Önemli değişiklikler duyurulacaktır.\n\nSon güncelleme: Aralık 2025',
      ),
      const _TermSection(
        title: '10. İletişim',
        body:
            'Sorularınız için: destek@kpss2026.com',
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Kullanım Koşulları'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: section.build(context, isDark),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: sections.length,
      ),
    );
  }
}

class _TermSection {
  final String title;
  final String body;
  final List<String> bulletPoints;

  const _TermSection({
    required this.title,
    this.body = '',
    this.bulletPoints = const [],
  });

  Widget build(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color:
                  isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
        if (bulletPoints.isNotEmpty) ...[
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: bulletPoints
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6, right: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
