import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(bottom: 8),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary : (isDark ? AppColors.darkSurface : AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        border: isUser ? null : Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: isUser ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ] : null,
      ),
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isUser ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideX(
        begin: isUser ? 0.1 : -0.1,
        duration: 400.ms,
        curve: Curves.easeOutCubic,
      );
  }
}
