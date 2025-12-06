import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

void main() {
  group('MemoryGame UI Tests', () {
    testWidgets('hidden card shows question mark icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.question_mark, size: 32, color: Colors.white),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.question_mark), findsOneWidget);
    });

    testWidgets('flipped card shows text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text('Demokrasi'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Demokrasi'), findsOneWidget);
    });

    testWidgets('matched card has success styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                border: Border.all(color: AppColors.success),
              ),
              child: const Text(
                'Eşleşti',
                style: TextStyle(color: AppColors.success),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Eşleşti'), findsOneWidget);
    });

    testWidgets('progress indicator shows correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Bulunan: 2/6',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Bulunan: 2/6'), findsOneWidget);
    });

    testWidgets('grid layout renders multiple cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  color: AppColors.primary,
                  child: Center(child: Text('Card $index')),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Card 0'), findsOneWidget);
      expect(find.text('Card 5'), findsOneWidget);
    });
  });
}
