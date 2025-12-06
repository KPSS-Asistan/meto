import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kpss_2026/core/utils/app_logger.dart';
import 'package:kpss_2026/core/services/streak_service.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/entities/flashcard_set.dart';
import '../../data/repositories/flashcard_progress_repository.dart';
import 'flashcard_state.dart';

/// Flashcard Cubit - Leitner System ile state management
class FlashcardCubit extends Cubit<FlashcardState> {
  final FlashcardRepository repository;
  final FlashcardProgressRepository progressRepository;
  
  // Oturum içi yanlış kartlar (destenin sonuna eklenecek)
  final List<String> _wrongCardsInSession = [];

  FlashcardCubit(this.repository, this.progressRepository) 
      : super(const FlashcardState.initial());

  /// Load flashcards by topic ID
  Future<void> loadByTopicId(String topicId) async {
    try {
      emit(const FlashcardState.loading());
      
      final result = await repository.getFlashcardSetByTopicId(topicId);
      
      result.fold(
        (error) => emit(FlashcardState.error(error)),
        (flashcardSet) => emit(FlashcardState.loaded(
          flashcardSet: flashcardSet,
          currentIndex: 0,
          isFlipped: false,
        )),
      );
    } catch (e) {
      emit(FlashcardState.error('Beklenmeyen bir hata oluştu: ${e.toString()}'));
    }
  }

  /// Flip the current card
  void flipCard() {
    state.maybeWhen(
      loaded: (set, index, isFlipped) {
        emit(FlashcardState.loaded(
          flashcardSet: set,
          currentIndex: index,
          isFlipped: !isFlipped,
        ));
      },
      orElse: () {},
    );
  }

  /// Go to next card
  void nextCard() {
    state.maybeWhen(
      loaded: (set, index, isFlipped) {
        if (index < set.cards.length - 1) {
          // Go to next card
          emit(FlashcardState.loaded(
            flashcardSet: set,
            currentIndex: index + 1,
            isFlipped: false,
          ));
        } else {
          // ⚡ Streak'i işaretle - flashcard tamamlandı
          StreakService.markTodayAsStudied();
          // Finished
          emit(FlashcardState.finished(flashcardSet: set));
        }
      },
      orElse: () {},
    );
  }

  /// Go to previous card
  void previousCard() {
    state.maybeWhen(
      loaded: (set, index, isFlipped) {
        if (index > 0) {
          emit(FlashcardState.loaded(
            flashcardSet: set,
            currentIndex: index - 1,
            isFlipped: false,
          ));
        }
      },
      orElse: () {},
    );
  }

  /// Restart the set from the beginning
  void restart() {
    state.maybeWhen(
      finished: (set) {
        emit(FlashcardState.loaded(
          flashcardSet: set,
          currentIndex: 0,
          isFlipped: false,
        ));
      },
      orElse: () {},
    );
  }

  /// Mark current card as known (Leitner: move to next box)
  Future<void> markAsKnown() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      nextCard();
      return;
    }

    await state.maybeWhen(
      loaded: (set, index, isFlipped) async {
        final currentCard = set.cards[index];
        
        // Save progress (Leitner System)
        await progressRepository.saveCorrectAnswer(
          userId: userId,
          flashcardId: currentCard.id,
        );
        
        // Remove from wrong cards if exists
        _wrongCardsInSession.remove(currentCard.id);
        
        nextCard();
      },
      orElse: () async {},
    );
  }

  /// Mark current card as unknown (Leitner: reset to box 1, add to end)
  Future<void> markAsUnknown() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      nextCard();
      return;
    }

    // Get current state data
    final currentState = state;
    
    late final FlashcardSet set;
    late final int index;
    late final Flashcard currentCard;
    
    currentState.maybeWhen(
      loaded: (flashcardSet, currentIndex, isFlipped) {
        set = flashcardSet;
        index = currentIndex;
        currentCard = set.cards[index];
      },
      orElse: () => {},
    );
    
    if (!currentState.maybeWhen(
      loaded: (_, __, ___) => true,
      orElse: () => false,
    )) {
      return;
    }
    
    try {
      // Save progress (Leitner System - reset to box 1)
      await progressRepository.saveWrongAnswer(
        userId: userId,
        flashcardId: currentCard.id,
      );
    } catch (e) {
      AppLogger.error('Flashcard wrong answer save failed', e);
    }
    
    // Add to wrong cards for session replay (only once per card)
    if (!_wrongCardsInSession.contains(currentCard.id)) {
      _wrongCardsInSession.add(currentCard.id);
      
      // Kartı destenin sonuna ekle (oturum içi tekrar)
      final updatedCards = List<Flashcard>.from(set.cards);
      updatedCards.add(currentCard);
      
      // totalCards orijinal sayıda kalmalı (progress tracking için)
      final updatedSet = FlashcardSet(
        id: set.id,
        topicId: set.topicId,
        topicName: set.topicName,
        cards: updatedCards,
        totalCards: set.totalCards,
      );
      
      emit(FlashcardState.loaded(
        flashcardSet: updatedSet,
        currentIndex: index,
        isFlipped: false,
      ));
    }
    
    // Move to next card
    nextCard();
  }
}
