import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class QuickQuestionCard extends StatefulWidget {
  final String question;
  final VoidCallback onTap;
  final bool isDark;

  const QuickQuestionCard({
    super.key,
    required this.question,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<QuickQuestionCard> createState() => _QuickQuestionCardState();
}

class _QuickQuestionCardState extends State<QuickQuestionCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark ? AppColors.darkBorder : AppColors.border,
            ),
            boxShadow: _scale < 1.0 ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.question, style: TextStyle(
                  fontSize: 14, 
                  color: widget.isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                )),
              ),
              const SizedBox(width: 12),
              AnimatedRotation(
                turns: _scale < 1.0 ? 0.1 : 0.0,
                duration: const Duration(milliseconds: 100),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: widget.isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
