import 'package:dartz/dartz.dart';
import 'package:kpss_2026/core/data/flashcards_data.dart';
import 'package:kpss_2026/core/data/topics_data.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/entities/flashcard_set.dart';
import '../../domain/repositories/flashcard_repository.dart';

/// ⚡ HARDCODED ONLY - Firebase bağımlılığı kaldırıldı
class FirebaseFlashcardRepository implements FlashcardRepository {
  FirebaseFlashcardRepository();

  @override
  Future<Either<String, FlashcardSet>> getFlashcardSetByTopicId(
      String topicId) async {
    // Hardcoded data'dan al
    final flashcardsRaw = getFlashcardsForTopic(topicId);
    
    if (flashcardsRaw == null || flashcardsRaw.isEmpty) {
      return const Left('Bu konu için flashcard bulunamadı');
    }

    // Topic adını al
    final topicName = _getTopicName(topicId);

    // Parse flashcards
    final cards = flashcardsRaw.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      return Flashcard(
        id: '${topicId}_$index',
        question: data['question'] ?? '',
        answer: data['answer'] ?? '',
        additionalInfo: data['additionalInfo'],
        imageUrl: null,
      );
    }).toList();

    // Shuffle for variety
    cards.shuffle();

    final flashcardSet = FlashcardSet(
      id: topicId,
      topicId: topicId,
      topicName: topicName,
      cards: cards,
      totalCards: cards.length,
    );

    return Right(flashcardSet);
  }

  @override
  Future<Either<String, List<FlashcardSet>>> getAllFlashcardSets() async {
    final sets = <FlashcardSet>[];
    
    for (final topicId in getAllFlashcardTopicIds()) {
      final result = await getFlashcardSetByTopicId(topicId);
      result.fold(
        (error) => {}, // Skip topics with no flashcards
        (set) => sets.add(set),
      );
    }

    return Right(sets);
  }
  
  /// Topic adını al
  String _getTopicName(String topicId) {
    for (final topic in topicsData) {
      if (topic['id'] == topicId) {
        return topic['name'] as String? ?? 'Konu';
      }
    }
    return 'Konu';
  }
}
