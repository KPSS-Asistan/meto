import 'package:flutter/material.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sections = <_PolicySection>[
      const _PolicySection(
        title: '1. Genel Bilgiler',
        body:
            'KPSS 2026 uygulamasını kullanarak bu gizlilik politikasını kabul etmiş sayılırsınız. Kişisel verilerinizin korunması bizim için önemlidir.',
      ),
      const _PolicySection(
        title: '2. Toplanan Bilgiler',
        body:
            'Hizmetlerimizi sunabilmek için aşağıdaki bilgileri topluyoruz:',
        bulletPoints: [
          'Hesap bilgileri (e-posta, kullanıcı adı)',
          'Çalışma verileri (test sonuçları, ilerleme)',
          'Cihaz bilgileri (model, işletim sistemi)',
          'Kullanım istatistikleri',
        ],
      ),
      const _PolicySection(
        title: '3. Bilgilerin Kullanımı',
        body:
            'Topladığımız bilgiler şu amaçlarla kullanılır:',
        bulletPoints: [
          'Eğitim hizmetlerinin sunulması',
          'Performans analizi ve öneriler',
          'Uygulama iyileştirmeleri',
          'Bildirimler ve hatırlatmalar',
        ],
      ),
      const _PolicySection(
        title: '4. Veri Güvenliği',
        body:
            'Verileriniz endüstri standardı güvenlik önlemleriyle korunmaktadır. Ancak internet üzerinden yapılan hiçbir veri aktarımının %100 güvenli olduğunu garanti edemeyiz.',
      ),
      const _PolicySection(
        title: '5. Veri Paylaşımı',
        body:
            'Kişisel bilgileriniz üçüncü taraflarla paylaşılmaz. Sadece hizmet sağlayıcılarımız (bulut altyapısı, analitik) ile gerekli ölçüde paylaşılır.',
      ),
      const _PolicySection(
        title: '6. Kullanıcı Hakları',
        body:
            'Verilerinize erişebilir, düzeltebilir veya silebilirsiniz. Hesabınızı tamamen silmek için Ayarlar > Hesabı Sil seçeneğini kullanabilirsiniz.',
      ),
      const _PolicySection(
        title: '7. Çerezler',
        body:
            'Uygulama, kullanıcı deneyimini iyileştirmek için çerezler ve benzeri teknolojiler kullanır.',
      ),
      const _PolicySection(
        title: '8. Değişiklikler',
        body:
            'Bu politika zaman zaman güncellenebilir. Önemli değişiklikler uygulama içinde duyurulacaktır.\n\nSon güncelleme: Aralık 2025',
      ),
      const _PolicySection(
        title: '9. İletişim',
        body:
            'Sorularınız için: destek@kpss2026.com',
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
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

class _PolicySection {
  final String title;
  final String body;
  final List<String> bulletPoints;

  const _PolicySection({
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
