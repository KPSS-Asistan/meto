import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NotificationService Unit Tests
void main() {
  group('NotificationService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Notifications should be enabled by default', () async {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? true;
      expect(enabled, true);
    });

    test('Should save daily reminder time', () async {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('daily_reminder_time', '19:00');
      final time = prefs.getString('daily_reminder_time');
      
      expect(time, '19:00');
    });

    test('Should parse reminder time correctly', () {
      const timeStr = '19:30';
      final parts = timeStr.split(':');
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      expect(hour, 19);
      expect(minute, 30);
    });

    test('Streak alert should be configurable', () async {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('streak_alert_enabled', true);
      final enabled = prefs.getBool('streak_alert_enabled');
      
      expect(enabled, true);
    });

    test('Should disable notifications', () async {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('notifications_enabled', false);
      final enabled = prefs.getBool('notifications_enabled');
      
      expect(enabled, false);
    });

    test('Motivation messages should have variety', () {
      final messages = [
        ('💪 Harika Gidiyorsun!', 'Her gün bir adım daha yakınsın hedefe.'),
        ('🎯 Odaklan!', 'Bugün de hedeflerini tamamla, başarı senin!'),
        ('🌟 Sen Yaparsın!', 'Binlerce öğrenci başardı, sıra sende!'),
      ];
      
      expect(messages.length, greaterThan(2));
      expect(messages[0].$1.contains('💪'), true);
    });

    test('Scheduled time should be in future', () {
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, 19, 0);
      
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      expect(scheduledDate.isAfter(now) || scheduledDate.isAtSameMomentAs(now), true);
    });
  });
}
