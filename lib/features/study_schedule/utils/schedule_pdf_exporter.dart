import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kpss_2026/core/services/study_schedule_service.dart';

/// PDF olarak ders programı çıktısı oluşturur
/// Checklist formatında, her gün için taktik önerileri içerir
class SchedulePdfExporter {
  SchedulePdfExporter._(); // Private constructor

  // Aktiviteye göre taktik önerileri
  static const Map<String, List<String>> _tacticsPerActivity = {
    'learn': [
      '💡 İlk okuduğunuzda anlamaya değil, genel resmi görmeye çalışın',
      '📝 Önemli kavramları kendi cümlelerinizle not alın',
      '🎯 Bu konuyu öğrenme amacınızı hatırlayın',
      '🔍 Zorlandığınız yerleri işaretleyin, sonra geri dönün',
      '📚 Konuyu küçük parçalara bölün, her parçayı ayrı öğrenin',
      '🧠 Aktif okuma yapın: "Bu ne anlama geliyor?" diye sorun',
    ],
    'review': [
      '🔄 Dün öğrendiklerinizi hatırlamaya çalışın (aktif geri çağırma)',
      '✍️ Notlarınıza bakmadan konuyu özetlemeye çalışın',
      '🎯 Aralıklı Tekrar: Bugün tekrar = %80 kalıcılık',
      '📊 Mindmap veya görsel şema çizerek tekrar edin',
      '🗣️ Konuyu birine anlatıyormuş gibi sesli tekrar edin',
      '❓ Kendi kendinize sorular sorun ve cevaplayın',
    ],
    'practice': [
      '📝 Soru çözerken zaman tutun ama acelemaye gerek yok',
      '❌ Yanlışlarınızı not alın, bunlar altın değerinde',
      '🔍 Neden yanlış olduğunu anlayın, sadece doğru cevabı değil',
      '⏱️ Gerçek sınav formatında pratik yapın',
      '📈 Her soru grubundan sonra performansınızı değerlendirin',
      '🎯 Zayıf konuları tespit edip ekstra pratik yapın',
    ],
  };

  // Gün bazlı motivasyon mesajları
  static const List<String> _dailyMotivations = [
    'Pazartesi enerjinizi hafta boyuna yayın! 💪',
    'Salı günü düzene oturmanın zamanı 📚',
    'Çarşamba: Hafta ortası performans günü! 🎯',
    'Perşembe: Son sprint öncesi konsantrasyon 🔥',
    'Cuma: Haftayı güçlü kapatın! ✨',
    'Cumartesi: Extra çalışma = Extra başarı 🚀',
    'Pazar: Haftalık tekrar ve planlama günü 📅',
  ];

  /// PDF oluştur ve yazdırma/paylaşma dialogu aç
  static Future<void> exportToPdf(WeeklySchedule schedule) async {
    final pdf = pw.Document();
    
    // Google Fonts'tan Türkçe destekli font yükle
    final ttf = await PdfGoogleFonts.notoSansRegular();
    final boldTtf = await PdfGoogleFonts.notoSansBold();

    // Renk paleti
    final dayColors = [
      PdfColors.blue700,    // Pzt
      PdfColors.teal700,    // Sal
      PdfColors.green700,   // Çar
      PdfColors.orange700,  // Per
      PdfColors.purple700,  // Cum
      PdfColors.pink700,    // Cmt
      PdfColors.red700,     // Paz
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(schedule, ttf, boldTtf),
        footer: (context) => _buildFooter(context, ttf),
        build: (context) => [
          // Her gün için section
          ...schedule.days.where((day) => day.blocks.isNotEmpty).map((day) {
            return _buildDaySection(day, dayColors, ttf, boldTtf);
          }),
          
          // Alt bilgi
          pw.SizedBox(height: 16),
          _buildInfoBox(ttf),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'KPSS_Ders_Programi.pdf',
    );
  }

  static pw.Widget _buildHeader(WeeklySchedule schedule, pw.Font ttf, pw.Font boldTtf) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('KPSS Haftalık Çalışma Planı',
                style: pw.TextStyle(font: boldTtf, fontSize: 22, color: PdfColors.grey800)),
              pw.SizedBox(height: 4),
              pw.Text('Toplam ${(schedule.totalWeeklyMinutes / 60).toStringAsFixed(0)} saat • ${schedule.totalBlocks} pomodoro bloğu',
                style: pw.TextStyle(font: ttf, fontSize: 11, color: PdfColors.grey600)),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.blue200, width: 0.5),
            ),
            child: pw.Text('KPSS Asistan 2026',
              style: pw.TextStyle(font: boldTtf, fontSize: 9, color: PdfColors.blue700)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font ttf) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        'Sayfa ${context.pageNumber}/${context.pagesCount}',
        style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey500),
      ),
    );
  }

  static pw.Widget _buildDaySection(
    DailySchedule day,
    List<PdfColor> dayColors,
    pw.Font ttf,
    pw.Font boldTtf,
  ) {
    final dayColor = dayColors[day.dayIndex % dayColors.length];
    final totalMinutes = day.blocks.fold<int>(0, (sum, b) => sum + b.durationMinutes);
    
    // O gündeki aktivitelere göre rastgele taktik seç
    final activities = day.blocks.map((b) => b.activity).toSet();
    final selectedTactics = <String>[];
    for (final activity in activities) {
      final tactics = _tacticsPerActivity[activity] ?? [];
      if (tactics.isNotEmpty) {
        // Her aktivite için bir taktik seç (deterministik - gün index'e göre)
        final index = (day.dayIndex + activities.toList().indexOf(activity)) % tactics.length;
        selectedTactics.add(tactics[index]);
      }
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Gün başlığı
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: pw.BoxDecoration(
              color: dayColor,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  StudyScheduleService.getDayName(day.dayIndex).toUpperCase(),
                  style: pw.TextStyle(font: boldTtf, fontSize: 13, color: PdfColors.white, letterSpacing: 1),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    '${day.blocks.length} ders • ${(totalMinutes / 60).toStringAsFixed(1)} saat',
                    style: pw.TextStyle(font: boldTtf, fontSize: 9, color: dayColor),
                  ),
                ),
              ],
            ),
          ),
          
          // Ders blokları - Checkbox listesi
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Column(
              children: day.blocks.asMap().entries.map((entry) {
                final index = entry.key;
                final block = entry.value;
                
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: pw.BoxDecoration(
                    color: index.isEven ? PdfColors.white : PdfColors.grey50,
                    border: index < day.blocks.length - 1 
                      ? pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))
                      : null,
                  ),
                  child: pw.Row(
                    children: [
                      // Checkbox (boş kare)
                      pw.Container(
                        width: 16,
                        height: 16,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400, width: 1.5),
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      
                      // Saat
                      pw.SizedBox(
                        width: 55,
                        child: pw.Text(
                          block.timeRange,
                          style: pw.TextStyle(font: boldTtf, fontSize: 10, color: PdfColors.grey700),
                        ),
                      ),
                      
                      // Ders adı
                      pw.Expanded(
                        child: pw.Text(
                          block.lessonName,
                          style: pw.TextStyle(font: boldTtf, fontSize: 11, color: PdfColors.grey900),
                        ),
                      ),
                      
                      // Aktivite ve süre
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          '${block.activityName} • ${block.durationMinutes}dk',
                          style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey600),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Günün Taktiği - Motivasyon kutusu
          if (selectedTactics.isNotEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: dayColor.shade(50),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(8),
                  bottomRight: pw.Radius.circular(8),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Günün Taktikleri:',
                    style: pw.TextStyle(font: boldTtf, fontSize: 9, color: dayColor),
                  ),
                  pw.SizedBox(height: 4),
                  ...selectedTactics.take(2).map((tactic) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      tactic,
                      style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey700),
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoBox(pw.Font ttf) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 14, height: 14,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey500, width: 1),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Center(
                  child: pw.Text('✓', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600)),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text('Tamamlanan dersleri isaretleyin',
                style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.Text('Olusturulma: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey500)),
        ],
      ),
    );
  }
}
