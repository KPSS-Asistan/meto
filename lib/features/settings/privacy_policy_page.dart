import 'package:flutter/material.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sections = <_PolicySection>[
      const _PolicySection(
        title: 'Giriş',
        body:
            'Bu Gizlilik Politikası, KPSS Asistan 2026 mobil uygulamasını cihazına yükleyen tüm kullanıcılar için yürürlüğe girer. Kullanıcı, uygulamayı kaldırarak politikayı sona erdirebilir.',
      ),
      const _PolicySection(
        title: 'Bilgilerin Kullanılması',
        body:
            'Toplanan kişisel veriler hizmeti sunmak, kişiselleştirmek, güvenliği sağlamak ve yasal yükümlülükleri yerine getirmek için kullanılır.',
        bulletPoints: [
          'Kimlik & iletişim: ad, soyad, e‑posta, profil görseli, sınav yılı.',
          'Akademik veriler: çözülen sorular, yanlışlar, favoriler, flashcard ilerlemesi, AI koç sohbetleri.',
          'Cihaz verileri: işletim sistemi, cihaz modeli, IP, çökme logları, performans ölçümleri.',
          'Konum: yalnızca şehir/bölge (IP tabanlı) ve tercihe bağlı bildirim önerileri.',
          'Ödeme: Kart bilgileri uygulamada saklanmaz; Google Play / App Store tarafından işlenir.',
        ],
      ),
      const _PolicySection(
        title: 'Bilgilerin Paylaşılması',
        body:
            'Veriler yalnızca hizmet sağlayıcılarımız (Firebase Auth, Firestore, Storage, Analytics, Crashlytics, bildirim servisleri) ile paylaşılır. Yasal zorunluluk olması hâlinde resmi mercilere aktarım yapılabilir.',
      ),
      const _PolicySection(
        title: 'Kullanıcı İzinleri',
        body:
            'Uygulamanın sağlıklı çalışması için belirli cihaz izinlerine ihtiyaç duyulur; kullanıcı izinleri cihaz ayarlarından yönetilebilir.',
        bulletPoints: [
          'Depolama / Fotoğraf: profil görseli ve offline veriler.',
          'Push bildirimleri: hatırlatmalar ve duyurular.',
          'Konum (opsiyonel): çalışma önerileri; gerçek koordinatlar tutulmaz.',
        ],
      ),
      const _PolicySection(
        title: 'Saklama Süresi',
        body:
            'Hesap silme talebinden sonra veriler 90 gün içinde aktif sistemlerden kaldırılır. Log ve yedekler yasal gereklilikler sebebiyle azami 2 yıl saklanır.',
      ),
      const _PolicySection(
        title: 'Sorumluluğun Sınırlandırılması',
        body:
            'Tüm güvenlik önlemlerine rağmen internet altyapısı, üçüncü taraf saldırıları veya kullanıcı hatalarından doğan veri ihlallerinde KPSS Asistan’ın sorumluluğu yürürlükteki mevzuatın izin verdiği ölçüde sınırlıdır.',
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
