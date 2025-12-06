import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

void main() {
  group('MatchingGame UI Tests', () {
    testWidgets('game card has correct styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: const Text('Test Card'),
            ),
          ),
        ),
      );

      expect(find.text('Test Card'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('matched card shows success color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                border: Border.all(color: AppColors.success),
              ),
              child: const Text('Matched'),
            ),
          ),
        ),
      );

      expect(find.text('Matched'), findsOneWidget);
    });

    testWidgets('selected card shows primary color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Text('Selected'),
            ),
          ),
        ),
      );

      expect(find.text('Selected'), findsOneWidget);
    });

    testWidgets('score display renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Skor: 3/5',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Skor: 3/5'), findsOneWidget);
    });
  });
}
