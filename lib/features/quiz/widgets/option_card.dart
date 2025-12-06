import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OptionCard extends StatelessWidget {
  final String optionKey;
  final String optionText;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback? onTap;

  const OptionCard({
    super.key,
    required this.optionKey,
    required this.optionText,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    Color letterBg;
    Color letterColor;

    if (showResult) {
      if (isCorrect) {
        backgroundColor = const Color(0xFF10B981).withValues(alpha: 0.08);
        borderColor = const Color(0xFF10B981);
        textColor = const Color(0xFF065F46);
        letterBg = const Color(0xFF10B981);
        letterColor = Colors.white;
      } else if (isSelected) {
        backgroundColor = const Color(0xFFEF4444).withValues(alpha: 0.08);
        borderColor = const Color(0xFFEF4444);
        textColor = const Color(0xFF991B1B);
        letterBg = const Color(0xFFEF4444);
        letterColor = Colors.white;
      } else {
        backgroundColor = const Color(0xFFFAFAFA);
        borderColor = const Color(0xFFE5E7EB);
        textColor = const Color(0xFF6B7280);
        letterBg = const Color(0xFFF3F4F6);
        letterColor = const Color(0xFF9CA3AF);
      }
    } else {
      if (isSelected) {
        backgroundColor = const Color(0xFF6366F1).withValues(alpha: 0.06);
        borderColor = const Color(0xFF6366F1);
        textColor = const Color(0xFF1C1B1F);
        letterBg = const Color(0xFF6366F1);
        letterColor = Colors.white;
      } else {
        backgroundColor = Colors.white;
        borderColor = const Color(0xFFE5E7EB);
        textColor = const Color(0xFF1C1B1F);
        letterBg = const Color(0xFFF9FAFB);
        letterColor = const Color(0xFF6B7280);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: letterBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    optionKey,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: letterColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  optionText,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 26,
                height: 26,
                child: showResult
                    ? (isCorrect
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          )
                        : (isSelected && !isCorrect
                            ? Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              )
                            : null))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
