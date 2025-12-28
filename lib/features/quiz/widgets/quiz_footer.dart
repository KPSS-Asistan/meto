import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

/// Quiz ekranının alt navigasyon bar'ı - İleri/Geri/Cevapla butonları
class QuizFooter extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final String? selectedOption;
  final bool isAnswered;
  final VoidCallback onPrevious;
  final VoidCallback onSubmit;
  final VoidCallback onNext;

  const QuizFooter({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.selectedOption,
    required this.isAnswered,
    required this.onPrevious,
    required this.onSubmit,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool canSubmit = selectedOption != null || isAnswered;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? const Color(0xFF374151) : Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Geri butonu (ilk soruda gizli)
          if (currentIndex > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _NavigationButton(
                icon: LucideIcons.arrowLeft,
                onTap: onPrevious,
              ),
            ),
          
          // Ana buton (Cevapla / Devam Et / Sonuçları Gör)
          Expanded(
            child: _MainActionButton(
              label: _getButtonLabel(),
              isEnabled: canSubmit,
              onTap: canSubmit
                  ? (isAnswered ? onNext : onSubmit)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonLabel() {
    if (isAnswered) {
      return currentIndex + 1 < totalQuestions ? 'Devam Et' : 'Sonuçları Gör';
    }
    return 'Cevapla';
  }
}

/// Küçük navigasyon butonu (Geri)
class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF4B5563) : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

/// Ana aksiyon butonu (Cevapla / Devam Et)
class _MainActionButton extends StatelessWidget {
  final String label;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _MainActionButton({
    required this.label,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primary : (isDark ? const Color(0xFF374151) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isEnabled ? Colors.white : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
            ),
          ),
        ),
      ),
    );
  }
}
