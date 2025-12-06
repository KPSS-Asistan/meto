import 'package:flutter/material.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

/// Arka plan dekoratif painter - yumuşak dalgalar
class HomeBackgroundPainter extends CustomPainter {
  final bool isDark;
  
  HomeBackgroundPainter({required this.isDark});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Üst dalga - mor/primary
    final topWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.4));
    
    final topPath = Path()
      ..moveTo(size.width * 0.6, 0)
      ..quadraticBezierTo(
        size.width * 1.1, size.height * 0.15,
        size.width, size.height * 0.35,
      )
      ..lineTo(size.width, 0)
      ..close();
    
    canvas.drawPath(topPath, topWavePaint);
    
    // Orta dalga - mavi
    final midWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF0284C7).withValues(alpha: isDark ? 0.06 : 0.04),
          const Color(0xFF0284C7).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.3, size.width * 0.5, size.height * 0.4));
    
    final midPath = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.2, size.height * 0.5,
        size.width * 0.1, size.height * 0.7,
      )
      ..lineTo(0, size.height * 0.7)
      ..close();
    
    canvas.drawPath(midPath, midWavePaint);
    
    // Alt dalga - turuncu/warm
    final bottomWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          const Color(0xFFD97706).withValues(alpha: isDark ? 0.06 : 0.04),
          const Color(0xFFD97706).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(size.width * 0.5, size.height * 0.6, size.width * 0.5, size.height * 0.4));
    
    final bottomPath = Path()
      ..moveTo(size.width, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.7, size.height * 0.85,
        size.width * 0.8, size.height,
      )
      ..lineTo(size.width, size.height)
      ..close();
    
    canvas.drawPath(bottomPath, bottomWavePaint);
  }
  
  @override
  bool shouldRepaint(covariant HomeBackgroundPainter oldDelegate) => 
      oldDelegate.isDark != isDark;
}
