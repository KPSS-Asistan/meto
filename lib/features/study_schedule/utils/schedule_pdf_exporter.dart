import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kpss_2026/core/services/study_schedule_service.dart';

/// PDF olarak ders programı çıktısı oluşturur
/// Her gün ayrı tablo - başlık ve içerik birleşik
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

  /// PDF oluştur ve yazdırma/paylaşma dialogu aç
  static Future<void> exportToPdf(WeeklySchedule schedule) async {
    final pdf = pw.Document();
    
    // Google Fonts'tan Türkçe destekli font yükle
    final ttf = await PdfGoogleFonts.notoSansRegular();
    final boldTtf = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildHeader(schedule, ttf, boldTtf),
        footer: (context) => _buildFooter(context, ttf),
        build: (context) => [
          // Her gün için ayrı tablo
          ...schedule.days.where((day) => day.blocks.isNotEmpty).map((day) {
            return _buildDayTable(day, ttf, boldTtf);
          }),
          pw.SizedBox(height: 12),
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

  static pw.Widget _buildFooter(pw.Context context, pw.Font ttf) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 6),
      child: pw.Text(
        'Sayfa ${context.pageNumber}/${context.pagesCount} • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey500),
      ),
    );
  }

  /// Her gün için ayrı tablo - başlık tablonun parçası
  static pw.Widget _buildDayTable(DailySchedule day, pw.Font ttf, pw.Font boldTtf) {
    final dayColor = _dayColors[day.dayIndex % _dayColors.length];
    final dayName = StudyScheduleService.getDayName(day.dayIndex).toUpperCase();
    final totalMinutes = day.blocks.fold<int>(0, (sum, b) => sum + b.durationMinutes);
    
    final rows = <pw.TableRow>[];
    
    // İlk satır = Gün başlığı (tablonun parçası)
    rows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: dayColor),
        children: [
          // Gün adı - 3 sütunu kapsıyor
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: pw.Text(
              dayName,
              style: pw.TextStyle(font: boldTtf, fontSize: 11, color: PdfColors.white, letterSpacing: 0.5),
            ),
          ),
          pw.Container(), // Boş
          pw.Container(), // Boş
          // Özet - sağ taraf
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: pw.Text(
              '${day.blocks.length} ders • ${(totalMinutes / 60).toStringAsFixed(1)} saat',
              style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.white),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
    
    // Ders satırları
    for (int i = 0; i < day.blocks.length; i++) {
      final block = day.blocks[i];
      final rowColor = i.isEven ? PdfColors.white : PdfColors.grey50;
      
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: rowColor),
          children: [
            // Checkbox + Saat
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 12,
                    height: 12,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    block.timeRange,
                    style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            // Ders adı
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: pw.Text(
                block.lessonName,
                style: pw.TextStyle(font: boldTtf, fontSize: 10, color: PdfColors.grey900),
              ),
            ),
            // Aktivite
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: pw.Text(
                block.activityName,
                style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // Süre
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: pw.Text(
                '${block.durationMinutes}dk',
                style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey600),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        columnWidths: {
          0: const pw.FixedColumnWidth(90),  // Checkbox + Saat
          1: const pw.FlexColumnWidth(1),    // Ders
          2: const pw.FixedColumnWidth(65),  // Aktivite
          3: const pw.FixedColumnWidth(45),  // Süre
        },
        children: rows,
      ),
    );
  }

  static pw.Widget _buildInfoBox(pw.Font ttf) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 10, height: 10,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500, width: 1),
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.Center(
              child: pw.Text('✓', style: pw.TextStyle(font: ttf, fontSize: 7, color: PdfColors.grey600)),
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text('Tamamlanan dersleri isaretleyin',
            style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }
}
