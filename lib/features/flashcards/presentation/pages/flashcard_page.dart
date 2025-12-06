import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kpss_2026/core/services/daily_progress_service.dart';
import '../../data/repositories/hardcoded_flashcard_repository.dart';
import '../../data/repositories/flashcard_progress_repository.dart';
import '../bloc/flashcard_cubit.dart';
import '../bloc/flashcard_state.dart';
import 'dart:math' as math;

/// Clean Minimal Flashcard with Leitner System (Spaced Repetition)
/// ⚡ OPTIMIZED: Hardcoded data - Firebase'e bağımlılık yok
/// Ön yüz: Soru
/// Arka yüz: Cevap + Info popup
/// Alt butonlar: ✓ Biliyorum (next box) | ✗ Bilmiyorum (reset to box 1)
class FlashcardPage extends StatelessWidget {
  final String topicId;

  const FlashcardPage({super.key, required this.topicId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlashcardCubit(
        HardcodedFlashcardRepository(), // ⚡ Firebase yerine hardcoded
        FlashcardProgressRepository(),
      )..loadByTopicId(topicId),
      child: const _FlashcardView(),
    );
  }
}

class _FlashcardView extends StatefulWidget {
  const _FlashcardView();

  @override
  State<_FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<_FlashcardView> with SingleTickerProviderStateMixin {
  final CardSwiperController _controller = CardSwiperController();
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800), // ⚡ Daha yavaş çevirme
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _showInfoDialog(String? additionalInfo) {
    if (additionalInfo == null || additionalInfo.isEmpty) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 32,
                  color: Color(0xFF6366F1),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'Ek Bilgi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                additionalInfo,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Anladım'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: BlocConsumer<FlashcardCubit, FlashcardState>(
          listener: (context, state) {
            state.maybeWhen(
              loaded: (set, index, isFlipped) {
                if (isFlipped && _flipController.status != AnimationStatus.completed) {
                  _flipController.forward();
                } else if (!isFlipped && _flipController.status != AnimationStatus.dismissed) {
                  _flipController.reverse();
                }
              },
              orElse: () {},
            );
          },
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                ),
              ),
              error: (msg) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
                    const SizedBox(height: 16),
                    Text(
                      msg,
                      style: const TextStyle(color: Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('Geri Dön'),
                    ),
                  ],
                ),
              ),
              finished: (set) => _buildFinished(context, isDark),
              loaded: (set, index, isFlipped) => Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(context, set.topicName, index, set.totalCards, isDark),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: CardSwiper(
                            controller: _controller,
                            cardsCount: set.cards.length,
                            initialIndex: index,
                            isDisabled: false,
                            allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
                            onSwipe: (prev, curr, dir) {
                              // ⚡ Her kart için günlük ilerleme say
                              DailyProgressService.incrementFlashcards();
                              
                              if (dir == CardSwiperDirection.left) {
                                context.read<FlashcardCubit>().markAsKnown();
                              } else if (dir == CardSwiperDirection.right) {
                                context.read<FlashcardCubit>().markAsUnknown();
                              }
                              _flipController.reset();
                              return true;
                            },
                            numberOfCardsDisplayed: (index < set.cards.length - 1) ? 2 : 1,
                            backCardOffset: const Offset(0, -20),
                            cardBuilder: (context, i, h, v) {
                              final card = set.cards[i];
                              final isCurrentCard = i == index;
                              
                              return GestureDetector(
                                onTap: isCurrentCard 
                                    ? () => context.read<FlashcardCubit>().flipCard()
                                    : null,
                                child: AnimatedBuilder(
                                  animation: _flipAnimation,
                                  builder: (context, child) {
                                    // ⚡ FIX: Sadece aktif kart flip olabilir, arkadakiler hep ön yüzde
                                    final angle = isCurrentCard ? _flipAnimation.value * math.pi : 0.0;
                                    final isFront = angle < (math.pi / 2);
                                    
                                    return Transform(
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateY(angle),
                                      alignment: Alignment.center,
                                      child: isFront
                                          ? _buildCard(card.question, card.answer, false, false, null, isDark)
                                          : Transform(
                                              transform: Matrix4.identity()..rotateY(math.pi),
                                              alignment: Alignment.center,
                                              child: _buildCard(card.question, card.answer, true, true, card.additionalInfo, isDark),
                                            ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                  
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 32,
                    child: _buildFloatingButtons(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, int index, int total, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 24),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${index + 1} / $total',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String front, String back, bool isFlipped, bool showInfo, String? additionalInfo, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isFlipped ? _buildBackCard(back, showInfo, additionalInfo, isDark) : _buildFrontCard(front, isDark),
    );
  }

  Widget _buildFrontCard(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'SORU',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          Expanded(
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              const Text(
                'Kartı çevirmek için dokunun',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(String text, bool showInfo, String? additionalInfo, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'CEVAP',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 40),

          Expanded(
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (showInfo && additionalInfo != null && additionalInfo.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, size: 28),
              color: const Color(0xFF6366F1),
              onPressed: () => _showInfoDialog(additionalInfo),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                padding: const EdgeInsets.all(12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              _controller.swipe(CardSwiperDirection.right);
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    blurRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(width: 48),

          GestureDetector(
            onTap: () {
              _controller.swipe(CardSwiperDirection.left);
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
    );
  }

  Widget _buildFinished(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: Colors.white,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 32),

            Text(
              'Tamamlandı!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Tüm kartları tamamladınız',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.read<FlashcardCubit>().restart(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Yeniden Başla'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Ana Sayfaya Dön',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
