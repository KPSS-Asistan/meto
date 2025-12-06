import 'package:flutter/material.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import 'package:kpss_2026/core/data/questions_data.dart';
import 'package:kpss_2026/core/data/topics_data.dart';
import 'package:kpss_2026/features/dev_tools/firebase_export_page.dart';
import 'package:go_router/go_router.dart';

/// Development için debug tools sayfası
/// Production'da bu sayfa erişilemez olmalı
class DevToolsPage extends StatefulWidget {
  const DevToolsPage({super.key});

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  String _statusMessage = '';

  void _checkQuestionCounts() {
    final buffer = StringBuffer();
    buffer.writeln('📊 HARDCODED SORU İSTATİSTİKLERİ:\n');

    // Derslere göre grupla
    final lessonGroups = <String, List<Map<String, dynamic>>>{};
    for (final topic in topicsData) {
      final lessonId = topic['lessonId'] as String;
      lessonGroups.putIfAbsent(lessonId, () => []).add(topic);
    }

    for (final entry in lessonGroups.entries) {
      final lessonName = entry.value.first['lessonName'] ?? entry.key;
      buffer.writeln('📚 $lessonName');
      
      for (final topic in entry.value) {
        final topicId = topic['id'] as String;
        final topicName = topic['name'] as String;
        final count = QuestionsData.getQuestionCount(topicId);
        buffer.writeln('  └─ $topicName: $count soru');
      }
      buffer.writeln();
    }

    setState(() {
      _statusMessage = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🛠️ Developer Tools'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bu sayfa sadece geliştirme amaçlıdır. Production\'da erişilemez olmalıdır.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Hardcoded Data Stats
                  const Text(
                    'Hardcoded Veri İstatistikleri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _ActionButton(
                    icon: Icons.analytics_rounded,
                    label: 'Soru Sayılarını Kontrol Et',
                    description: 'Her topic için hardcoded soru sayısını görüntüler',
                    color: Colors.blue,
                    onPressed: _checkQuestionCounts,
                  ),

                  const SizedBox(height: 32),

                  // UI Tests
                  const Text(
                    'UI Testleri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _ActionButton(
                    icon: Icons.quiz_rounded,
                    label: 'Hardcoded Quiz Sayfası',
                    description: 'Statik quiz sayfası tasarımı',
                    color: Colors.purple,
                    onPressed: () => context.push('/quiz-hardcoded'),
                  ),

                  const SizedBox(height: 32),

                  // Firebase Export
                  const Text(
                    'Firebase Export',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _ActionButton(
                    icon: Icons.download_rounded,
                    label: 'Firebase Verilerini Export Et',
                    description: 'Sorular, flashcards, konular vb. Dart koduna çevir',
                    color: Colors.teal,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FirebaseExportPage(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Status
                  if (_statusMessage.isNotEmpty) ...[
                    const Text(
                      'Durum',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}


class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
