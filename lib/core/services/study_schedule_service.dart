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

    // Aktivite döngüsü
    final activities = ['learn', 'learn', 'review', 'practice'];

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final List<StudyBlock> blocks = [];

      if (!prefs.availableDays.contains(dayIndex)) {
        days.add(DailySchedule(dayIndex: dayIndex, blocks: []));
        continue;
      }

      int currentHour = prefs.startHour;
      int currentMinute = 0;
      int blockCount = 0;

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

        final activity = activities[(dayIndex + blockCount) % activities.length];
        
        // Her 4 blokta uzun mola
        final breakMins = (blockCount > 0 && blockCount % 4 == 0) 
            ? longBreakMinutes 
            : pomodoroBreakMinutes;

        blocks.add(StudyBlock(
          id: '${dayIndex}_$blockCount',
          lessonId: selectedLesson['id']!,
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
}
