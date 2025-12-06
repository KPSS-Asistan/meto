import 'package:dartz/dartz.dart';
import '../entities/flashcard_set.dart';

abstract class FlashcardRepository {
  Future<Either<String, FlashcardSet>> getFlashcardSetByTopicId(String topicId);
  Future<Either<String, List<FlashcardSet>>> getAllFlashcardSets();
}
