import 'package:dartz/dartz.dart';
import 'package:kpss_2026/core/data/flashcards_data.dart';
import 'package:kpss_2026/core/data/topics_data.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/entities/flashcard_set.dart';
import '../../domain/repositories/flashcard_repository.dart';

/// Hardcoded Flashcard Repository
/// Firebase'e bağımlılık yok - Anında yüklenir
/// ⚡ PERFORMANS: 0ms latency, offline çalışır
/// ⚡ LAZY LOADING: Sadece istendiğinde parse edilir
class HardcodedFlashcardRepository implements FlashcardRepository {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LAZY CACHE - Parse edilmiş flashcard setleri
  // ═══════════════════════════════════════════════════════════════════════════
  static final Map<String, FlashcardSet> _cache = {};
  static Map<String, String>? _topicNameCache;
  
  /// Topic adlarını lazy cache'le
  Map<String, String> get _topicNames {
    _topicNameCache ??= {
      for (final topic in topicsData)
        topic['id'] as String: topic['name'] as String? ?? 'Konu'
    };
    return _topicNameCache!;
  }
  
  @override
  Future<Either<String, FlashcardSet>> getFlashcardSetByTopicId(String topicId) async {
    // ⚡ CACHE HIT: Daha önce parse edildiyse direkt dön
    if (_cache.containsKey(topicId)) {
      // Kartları tekrar karıştır
      final cached = _cache[topicId]!;
      final shuffledCards = List<Flashcard>.from(cached.cards)..shuffle();
      return Right(cached.copyWith(cards: shuffledCards));
    }
    
    // Hardcoded data'dan al
    final flashcardsRaw = getFlashcardsForTopic(topicId);
    
    if (flashcardsRaw == null || flashcardsRaw.isEmpty) {
      return const Left('Bu konu için flashcard bulunamadı');
    }
    
    // Topic adını lazy cache'den al
    final topicName = _topicNames[topicId] ?? 'Konu';
    
    // Flashcard'ları parse et (LAZY - sadece ilk erişimde)
    final cards = <Flashcard>[];
    for (var i = 0; i < flashcardsRaw.length; i++) {
      final data = flashcardsRaw[i];
      cards.add(Flashcard(
        id: '${topicId}_$i',
        question: data['question'] ?? '',
        answer: data['answer'] ?? '',
        additionalInfo: data['additionalInfo'],
      ));
    }
    
    final flashcardSet = FlashcardSet(
      id: topicId,
      topicId: topicId,
      topicName: topicName,
      cards: cards,
      totalCards: cards.length,
    );
    
    // ⚡ CACHE'E KAYDET
    _cache[topicId] = flashcardSet;
    
    // Karıştırılmış kopyasını dön
    final shuffledCards = List<Flashcard>.from(cards)..shuffle();
    return Right(flashcardSet.copyWith(cards: shuffledCards));
  }
  
  @override
  Future<Either<String, List<FlashcardSet>>> getAllFlashcardSets() async {
    final sets = <FlashcardSet>[];
    
    // ⚡ SADECE DOLU OLAN TOPIC'LERİ AL (boş şablonları atla)
    for (final topicId in getAllFlashcardTopicIds()) {
      // Önce count'a bak - 0 ise atla
      if (getFlashcardCount(topicId) == 0) continue;
      
      final result = await getFlashcardSetByTopicId(topicId);
      result.fold(
        (error) {}, // Skip errors
        (set) => sets.add(set),
      );
    }
    
    if (sets.isEmpty) {
      return const Left('Hiç flashcard seti bulunamadı');
    }
    
    return Right(sets);
  }
  
  /// Cache'i temizle (test için)
  static void clearCache() {
    _cache.clear();
    _topicNameCache = null;
  }
  
  /// Flashcard sayısını al (parse etmeden)
  int getCount(String topicId) => getFlashcardCount(topicId);
  
  /// Toplam flashcard sayısı
  int get totalCount => getTotalFlashcardCount();
  
  /// Dolu topic sayısı
  int get topicCount => getAllFlashcardTopicIds()
      .where((id) => getFlashcardCount(id) > 0)
      .length;
}
