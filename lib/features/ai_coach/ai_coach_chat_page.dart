import 'package:flutter/material.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';
import 'package:kpss_2026/core/theme/app_sizes.dart';
import 'mixins/ai_coach_logic_mixin.dart';
import 'widgets/chat_message_bubble.dart'; 
import 'widgets/quick_question_card.dart';

/// AI Koç Sayfası - Academic Premium Design
/// ⚡ OPTIMIZED: Logic mixin'e taşındı
class AICoachChatPage extends StatefulWidget {
  const AICoachChatPage({super.key});

  @override
  State<AICoachChatPage> createState() => _AICoachChatPageState();
}

class _AICoachChatPageState extends State<AICoachChatPage> with AutomaticKeepAliveClientMixin, AICoachLogicMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // ⚡ AutomaticKeepAliveClientMixin için gerekli
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space16, vertical: AppSizes.space12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppSizes.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Koç', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      )),
                      // Premium kullanıcılar için sınırsız, diğerleri için günlük + bonus
                      isPremium
                          ? Text('∞ Sınırsız soru hakkı', style: TextStyle(
                              fontSize: 12, color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ))
                          : Row(
                              children: [
                                Text('$remainingQuestions günlük', style: TextStyle(
                                  fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                                )),
                                if (bonusQuestions > 0) ...[
                                  Text(' + ', style: TextStyle(
                                    fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                                  )),
                                  Text('$bonusQuestions bonus', style: TextStyle(
                                    fontSize: 12, color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  )),
                                ],
                              ],
                            ),
                    ],
                  ),
                ),
                // Reklam İzle Butonu - Her zaman görünür
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: watchRewardedAd,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_filled_rounded, size: 16, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text('+1', style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, size: 20, 
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                  onPressed: resetConversation,
                  tooltip: 'Yenile',
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: messages.isEmpty
                ? _buildEmpty(isDark)
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSizes.space16),
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (isLoading && i == messages.length) {
                        return _buildLoading(isDark);
                      }
                      return Align(
                        alignment: messages[i].isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: ChatMessageBubble(message: messages[i], isDark: isDark),
                      );
                    },
                  ),
          ),
          
          // Hızlı Sorular (Horizontal Scroll) - Modern Chip Design
          if (messages.isNotEmpty && quickQuestions.isNotEmpty && remainingQuestions > 0)
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.background,
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: quickQuestions.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          textController.text = quickQuestions[i];
                          sendMessage();
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                quickQuestions[i],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Input
          Container(
            padding: const EdgeInsets.all(AppSizes.space16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: remainingQuestions > 0 ? 'Soru sor...' : 'Günlük hakkınız bitti',
                        hintStyle: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                        filled: true,
                        fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      enabled: remainingQuestions > 0 && !isCheater,
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: AppSizes.space12),
                  GestureDetector(
                    onTap: (isLoading || remainingQuestions <= 0) ? null : sendMessage,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: (isLoading || remainingQuestions <= 0) 
                            ? AppColors.surfaceHover 
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_upward_rounded, 
                        color: (isLoading || remainingQuestions <= 0) 
                            ? AppColors.textTertiary 
                            : Colors.white, 
                        size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.space20),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          // AI Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text('KPSS Koçun', style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          )),
          const SizedBox(height: 8),
          Text('Sana özel çalışma planı, motivasyon ve\nstratejiler için buradayım', 
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, 
              height: 1.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          )),
          
          const SizedBox(height: 32),
          
          // Hızlı Sorular Başlığı
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hızlı Sorular',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Hızlı Soru Kartları
          ...quickQuestions.map((q) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: QuickQuestionCard(
              question: q,
              onTap: () { textController.text = q; sendMessage(); },
              isDark: isDark,
            ),
          )),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Text('AI KOÇ düşünüyor.', style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary)),
      ),
    );
  }
}
