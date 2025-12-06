import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpss_2026/core/widgets/theme_aware_header.dart';

void main() {
  group('ThemeAwareHeader Widget Tests', () {
    testWidgets('displays title correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThemeAwareHeader(
              title: 'Test Title',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThemeAwareHeader(
              title: 'Test Title',
              subtitle: 'Test Subtitle',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('renders without crashing when onClose provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeAwareHeader(
              title: 'Test',
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('displays actions when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThemeAwareHeader(
              title: 'Test',
              actions: [Icon(Icons.settings)],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });

  group('Common Widget Behaviors', () {
    testWidgets('handles light theme correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: ThemeAwareHeader(
              title: 'Light Theme Test',
            ),
          ),
        ),
      );

      expect(find.text('Light Theme Test'), findsOneWidget);
    });

    testWidgets('handles dark theme correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ThemeAwareHeader(
              title: 'Dark Theme Test',
            ),
          ),
        ),
      );

      expect(find.text('Dark Theme Test'), findsOneWidget);
    });
  });
}
