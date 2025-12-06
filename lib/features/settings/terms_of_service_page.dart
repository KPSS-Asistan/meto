import 'package:flutter/material.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sections = <_TermSection>[
      const _TermSection(
        title: '1. Giriş',
        body:
            'Bu Kullanım Koşulları ("Koşullar"), KPSS Asistan 2026 mobil uygulamasını ("Uygulama") kullanımınızı yönetir. Uygulamayı kullanarak, bu Koşulları kabul etmiş sayılırsınız.',
      ),
      const _TermSection(
        title: '2. Hizmet Tanımı',
        body:
            'KPSS Asistan 2026, kullanıcıların KPSS sınavına hazırlanmalarına yardımcı olmak amacıyla geliştirilmiş bir mobil uygulamadır. Uygulama şu hizmetleri sunar:',
        bulletPoints: [
          'Konu anlatımları ve ders notları',
          'Çıkmış sorular ve çözümleri',
          'Deneme sınavları ve testler',
          'Performans takip ve analiz',
          'Kişiselleştirilmiş çalışma planı',
        ],
      ),
      const _TermSection(
        title: '3. Hesap Sorumlulukları',
        body:
            'Uygulamayı kullanmak için bir hesap oluşturmanız gerekebilir. Hesap bilgilerinizin güvenliğinden siz sorumlusunuz. Hesabınız aracılığıyla gerçekleştirilen tüm işlemlerden siz sorumlu olacaksınız.',
      ),
      const _TermSection(
        title: '4. Kullanım Koşulları',
        body:
            'Uygulamayı kullanırken aşağıdaki kurallara uymayı kabul edersiniz:',
        bulletPoints: [
          'Uygulamayı yalnızca yasal amaçlarla kullanacaksınız.',
          'Uygulamanın çalışmasını engelleyecek veya bozacak herhangi bir eylemde bulunmayacaksınız.',
          'Telif hakkı, ticari marka veya diğer mülkiyet haklarını ihlal eden içerik paylaşmayacaksınız.',
          'Diğer kullanıcıların deneyimini olumsuz etkileyecek davranışlarda bulunmayacaksınız.',
          'Uygulamanın kaynak kodunu tersine mühendislik yapmayacak veya çoğaltmayacaksınız.',
        ],
      ),
      const _TermSection(
        title: '5. Fikri Mülkiyet',
        body:
            'Uygulamada yer alan tüm içerik, telif hakkı, ticari marka ve diğer fikri mülkiyet yasalarıyla korunmaktadır. Uygulama içeriğini izinsiz kopyalayamaz, çoğaltamaz veya dağıtamazsınız.',
      ),
      const _TermSection(
        title: '6. Sorumluluk Reddi',
        body:
            'Uygulama "olduğu gibi" ve "mümkün olduğu sürece" sunulmaktadır. Uygulamanın kesintisiz, güvenli veya hatasız olacağına dair herhangi bir garanti vermiyoruz. Sınav sonuçlarınız üzerinde doğrudan etkisi olabilecek kararlar vermeden önce resmi kaynakları kontrol etmelisiniz.',
      ),
      const _TermSection(
        title: '7. Değişiklikler ve Güncellemeler',
        body:
            'Uygulamanın içeriğini ve işlevselliğini herhangi bir zamanda değiştirme, güncelleme veya kaldırma hakkını saklı tutarız. Bu tür değişikliklerden önce sizi bilgilendirmeye çalışacağız, ancak bu her zaman mümkün olmayabilir.',
      ),
      const _TermSection(
        title: '8. Üyelik ve Ödemeler',
        body:
            'Bazı özellikler ücretli abonelik gerektirebilir. Ücretli hizmetler için ödeme yapmadan önce fiyatlandırma bilgilerini dikkatlice inceleyin. Abonelikler genellikle otomatik olarak yenilenir ve iptal edilmediği sürece devam eder.',
      ),
      const _TermSection(
        title: '9. İptal ve İade Politikası',
        body:
            'Uygulama içi satın alımlar için App Store ve Google Play mağazalarının iptal ve iade politikaları geçerlidir. Uygulama üzerinden doğrudan iade işlemi yapılamamaktadır.',
      ),
      const _TermSection(
        title: '10. Sonlandırma',
        body:
            'Bu Koşulları ihlal etmeniz durumunda, uyarıda bulunmaksızın hesabınızı askıya alma veya sonlandırma hakkını saklı tutarız. Hesabınızın sonlandırılması durumunda, uygulamayı kullanma hakkınız da sona erecektir.',
      ),
      const _TermSection(
        title: '11. Değişiklikler',
        body:
            'Bu Koşulları herhangi bir zamanda güncelleme hakkını saklı tutarız. Önemli değişiklikler için sizi bilgilendireceğiz, ancak düzenli olarak bu sayfayı gözden geçirmenizi öneririz.',
      ),
      const _TermSection(
        title: '12. İletişim',
        body:
            'Bu Koşullar hakkında herhangi bir sorunuz varsa, lütfen bize support@kpssasistan.com adresinden ulaşın.',
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
