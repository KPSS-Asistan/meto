import 'package:flutter/material.dart';
import 'package:kpss_2026/core/theme/app_colors.dart';

class CurveDivider extends StatelessWidget {
  const CurveDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: double.infinity,
      height: 10,
      child: CustomPaint(
        painter: _CurveDividerPainter(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
    );
  }
}

class _CurveDividerPainter extends CustomPainter {
  final Color color;
  
  _CurveDividerPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    
    // Hafif eğimli dalga - tüm genişliği kaplar
    path.moveTo(0, size.height * 0.5);
    
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.35,
      size.width * 0.5, size.height * 0.5,
    );
    
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.65,
      size.width, size.height * 0.5,
    );
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
