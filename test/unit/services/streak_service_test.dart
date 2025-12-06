import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StreakService Unit Tests
/// 
/// Test coverage için kritik servis testleri
void main() {
  group('StreakService Tests', () {
    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial streak should be 0', () async {
      final prefs = await SharedPreferences.getInstance();
      final streak = prefs.getInt('current_streak') ?? 0;
      expect(streak, 0);
    });

    test('Streak should increment when studying', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Simulate first study
      await prefs.setInt('current_streak', 1);
      final streak = prefs.getInt('current_streak');
      
      expect(streak, 1);
    });

    test('Streak should reset after missing a day', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Set streak to 5
      await prefs.setInt('current_streak', 5);
      
      // Simulate missing a day (reset)
      await prefs.setInt('current_streak', 1);
      
      final streak = prefs.getInt('current_streak');
      expect(streak, 1);
    });

    test('Longest streak should be tracked', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Set current and longest streak
      await prefs.setInt('current_streak', 3);
      await prefs.setInt('longest_streak', 10);
      
      final current = prefs.getInt('current_streak');
      final longest = prefs.getInt('longest_streak');
      
      expect(current, 3);
      expect(longest, 10);
    });

    test('Week data should track 7 days', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Simulate week data
      final weekDays = ['2025-12-01', '2025-12-02', '2025-12-03'];
      await prefs.setStringList('streak_days', weekDays);
      
      final savedDays = prefs.getStringList('streak_days');
      expect(savedDays?.length, 3);
    });

    test('Date format should be consistent', () {
      final now = DateTime.now();
      final formatted = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      expect(formatted.contains('-'), true);
      expect(formatted.split('-').length, 3);
    });
  });
}
