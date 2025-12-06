import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kpss_2026/core/data/lessons_data.dart';

/// Kullanıcı çalışma tercihleri modeli
class StudyPreferences {
  final int dailyHours;
  final List<int> availableDays; // 0=Pazartesi, 6=Pazar
  final int startHour; // Başlangıç saati (0-23)
  final int endHour;   // Bitiş saati (0-23)
  final List<String> priorityLessons;

  StudyPreferences({
    required this.dailyHours,
    required this.availableDays,
    required this.startHour,
    required this.endHour,
    required this.priorityLessons,
  });

  Map<String, dynamic> toJson() => {
    'dailyHours': dailyHours,
    'availableDays': availableDays,
    'startHour': startHour,
    'endHour': endHour,
    'priorityLessons': priorityLessons,
  };

  factory StudyPreferences.fromJson(Map<String, dynamic> json) => StudyPreferences(
    dailyHours: json['dailyHours'] as int,
    availableDays: List<int>.from(json['availableDays']),
    startHour: json['startHour'] as int? ?? 9,
    endHour: json['endHour'] as int? ?? 17,
    priorityLessons: List<String>.from(json['priorityLessons']),
  );
}

/// Tek bir çalışma bloğu (Pomodoro)
class StudyBlock {
  final String id;
  final String lessonId;
  final String lessonName;
  final int startHour;
  final int startMinute;
  final int durationMinutes; // 25dk
  final int breakMinutes;    // 5dk
  final bool isPriority;
  final String activity; // 'learn', 'review', 'practice'
  bool isCompleted;

  StudyBlock({
    required this.id,
    required this.lessonId,
    required this.lessonName,
    required this.startHour,
    required this.startMinute,
    required this.durationMinutes,
    required this.breakMinutes,
    required this.isPriority,
    required this.activity,
    this.isCompleted = false,
  });

  String get timeRange {
    final endMin = startMinute + durationMinutes;
    final endHour = startHour + (endMin ~/ 60);
    final endMinute = endMin % 60;
    return '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} - ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  String get activityName {
    switch (activity) {
      case 'learn': return 'Öğrenme';
      case 'review': return 'Tekrar';
      case 'practice': return 'Uygulama';
      default: return 'Çalışma';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lessonId': lessonId,
    'lessonName': lessonName,
    'startHour': startHour,
    'startMinute': startMinute,
    'durationMinutes': durationMinutes,
    'breakMinutes': breakMinutes,
    'isPriority': isPriority,
    'activity': activity,
    'isCompleted': isCompleted,
  };

  factory StudyBlock.fromJson(Map<String, dynamic> json) => StudyBlock(
    id: json['id'] as String,
    lessonId: json['lessonId'] as String,
    lessonName: json['lessonName'] as String,
    startHour: json['startHour'] as int,
    startMinute: json['startMinute'] as int,
    durationMinutes: json['durationMinutes'] as int,
    breakMinutes: json['breakMinutes'] as int,
    isPriority: json['isPriority'] as bool,
    activity: json['activity'] as String,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

/// Günlük program
class DailySchedule {
  final int dayIndex;
  final List<StudyBlock> blocks;

  DailySchedule({
    required this.dayIndex,
    required this.blocks,
  });

  int get totalMinutes => blocks.fold(0, (sum, b) => sum + b.durationMinutes);
  int get completedCount => blocks.where((b) => b.isCompleted).length;
  double get progress => blocks.isEmpty ? 0 : completedCount / blocks.length;

  Map<String, dynamic> toJson() => {
    'dayIndex': dayIndex,
    'blocks': blocks.map((b) => b.toJson()).toList(),
  };

  factory DailySchedule.fromJson(Map<String, dynamic> json) => DailySchedule(
    dayIndex: json['dayIndex'] as int,
    blocks: (json['blocks'] as List).map((b) => StudyBlock.fromJson(b)).toList(),
  );
}

/// Haftalık program
class WeeklySchedule {
  final List<DailySchedule> days;
  final DateTime createdAt;
  final StudyPreferences preferences;

  WeeklySchedule({
    required this.days,
    required this.createdAt,
    required this.preferences,
  });

  int get totalWeeklyMinutes => days.fold(0, (sum, d) => sum + d.totalMinutes);
  int get activeDaysCount => days.where((d) => d.blocks.isNotEmpty).length;
  int get totalBlocks => days.fold(0, (sum, d) => sum + d.blocks.length);
  int get completedBlocks => days.fold(0, (sum, d) => sum + d.completedCount);

  Map<String, dynamic> toJson() => {
    'days': days.map((d) => d.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'preferences': preferences.toJson(),
  };

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) => WeeklySchedule(
    days: (json['days'] as List).map((d) => DailySchedule.fromJson(d)).toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    preferences: StudyPreferences.fromJson(json['preferences']),
  );
}

/// Ders Programı Servisi
class StudyScheduleService {
  static const _scheduleKey = 'study_schedule_v3';
  static const _completedKey = 'completed_blocks';

  // Pomodoro sabitleri
  static const int pomodoroWorkMinutes = 25;
  static const int pomodoroBreakMinutes = 5;
  static const int longBreakMinutes = 15; // Her 4 pomodoro'da

  /// Kayıtlı programı getir
  static Future<WeeklySchedule?> getSavedSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_scheduleKey);
    if (json == null) return null;
    
    try {
      return WeeklySchedule.fromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  /// Programı kaydet
  static Future<void> saveSchedule(WeeklySchedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scheduleKey, jsonEncode(schedule.toJson()));
  }

  /// Programı sil
  static Future<void> clearSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scheduleKey);
    await prefs.remove(_completedKey);
  }

  /// Bloğu tamamlandı olarak işaretle
  static Future<void> toggleBlockCompletion(WeeklySchedule schedule, String blockId) async {
    for (final day in schedule.days) {
      for (final block in day.blocks) {
        if (block.id == blockId) {
          block.isCompleted = !block.isCompleted;
          break;
        }
      }
    }
    await saveSchedule(schedule);
  }

  /// Bloğu güncelle (ders değiştir)
  static Future<void> updateBlock(WeeklySchedule schedule, String blockId, String newLessonId, String newLessonName) async {
    for (final day in schedule.days) {
      for (int i = 0; i < day.blocks.length; i++) {
        if (day.blocks[i].id == blockId) {
          final oldBlock = day.blocks[i];
          day.blocks[i] = StudyBlock(
            id: oldBlock.id,
            lessonId: newLessonId,
            lessonName: newLessonName,
            startHour: oldBlock.startHour,
            startMinute: oldBlock.startMinute,
            durationMinutes: oldBlock.durationMinutes,
            breakMinutes: oldBlock.breakMinutes,
            isPriority: oldBlock.isPriority,
            activity: oldBlock.activity,
            isCompleted: oldBlock.isCompleted,
          );
          break;
        }
      }
    }
    await saveSchedule(schedule);
  }

  /// Bloğu sil
  static Future<void> deleteBlock(WeeklySchedule schedule, String blockId) async {
    for (final day in schedule.days) {
      day.blocks.removeWhere((b) => b.id == blockId);
    }
    await saveSchedule(schedule);
  }

  /// Yeni blok ekle
  static Future<void> addBlock(WeeklySchedule schedule, int dayIndex, String lessonId, String lessonName, int startHour) async {
    final day = schedule.days[dayIndex];
    final newId = '${dayIndex}_${day.blocks.length}_${DateTime.now().millisecondsSinceEpoch}';
    
    day.blocks.add(StudyBlock(
      id: newId,
      lessonId: lessonId,
      lessonName: lessonName,
      startHour: startHour,
      startMinute: 0,
      durationMinutes: pomodoroWorkMinutes,
      breakMinutes: pomodoroBreakMinutes,
      isPriority: false,
      activity: 'learn',
    ));
    
    // Saate göre sırala
    day.blocks.sort((a, b) => (a.startHour * 60 + a.startMinute).compareTo(b.startHour * 60 + b.startMinute));
    
    await saveSchedule(schedule);
  }

  /// Tercihlere göre program oluştur (Pomodoro bazlı)
  /// Aktivite ataması pedagojik kurallara göre:
  /// - Bir dersin günde 1. bloğu = Öğrenme (yeni konu)
  /// - Bir dersin günde 2. bloğu = Tekrar (pekiştirme)
  /// - Bir dersin günde 3+ bloğu = Uygulama (soru çözme)
  static WeeklySchedule generateSchedule(StudyPreferences prefs) {
    final List<DailySchedule> days = [];
    
    // Ders listesi
    final allLessons = lessonsData.map((l) => {
      'id': l['id'] as String,
      'name': l['name'] as String,
    }).toList();

    final priorityLessons = allLessons.where((l) => prefs.priorityLessons.contains(l['id'])).toList();
    final normalLessons = allLessons.where((l) => !prefs.priorityLessons.contains(l['id'])).toList();

    // Günlük toplam dakika
    final dailyMinutes = prefs.dailyHours * 60;
    
    // Bir pomodoro bloğu (çalışma + mola)
    final blockTotal = pomodoroWorkMinutes + pomodoroBreakMinutes; // 30dk
    
    // Günde kaç pomodoro sığar
    final blocksPerDay = (dailyMinutes / blockTotal).floor();

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final List<StudyBlock> blocks = [];

      if (!prefs.availableDays.contains(dayIndex)) {
        days.add(DailySchedule(dayIndex: dayIndex, blocks: []));
        continue;
      }

      int currentHour = prefs.startHour;
      int currentMinute = 0;
      int blockCount = 0;

      // Her ders için o gün kaç kez kullanıldığını takip et
      // Bu sayede pedagojik olarak doğru aktivite atanır
      final Map<String, int> lessonDailyCount = {};

      while (blockCount < blocksPerDay && currentHour < prefs.endHour) {
        // Ders seç
        Map<String, String> selectedLesson;
        bool isPriority = false;

        if (priorityLessons.isNotEmpty && blockCount % 3 != 2) {
          final pIndex = (dayIndex + blockCount) % priorityLessons.length;
          selectedLesson = priorityLessons[pIndex].cast<String, String>();
          isPriority = true;
        } else if (normalLessons.isNotEmpty) {
          final nIndex = (dayIndex + blockCount) % normalLessons.length;
          selectedLesson = normalLessons[nIndex].cast<String, String>();
        } else {
          final idx = (dayIndex + blockCount) % allLessons.length;
          selectedLesson = allLessons[idx].cast<String, String>();
        }

        // Bu dersin gündeki kaçıncı bloğu olduğunu bul
        final lessonId = selectedLesson['id']!;
        final lessonBlockNumber = (lessonDailyCount[lessonId] ?? 0) + 1;
        lessonDailyCount[lessonId] = lessonBlockNumber;

        // Pedagojik aktivite ataması:
        // 1. blok = Öğrenme (yeni konu)
        // 2. blok = Tekrar (pekiştirme)
        // 3+ blok = Uygulama (soru çözme)
        String activity;
        if (lessonBlockNumber == 1) {
          activity = 'learn';
        } else if (lessonBlockNumber == 2) {
          activity = 'review';
        } else {
          activity = 'practice';
        }
        
        // Her 4 blokta uzun mola
        final breakMins = (blockCount > 0 && blockCount % 4 == 0) 
            ? longBreakMinutes 
            : pomodoroBreakMinutes;

        blocks.add(StudyBlock(
          id: '${dayIndex}_$blockCount',
          lessonId: lessonId,
          lessonName: selectedLesson['name']!,
          startHour: currentHour,
          startMinute: currentMinute,
          durationMinutes: pomodoroWorkMinutes,
          breakMinutes: breakMins,
          isPriority: isPriority,
          activity: activity,
        ));

        // Sonraki blok için zaman hesapla
        currentMinute += pomodoroWorkMinutes + breakMins;
        while (currentMinute >= 60) {
          currentMinute -= 60;
          currentHour++;
        }
        
        blockCount++;
      }

      days.add(DailySchedule(dayIndex: dayIndex, blocks: blocks));
    }

    return WeeklySchedule(
      days: days,
      createdAt: DateTime.now(),
      preferences: prefs,
    );
  }

  /// Gün adları
  static String getDayName(int index) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[index];
  }

  static String getShortDayName(int index) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[index];
  }

  /// Ders renkleri
  static int getLessonColor(String lessonId) {
    final colors = [
      0xFF0EA5E9, // Sky
      0xFF10B981, // Emerald
      0xFFF59E0B, // Amber
      0xFFEF4444, // Red
      0xFF14B8A6, // Teal
      0xFF06B6D4, // Cyan
      0xFFEC4899, // Pink
      0xFF84CC16, // Lime
    ];
    return colors[lessonId.hashCode.abs() % colors.length];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HAZIR ŞABLONLAR (TEMPLATES)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hazır şablon listesi
  static List<ScheduleTemplate> get templates => [
    ScheduleTemplate(
      id: 'working-pro',
      name: 'Çalışan Aday',
      description: 'Akşam 19:00 - 23:00 arası yoğunlaştırılmış program',
      icon: '👨‍💼',
      preferences: StudyPreferences(
        dailyHours: 3,
        availableDays: [0, 1, 2, 3, 4], // Pzt-Cum
        startHour: 19,
        endHour: 23,
        priorityLessons: [],
      ),
    ),
    ScheduleTemplate(
      id: 'full-time',
      name: 'Full-Time Evde',
      description: 'Sabah 09:00 - 17:00 mesai simülasyonu',
      icon: '🏠',
      preferences: StudyPreferences(
        dailyHours: 6,
        availableDays: [0, 1, 2, 3, 4, 5], // Pzt-Cmt
        startHour: 9,
        endHour: 17,
        priorityLessons: [],
      ),
    ),
    ScheduleTemplate(
      id: 'weekend-camp',
      name: 'Hafta Sonu Kampı',
      description: 'Sadece Cumartesi-Pazar yoğun tekrar',
      icon: '🚀',
      preferences: StudyPreferences(
        dailyHours: 8,
        availableDays: [5, 6], // Cmt-Paz
        startHour: 9,
        endHour: 19,
        priorityLessons: [],
      ),
    ),
    ScheduleTemplate(
      id: 'rush-mode',
      name: 'Son 1 Ay (Rush Mode)',
      description: 'Full deneme ve nokta atışı tekrar',
      icon: '⚡',
      preferences: StudyPreferences(
        dailyHours: 8,
        availableDays: [0, 1, 2, 3, 4, 5, 6], // Her gün
        startHour: 8,
        endHour: 20,
        priorityLessons: [],
      ),
    ),
    ScheduleTemplate(
      id: 'student-mode',
      name: 'Üniversite Öğrencisi',
      description: 'Ders aralarında ve akşam çalışma',
      icon: '🎓',
      preferences: StudyPreferences(
        dailyHours: 4,
        availableDays: [0, 1, 2, 3, 4], // Pzt-Cum
        startHour: 14,
        endHour: 22,
        priorityLessons: [],
      ),
    ),
    ScheduleTemplate(
      id: 'morning-person',
      name: 'Sabahçı Program',
      description: 'Erken kalkıp 06:00 - 10:00 arası verimli çalışma',
      icon: '🌅',
      preferences: StudyPreferences(
        dailyHours: 3,
        availableDays: [0, 1, 2, 3, 4, 5], // Pzt-Cmt
        startHour: 6,
        endHour: 10,
        priorityLessons: [],
      ),
    ),
    ScheduleTemplate(
      id: 'light-mode',
      name: 'Hafif Tempo',
      description: 'Günde 2 saat, rahatlığınızı bozmadan',
      icon: '🌿',
      preferences: StudyPreferences(
        dailyHours: 2,
        availableDays: [0, 1, 2, 3, 4], // Pzt-Cum
        startHour: 20,
        endHour: 22,
        priorityLessons: [],
      ),
    ),
    ScheduleTemplate(
      id: 'mixed-schedule',
      name: 'Hibrit Çalışan',
      description: 'Öğle + Akşam karma program',
      icon: '🔄',
      preferences: StudyPreferences(
        dailyHours: 4,
        availableDays: [0, 1, 2, 3, 4, 5], // Pzt-Cmt
        startHour: 12,
        endHour: 22,
        priorityLessons: [],
      ),
    ),
  ];

  /// Şablondan program oluştur
  static WeeklySchedule generateFromTemplate(ScheduleTemplate template, List<String> priorityLessons) {
    final prefs = StudyPreferences(
      dailyHours: template.preferences.dailyHours,
      availableDays: template.preferences.availableDays,
      startHour: template.preferences.startHour,
      endHour: template.preferences.endHour,
      priorityLessons: priorityLessons,
    );
    return generateSchedule(prefs);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AKILLI TELAFİ (SMART RE-SCHEDULE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tamamlanmamış blokları sonraki günlere taşı
  static Future<int> rescheduleIncompleteBlocks(WeeklySchedule schedule) async {
    final now = DateTime.now();
    final todayIndex = (now.weekday - 1) % 7; // 0=Pazartesi

    List<StudyBlock> incompleteBlocks = [];

    // Bugünden önceki günlerdeki tamamlanmamış blokları topla
    for (int dayIndex = 0; dayIndex < todayIndex; dayIndex++) {
      final day = schedule.days[dayIndex];
      final incomplete = day.blocks.where((b) => !b.isCompleted).toList();
      incompleteBlocks.addAll(incomplete);
      // Orjinal günden sil
      day.blocks.removeWhere((b) => !b.isCompleted);
    }

    if (incompleteBlocks.isEmpty) return 0;

    int movedCount = 0;

    // Gelecekteki günlere dağıt
    for (int dayIndex = todayIndex; dayIndex < 7; dayIndex++) {
      if (incompleteBlocks.isEmpty) break;
      
      final day = schedule.days[dayIndex];
      final maxBlocks = schedule.preferences.dailyHours * 2; // saatBaşına 2 blok
      final availableSlots = maxBlocks - day.blocks.length;

      for (int i = 0; i < availableSlots && incompleteBlocks.isNotEmpty; i++) {
        final block = incompleteBlocks.removeAt(0);
        
        // Yeni saat hesapla (günün son bloğundan sonra)
        int newHour = schedule.preferences.startHour;
        if (day.blocks.isNotEmpty) {
          final lastBlock = day.blocks.last;
          newHour = lastBlock.startHour + 1;
          if (newHour >= schedule.preferences.endHour) continue;
        }

        day.blocks.add(StudyBlock(
          id: '${dayIndex}_reschedule_${DateTime.now().millisecondsSinceEpoch}_$movedCount',
          lessonId: block.lessonId,
          lessonName: block.lessonName,
          startHour: newHour,
          startMinute: 0,
          durationMinutes: block.durationMinutes,
          breakMinutes: block.breakMinutes,
          isPriority: block.isPriority,
          activity: block.activity,
          isCompleted: false,
        ));

        movedCount++;
      }

      // Saate göre sırala
      day.blocks.sort((a, b) => (a.startHour * 60 + a.startMinute).compareTo(b.startHour * 60 + b.startMinute));
    }

    await saveSchedule(schedule);
    return movedCount;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UYUMLULUK ANALİZİ (ANALYTICS)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Haftalık analiz verileri
  static ScheduleAnalytics getAnalytics(WeeklySchedule schedule) {
    final now = DateTime.now();
    final todayIndex = (now.weekday - 1) % 7;

    int totalBlocksUntilToday = 0;
    int completedBlocksUntilToday = 0;
    Map<String, int> lessonCounts = {};
    Map<String, int> lessonCompleted = {};
    int mostSkippedDayIndex = -1;
    int maxSkipped = 0;

    for (int dayIndex = 0; dayIndex <= todayIndex && dayIndex < schedule.days.length; dayIndex++) {
      final day = schedule.days[dayIndex];
      totalBlocksUntilToday += day.blocks.length;
      completedBlocksUntilToday += day.completedCount;

      final skipped = day.blocks.length - day.completedCount;
      if (skipped > maxSkipped) {
        maxSkipped = skipped;
        mostSkippedDayIndex = dayIndex;
      }

      for (final block in day.blocks) {
        lessonCounts[block.lessonName] = (lessonCounts[block.lessonName] ?? 0) + 1;
        if (block.isCompleted) {
          lessonCompleted[block.lessonName] = (lessonCompleted[block.lessonName] ?? 0) + 1;
        }
      }
    }

    // En çok atlanan ders
    String? mostSkippedLesson;
    int maxLessonSkip = 0;
    for (final lesson in lessonCounts.keys) {
      final total = lessonCounts[lesson]!;
      final completed = lessonCompleted[lesson] ?? 0;
      final skipped = total - completed;
      if (skipped > maxLessonSkip) {
        maxLessonSkip = skipped;
        mostSkippedLesson = lesson;
      }
    }

    final complianceRate = totalBlocksUntilToday > 0 
        ? (completedBlocksUntilToday / totalBlocksUntilToday * 100).round()
        : 0;

    return ScheduleAnalytics(
      totalBlocks: schedule.totalBlocks,
      completedBlocks: schedule.completedBlocks,
      totalBlocksUntilToday: totalBlocksUntilToday,
      completedBlocksUntilToday: completedBlocksUntilToday,
      complianceRate: complianceRate,
      mostSkippedLesson: mostSkippedLesson,
      mostSkippedDayIndex: mostSkippedDayIndex,
      lessonBreakdown: lessonCounts,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAKVİM ENTEGRASYONU (CALENDAR SYNC)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tüm programı takvime ekle
  static Future<int> exportToCalendar(WeeklySchedule schedule) async {
    // add_2_calendar paketini dinamik import
    // ignore: depend_on_referenced_packages
    final add2Calendar = await _getAdd2CalendarInstance();
    if (add2Calendar == null) return 0;

    int addedCount = 0;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    for (final day in schedule.days) {
      final date = monday.add(Duration(days: day.dayIndex));
      
      for (final block in day.blocks) {
        final startTime = DateTime(
          date.year, date.month, date.day,
          block.startHour, block.startMinute,
        );
        final endTime = startTime.add(Duration(minutes: block.durationMinutes));

        final event = CalendarEvent(
          title: '📚 ${block.lessonName}',
          description: '${block.activityName} - ${block.durationMinutes} dakika\nKPSS Asistan Ders Programı',
          location: 'Çalışma',
          startDate: startTime,
          endDate: endTime,
        );

        // Her bloğu takvime ekle
        try {
          await add2Calendar(event);
          addedCount++;
        } catch (_) {
          // Kullanıcı iptal etti veya hata
        }
      }
    }

    return addedCount;
  }

  /// Tek bir günü takvime ekle
  static Future<int> exportDayToCalendar(WeeklySchedule schedule, int dayIndex) async {
    final add2Calendar = await _getAdd2CalendarInstance();
    if (add2Calendar == null) return 0;

    int addedCount = 0;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final date = monday.add(Duration(days: dayIndex));
    final day = schedule.days[dayIndex];

    for (final block in day.blocks) {
      final startTime = DateTime(
        date.year, date.month, date.day,
        block.startHour, block.startMinute,
      );
      final endTime = startTime.add(Duration(minutes: block.durationMinutes));

      final event = CalendarEvent(
        title: '📚 ${block.lessonName}',
        description: '${block.activityName} - ${block.durationMinutes} dakika',
        location: 'Çalışma',
        startDate: startTime,
        endDate: endTime,
      );

      try {
        await add2Calendar(event);
        addedCount++;
      } catch (_) {}
    }

    return addedCount;
  }

  // Helper - add_2_calendar lazy import
  static Future<Function(CalendarEvent)?> _getAdd2CalendarInstance() async {
    try {
      // Bu metod takvim ekleme işlemini tetikler
      return (CalendarEvent event) async {
        // Platform check ve add_2_calendar kullanımı UI tarafında yapılacak
        // Şimdilik stub olarak bırakıyoruz
      };
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF ÇIKTI (EXPORT TO PDF)
  // ═══════════════════════════════════════════════════════════════════════════

  /// PDF için program verilerini hazırla (UI tarafında pdf paketi ile render edilecek)
  static Map<String, dynamic> preparePdfData(WeeklySchedule schedule) {
    final List<Map<String, dynamic>> daysData = [];

    for (final day in schedule.days) {
      final List<Map<String, dynamic>> blocksData = [];
      
      for (final block in day.blocks) {
        blocksData.add({
          'time': block.timeRange,
          'lesson': block.lessonName,
          'activity': block.activityName,
          'isPriority': block.isPriority,
          'duration': block.durationMinutes,
        });
      }

      daysData.add({
        'dayName': getDayName(day.dayIndex),
        'shortName': getShortDayName(day.dayIndex),
        'blocks': blocksData,
        'totalMinutes': day.totalMinutes,
        'blockCount': day.blocks.length,
      });
    }

    return {
      'title': 'KPSS Ders Programı',
      'createdAt': schedule.createdAt.toIso8601String(),
      'totalBlocks': schedule.totalBlocks,
      'activeDays': schedule.activeDaysCount,
      'weeklyHours': (schedule.totalWeeklyMinutes / 60).toStringAsFixed(1),
      'days': daysData,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EK MODELLER
// ═══════════════════════════════════════════════════════════════════════════

/// Şablon modeli
class ScheduleTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final StudyPreferences preferences;

  const ScheduleTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.preferences,
  });
}

/// Analiz sonuç modeli
class ScheduleAnalytics {
  final int totalBlocks;
  final int completedBlocks;
  final int totalBlocksUntilToday;
  final int completedBlocksUntilToday;
  final int complianceRate; // 0-100
  final String? mostSkippedLesson;
  final int mostSkippedDayIndex;
  final Map<String, int> lessonBreakdown;

  const ScheduleAnalytics({
    required this.totalBlocks,
    required this.completedBlocks,
    required this.totalBlocksUntilToday,
    required this.completedBlocksUntilToday,
    required this.complianceRate,
    required this.mostSkippedLesson,
    required this.mostSkippedDayIndex,
    required this.lessonBreakdown,
  });

  String get complianceMessage {
    // Yeni başlayanlar için özel mesaj
    if (totalBlocksUntilToday == 0) {
      return 'Programın yeni başladı, hadi ilk dersleri tamamla! 🚀';
    }
    // Hiç tamamlanmadıysa ama dersler varsa
    if (completedBlocksUntilToday == 0 && totalBlocksUntilToday > 0) {
      return 'Henüz hiç ders tamamlanmadı, başlama zamanı! 💡';
    }
    if (complianceRate >= 90) return 'Mükemmel! Programa harika uyuyorsun 🔥';
    if (complianceRate >= 70) return 'İyi gidiyorsun, biraz daha gayret! 💪';
    if (complianceRate >= 50) return 'Ortalama, programı gözden geçir 🤔';
    if (complianceRate >= 25) return 'Biraz zorlanıyorsun, hedef küçült 📉';
    return 'Dikkat! Program çok zorlanıyor 😟';
  }
}

/// Takvim etkinlik modeli (add_2_calendar ile uyumlu)
class CalendarEvent {
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime endDate;

  const CalendarEvent({
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
  });
}
