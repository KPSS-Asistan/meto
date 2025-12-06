import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Firebase'den verileri export edip Dart kodu olarak gösterir
/// Bu sayfa sadece geliştirme amaçlıdır, production'da kullanılmaz
class FirebaseExportPage extends StatefulWidget {
  const FirebaseExportPage({super.key});

  @override
  State<FirebaseExportPage> createState() => _FirebaseExportPageState();
}

class _FirebaseExportPageState extends State<FirebaseExportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _output = '';
  bool _isLoading = false;
  String _currentTask = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Export'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _output.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _output));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kopyalandı!')),
                    );
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Butonlar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportQuestions,
                  icon: const Icon(Icons.quiz),
                  label: const Text('Soruları Export Et'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportFlashcards,
                  icon: const Icon(Icons.style),
                  label: const Text('Flashcards Export Et'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportTopics,
                  icon: const Icon(Icons.topic),
                  label: const Text('Konuları Export Et'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportLessons,
                  icon: const Icon(Icons.book),
                  label: const Text('Dersleri Export Et'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportMatchingGames,
                  icon: const Icon(Icons.games),
                  label: const Text('Eşleştirmeleri Export Et'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportAll,
                  icon: const Icon(Icons.download),
                  label: const Text('Tümünü Export Et'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(_currentTask),
                ],
              ),
            ),
          // Output
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _output.isEmpty ? 'Export sonucu burada görünecek...' : _output,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportQuestions() async {
    setState(() {
      _isLoading = true;
      _currentTask = 'Sorular yükleniyor...';
      _output = '';
    });

    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('is_deleted', isEqualTo: false)
          .get();

      // Konu bazlı grupla
      final Map<String, List<Map<String, dynamic>>> questionsByTopic = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final topicId = data['topic_id'] ?? data['topicId'] ?? '';
        
        if (topicId.isEmpty) continue;

        questionsByTopic.putIfAbsent(topicId, () => []).add({
          'id': doc.id,
          ...data,
        });
      }

      // Dart kodu oluştur
      final buffer = StringBuffer();
      buffer.writeln('// ═══════════════════════════════════════════════════════════════');
      buffer.writeln('// FIREBASE EXPORT - SORULAR');
      buffer.writeln('// Toplam: ${snapshot.docs.length} soru, ${questionsByTopic.length} konu');
      buffer.writeln('// Tarih: ${DateTime.now()}');
      buffer.writeln('// ═══════════════════════════════════════════════════════════════');
      buffer.writeln();

      for (final entry in questionsByTopic.entries) {
        final topicId = entry.key;
        final questions = entry.value;

        buffer.writeln('// ─────────────────────────────────────────────────────────────────');
        buffer.writeln('// Topic ID: $topicId');
        buffer.writeln('// Soru Sayısı: ${questions.length}');
        buffer.writeln('// ─────────────────────────────────────────────────────────────────');
        buffer.writeln();
        buffer.writeln('const List<Map<String, dynamic>> questions_$topicId = [');

        for (final q in questions) {
          buffer.writeln('  {');
          buffer.writeln("    'id': '${q['id']}',");
          buffer.writeln("    'questionText': '''${_escapeString(q['question_text'] ?? q['questionText'] ?? '')}''',");
          
          // Options
          final options = q['options'] as Map<String, dynamic>?;
          if (options != null) {
            buffer.writeln("    'options': {");
            for (final opt in options.entries) {
              buffer.writeln("      '${opt.key}': '''${_escapeString(opt.value.toString())}''',");
            }
            buffer.writeln("    },");
          }
          
          buffer.writeln("    'correctAnswer': '${q['correct_answer'] ?? q['correctAnswer'] ?? ''}',");
          buffer.writeln("    'explanation': '''${_escapeString(q['explanation'] ?? '')}''',");
          buffer.writeln('  },');
        }

        buffer.writeln('];');
        buffer.writeln();
      }

      setState(() {
        _output = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _output = 'HATA: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportFlashcards() async {
    setState(() {
      _isLoading = true;
      _currentTask = 'Flashcards yükleniyor...';
      _output = '';
    });

    try {
      final snapshot = await _firestore.collection('flashcards').get();

      // Konu bazlı grupla
      final Map<String, List<Map<String, dynamic>>> cardsByTopic = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final topicId = data['topic_id'] ?? data['topicId'] ?? '';
        final isDeleted = data['is_deleted'] ?? data['isDeleted'] ?? false;
        
        if (topicId.isEmpty || isDeleted) continue;

        cardsByTopic.putIfAbsent(topicId, () => []).add({
          'id': doc.id,
          ...data,
        });
      }

      // Dart kodu oluştur
      final buffer = StringBuffer();
      buffer.writeln('// ═══════════════════════════════════════════════════════════════');
      buffer.writeln('// FIREBASE EXPORT - FLASHCARDS');
      buffer.writeln('// Toplam: ${snapshot.docs.length} kart, ${cardsByTopic.length} konu');
      buffer.writeln('// Tarih: ${DateTime.now()}');
      buffer.writeln('// ═══════════════════════════════════════════════════════════════');
      buffer.writeln();

      for (final entry in cardsByTopic.entries) {
        final topicId = entry.key;
        final cards = entry.value;

        buffer.writeln('// ─────────────────────────────────────────────────────────────────');
        buffer.writeln('// Topic ID: $topicId');
        buffer.writeln('// Kart Sayısı: ${cards.length}');
        buffer.writeln('// ─────────────────────────────────────────────────────────────────');
        buffer.writeln();
        buffer.writeln('const List<Map<String, dynamic>> flashcards_$topicId = [');

        for (final card in cards) {
          final question = card['question'] ?? card['front'] ?? card['on_yuz'] ?? card['soru'] ?? '';
          final answer = card['answer'] ?? card['back'] ?? card['arka_yuz'] ?? card['cevap'] ?? '';
          final additionalInfo = card['additional_info'] ?? card['explanation'] ?? card['aciklama'];

          buffer.writeln('  {');
          buffer.writeln("    'id': '${card['id']}',");
          buffer.writeln("    'question': '''${_escapeString(question)}''',");
          buffer.writeln("    'answer': '''${_escapeString(answer)}''',");
          if (additionalInfo != null && additionalInfo.toString().isNotEmpty) {
            buffer.writeln("    'additionalInfo': '''${_escapeString(additionalInfo.toString())}''',");
          }
          buffer.writeln('  },');
        }

        buffer.writeln('];');
        buffer.writeln();
      }

      setState(() {
        _output = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _output = 'HATA: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportTopics() async {
    setState(() {
      _isLoading = true;
      _currentTask = 'Konular yükleniyor...';
      _output = '';
    });

    try {
      final snapshot = await _firestore.collection('topics').get();

      final buffer = StringBuffer();
      buffer.writeln('// ═══════════════════════════════════════════════════════════════');
      buffer.writeln('// FIREBASE EXPORT - KONULAR');
      buffer.writeln('// Toplam: ${snapshot.docs.length} konu');
      buffer.writeln('// Tarih: ${DateTime.now()}');
      buffer.writeln('// ═══════════════════════════════════════════════════════════════');
      buffer.writeln();
      buffer.writeln('const List<Map<String, dynamic>> allTopics = [');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        buffer.writeln('  {');
        buffer.writeln("    'id': '${doc.id}',");
        buffer.writeln("    'name': '''${_escapeString(data['name'] ?? '')}''',");
        buffer.writeln("    'lessonId': '${data['lesson_id'] ?? data['lessonId'] ?? ''}',");
        buffer.writeln("    'order': ${data['order'] ?? 0},");
        buffer.writeln("    'description': '''${_escapeString(data['description'] ?? '')}''',");
        buffer.writeln('  },');
      }

      buffer.writeln('];');

      setState(() {
        _output = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _output = 'HATA: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportLessons() async {
    setState(() {
      _isLoading = true;
      _currentTask = 'Dersler yükleniyor...';
      _output = '';
    });

    try {
      final snapshot = await _firestore.collection('lessons').get();

      final buffer = StringBuffer();
      buffer.writeln('// ═══════════════════════════════════════════════════════════════');
      buffer.writeln('// FIREBASE EXPORT - DERSLER');
      buffer.writeln('// Toplam: ${snapshot.docs.length} ders');
      buffer.writeln('// Tarih: ${DateTime.now()}');
      buffer.writeln('// ═══════════════════════════════════════════════════════════════');
      buffer.writeln();
      buffer.writeln('const List<Map<String, dynamic>> allLessons = [');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        buffer.writeln('  {');
        buffer.writeln("    'id': '${doc.id}',");
        buffer.writeln("    'name': '''${_escapeString(data['name'] ?? '')}''',");
        buffer.writeln("    'icon': '${data['icon'] ?? ''}',");
        buffer.writeln("    'color': '${data['color'] ?? ''}',");
        buffer.writeln("    'order': ${data['order'] ?? 0},");
        buffer.writeln('  },');
      }

      buffer.writeln('];');

      setState(() {
        _output = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _output = 'HATA: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportMatchingGames() async {
    setState(() {
      _isLoading = true;
      _currentTask = 'Eşleştirmeler yükleniyor...';
      _output = '';
    });

    try {
      final snapshot = await _firestore.collection('matching_games').get();

      // Konu bazlı grupla
      final Map<String, List<Map<String, dynamic>>> gamesByTopic = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final topicId = data['topic_id'] ?? data['topicId'] ?? '';
        
        if (topicId.isEmpty) continue;

        gamesByTopic.putIfAbsent(topicId, () => []).add({
          'id': doc.id,
          ...data,
        });
      }

      final buffer = StringBuffer();
      buffer.writeln('// ═══════════════════════════════════════════════════════════════');
      buffer.writeln('// FIREBASE EXPORT - EŞLEŞTİRME OYUNLARI');
      buffer.writeln('// Toplam: ${snapshot.docs.length} çift, ${gamesByTopic.length} konu');
      buffer.writeln('// Tarih: ${DateTime.now()}');
      buffer.writeln('// ═══════════════════════════════════════════════════════════════');
      buffer.writeln();

      for (final entry in gamesByTopic.entries) {
        final topicId = entry.key;
        final games = entry.value;

        buffer.writeln('// ─────────────────────────────────────────────────────────────────');
        buffer.writeln('// Topic ID: $topicId');
        buffer.writeln('// Çift Sayısı: ${games.length}');
        buffer.writeln('// ─────────────────────────────────────────────────────────────────');
        buffer.writeln();
        buffer.writeln('const List<Map<String, String>> matching_$topicId = [');

        for (final game in games) {
          final question = game['question'] ?? game['term'] ?? game['kavram'] ?? '';
          final answer = game['answer'] ?? game['definition'] ?? game['tanim'] ?? '';

          buffer.writeln('  {');
          buffer.writeln("    'question': '''${_escapeString(question)}''',");
          buffer.writeln("    'answer': '''${_escapeString(answer)}''',");
          buffer.writeln('  },');
        }

        buffer.writeln('];');
        buffer.writeln();
      }

      setState(() {
        _output = buffer.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _output = 'HATA: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportAll() async {
    setState(() {
      _isLoading = true;
      _output = '';
    });

    final buffer = StringBuffer();

    // Dersler
    setState(() => _currentTask = 'Dersler yükleniyor...');
    await _exportLessons();
    buffer.writeln(_output);
    buffer.writeln('\n\n');

    // Konular
    setState(() => _currentTask = 'Konular yükleniyor...');
    await _exportTopics();
    buffer.writeln(_output);
    buffer.writeln('\n\n');

    // Sorular
    setState(() => _currentTask = 'Sorular yükleniyor...');
    await _exportQuestions();
    buffer.writeln(_output);
    buffer.writeln('\n\n');

    // Flashcards
    setState(() => _currentTask = 'Flashcards yükleniyor...');
    await _exportFlashcards();
    buffer.writeln(_output);
    buffer.writeln('\n\n');

    // Eşleştirmeler
    setState(() => _currentTask = 'Eşleştirmeler yükleniyor...');
    await _exportMatchingGames();
    buffer.writeln(_output);

    setState(() {
      _output = buffer.toString();
      _isLoading = false;
    });
  }

  String _escapeString(String input) {
    return input
        .replaceAll("'''", "' ' '")
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
  }
}
