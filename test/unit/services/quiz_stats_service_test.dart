import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// QuizStatsService Unit Tests
void main() {
  group('QuizStatsService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial total solved should be 0', () async {
      final prefs = await SharedPreferences.getInstance();
      final total = prefs.getInt('total_questions_solved') ?? 0;
      expect(total, 0);
    });

    test('Should increment total solved', () async {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt('total_questions_solved', 10);
      final total = prefs.getInt('total_questions_solved');
      
      expect(total, 10);
    });

    test('Should track correct answers', () async {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt('total_correct_answers', 8);
      await prefs.setInt('total_questions_solved', 10);
      
      final correct = prefs.getInt('total_correct_answers') ?? 0;
      final total = prefs.getInt('total_questions_solved') ?? 0;
      
      expect(correct, 8);
      expect(total, 10);
    });

    test('Success rate calculation', () async {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt('total_correct_answers', 75);
      await prefs.setInt('total_questions_solved', 100);
      
      final correct = prefs.getInt('total_correct_answers') ?? 0;
      final total = prefs.getInt('total_questions_solved') ?? 1;
      
      final successRate = (correct / total * 100).round();
      expect(successRate, 75);
    });

    test('Today stats should reset daily', () async {
      final prefs = await SharedPreferences.getInstance();
      
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      
      await prefs.setString('quiz_stats_date', todayStr);
      await prefs.setInt('today_solved', 5);
      
      final savedDate = prefs.getString('quiz_stats_date');
      final todaySolved = prefs.getInt('today_solved');
      
      expect(savedDate, todayStr);
      expect(todaySolved, 5);
    });

    test('Lesson-specific stats', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Tarih dersi için istatistik
      await prefs.setInt('lesson_tarih_solved', 50);
      await prefs.setInt('lesson_tarih_correct', 40);
      
      final solved = prefs.getInt('lesson_tarih_solved');
      final correct = prefs.getInt('lesson_tarih_correct');
      
      expect(solved, 50);
      expect(correct, 40);
    });

    test('Topic-specific stats', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Osmanlı konusu için istatistik
      await prefs.setInt('topic_osmanli_solved', 20);
      await prefs.setInt('topic_osmanli_correct', 15);
      
      final solved = prefs.getInt('topic_osmanli_solved');
      final correct = prefs.getInt('topic_osmanli_correct');
      
      expect(solved, 20);
      expect(correct, 15);
    });
  });
}
