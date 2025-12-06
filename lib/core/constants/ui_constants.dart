import 'package:flutter/material.dart';

/// UI Constants - Magic number'ları ortadan kaldırır
/// Material Design 3 standartlarına uygun
class UIConstants {
  UIConstants._();

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacing2XL = 32.0;
  static const double spacing3XL = 48.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusFull = 999.0;

  static const BorderRadius borderRadiusXS = BorderRadius.all(Radius.circular(radiusXS));
  static const BorderRadius borderRadiusSM = BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderRadiusMD = BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderRadiusLG = BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));

  // ═══════════════════════════════════════════════════════════════════════════
  // PADDING
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const EdgeInsets paddingXS = EdgeInsets.all(spacingXS);
  static const EdgeInsets paddingSM = EdgeInsets.all(spacingSM);
  static const EdgeInsets paddingMD = EdgeInsets.all(spacingMD);
  static const EdgeInsets paddingLG = EdgeInsets.all(spacingLG);
  static const EdgeInsets paddingXL = EdgeInsets.all(spacingXL);
  
  static const EdgeInsets paddingHorizontalSM = EdgeInsets.symmetric(horizontal: spacingSM);
  static const EdgeInsets paddingHorizontalMD = EdgeInsets.symmetric(horizontal: spacingMD);
  static const EdgeInsets paddingHorizontalLG = EdgeInsets.symmetric(horizontal: spacingLG);
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(horizontal: spacingXL);
  
  static const EdgeInsets paddingVerticalSM = EdgeInsets.symmetric(vertical: spacingSM);
  static const EdgeInsets paddingVerticalMD = EdgeInsets.symmetric(vertical: spacingMD);
  static const EdgeInsets paddingVerticalLG = EdgeInsets.symmetric(vertical: spacingLG);
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(vertical: spacingXL);

  // ═══════════════════════════════════════════════════════════════════════════
  // CARD STYLES
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double cardElevation = 0.0;
  static const double cardBorderWidth = 1.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingLG);
  static const BorderRadius cardBorderRadius = borderRadiusMD;

  // ═══════════════════════════════════════════════════════════════════════════
  // BUTTON STYLES
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightLarge = 56.0;
  static const BorderRadius buttonBorderRadius = borderRadiusMD;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: spacingXL,
    vertical: spacingMD,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // INPUT STYLES
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double inputHeight = 52.0;
  static const BorderRadius inputBorderRadius = borderRadiusMD;
  static const EdgeInsets inputContentPadding = EdgeInsets.symmetric(
    horizontal: spacingLG,
    vertical: spacingMD,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ICON SIZES
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // FONT SIZES
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const double fontXS = 10.0;
  static const double fontSM = 12.0;
  static const double fontMD = 14.0;
  static const double fontLG = 16.0;
  static const double fontXL = 18.0;
  static const double fontXXL = 20.0;
  static const double font2XL = 24.0;
  static const double font3XL = 30.0;
  static const double font4XL = 36.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const Duration animationFast = Duration(milliseconds: 100);
  static const Duration animationNormal = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 400);
  
  static const Curve animationCurve = Curves.easeOutCubic;
  static const Curve animationCurveIn = Curves.easeIn;
  static const Curve animationCurveOut = Curves.easeOut;

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOWS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static List<BoxShadow> shadowSM(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadowMD(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowLG(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // TOUCH TARGETS (Accessibility)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Minimum touch target size (Material Design recommendation: 48x48)
  static const double minTouchTarget = 48.0;
}
