import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kpss_2026/core/services/study_schedule_service.dart';

/// PDF olarak ders programı çıktısı oluşturur
/// Her gün ayrı tablo - Wrap ile sayfa bölünmesi kontrolü
class SchedulePdfExporter {
  SchedulePdfExporter._(); // Private constructor

  // Gün renkleri
  static const List<PdfColor> _dayColors = [
    PdfColors.blue600,    // Pzt
    PdfColors.teal600,    // Sal
    PdfColors.green600,   // Çar
    PdfColors.orange600,  // Per
    PdfColors.purple600,  // Cum
    PdfColors.pink600,    // Cmt
    PdfColors.red600,     // Paz
  ];

  // Satır yüksekliği (yaklaşık)
  static const double _rowHeight = 22.0;
  static const double _headerHeight = 28.0;
  
  // A4 sayfa bilgileri
  static const double _pageUsableHeight = 750.0; // A4 - margins - header/footer

  /// PDF oluştur ve yazdırma/paylaşma dialogu aç
  static Future<void> exportToPdf(WeeklySchedule schedule) async {
    final pdf = pw.Document();
    
    // Google Fonts'tan Türkçe destekli font yükle
    final ttf = await PdfGoogleFonts.notoSansRegular();
    final boldTtf = await PdfGoogleFonts.notoSansBold();

    // Günleri listele
    final daysWithBlocks = schedule.days.where((day) => day.blocks.isNotEmpty).toList();
    
    // Günleri sayfa yüksekliğine göre grupla
    final pageGroups = _groupDaysByPageHeight(daysWithBlocks);

    for (int pageIndex = 0; pageIndex < pageGroups.length; pageIndex++) {
      final daysInPage = pageGroups[pageIndex];
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Sadece ilk sayfada header
              if (pageIndex == 0) _buildHeader(schedule, ttf, boldTtf),
              
              // Bu sayfadaki günler
              ...daysInPage.map((day) => _buildDayTable(day, ttf, boldTtf)),
              
              pw.Spacer(),
              
              // Footer
              _buildFooter(pageIndex + 1, pageGroups.length, ttf),
            ],
          ),
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'KPSS_Ders_Programi.pdf',
    );
  }

  /// Günleri sayfa yüksekliğine göre grupla
  static List<List<DailySchedule>> _groupDaysByPageHeight(List<DailySchedule> days) {
    final groups = <List<DailySchedule>>[];
    var currentGroup = <DailySchedule>[];
    double currentHeight = 80; // Header için başlangıç yüksekliği
    
    for (final day in days) {
      final dayHeight = _headerHeight + (day.blocks.length * _rowHeight) + 16; // +16 margin
      
      // Bu gün mevcut sayfaya sığar mı?
      if (currentHeight + dayHeight > _pageUsableHeight && currentGroup.isNotEmpty) {
        // Sığmaz - yeni sayfa başlat
        groups.add(currentGroup);
        currentGroup = [day];
        currentHeight = dayHeight;
      } else {
        // Sığar - mevcut sayfaya ekle
        currentGroup.add(day);
        currentHeight += dayHeight;
      }
    }
    
    // Son grubu ekle
    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }
    
    return groups;
  }

  static pw.Widget _buildHeader(WeeklySchedule schedule, pw.Font ttf, pw.Font boldTtf) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('KPSS Haftalık Çalışma Planı',
                style: pw.TextStyle(font: boldTtf, fontSize: 16, color: PdfColors.grey800)),
              pw.Text('${(schedule.totalWeeklyMinutes / 60).toStringAsFixed(0)} saat • ${schedule.totalBlocks} ders',
                style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue600,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text('KPSS Asistan 2026',
              style: pw.TextStyle(font: boldTtf, fontSize: 7, color: PdfColors.white)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(int currentPage, int totalPages, pw.Font ttf) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Sayfa $currentPage/$totalPages • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey500),
      ),
    );
  }

  /// Her gün için ayrı tablo - başlık tablonun parçası
  static pw.Widget _buildDayTable(DailySchedule day, pw.Font ttf, pw.Font boldTtf) {
    final dayColor = _dayColors[day.dayIndex % _dayColors.length];
    final dayName = StudyScheduleService.getDayName(day.dayIndex).toUpperCase();
    final totalMinutes = day.blocks.fold<int>(0, (sum, b) => sum + b.durationMinutes);
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Gün başlığı
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: pw.BoxDecoration(
              color: dayColor,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  dayName,
                  style: pw.TextStyle(font: boldTtf, fontSize: 10, color: PdfColors.white, letterSpacing: 0.5),
                ),
                pw.Text(
                  '${day.blocks.length} ders • ${(totalMinutes / 60).toStringAsFixed(1)} saat',
                  style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.white),
                ),
              ],
            ),
          ),
          
          // Ders satırları
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(4),
                bottomRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Column(
              children: day.blocks.asMap().entries.map((entry) {
                final i = entry.key;
                final block = entry.value;
                final rowColor = i.isEven ? PdfColors.white : PdfColors.grey50;
                
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: pw.BoxDecoration(color: rowColor),
                  child: pw.Row(
                    children: [
                      // Checkbox
                      pw.Container(
                        width: 11,
                        height: 11,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      // Saat
                      pw.SizedBox(
                        width: 65,
                        child: pw.Text(
                          block.timeRange,
                          style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey700),
                        ),
                      ),
                      // Ders adı
                      pw.Expanded(
                        child: pw.Text(
                          block.lessonName,
                          style: pw.TextStyle(font: boldTtf, fontSize: 9, color: PdfColors.grey900),
                        ),
                      ),
                      // Aktivite
                      pw.SizedBox(
                        width: 55,
                        child: pw.Text(
                          block.activityName,
                          style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey600),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      // Süre
                      pw.SizedBox(
                        width: 30,
                        child: pw.Text(
                          '${block.durationMinutes}dk',
                          style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey600),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
