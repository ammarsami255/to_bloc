// Copyright 2024 ElMoza3. All rights reserved.
// Core constants and theme for the application

import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF1A6BF5);
  static const Color textPrimary = Color(0xFF0D1B3E);
  static const Color textSecondary = Color(0xFF6B7FA3);
  static const Color border = Color(0xFFD4E2F7);
  static const Color background1 = Color(0xFFE8F0FE);
  static const Color background2 = Color(0xFFF5F8FF);

  // Derived colors
  static const Color primaryLight = Color(0xFF4A90F8);
  static const Color primaryDark = Color(0xFF0052CC);
  static const Color primaryLighter = Color(0xFFE3F0FF);
  static final Color primaryFade = Color(0xFF1A6BF5).withOpacity(0.1);

  // Semantic colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Text colors
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFF0F172A);

  // Surface colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFC);
  static const Color divider = Color(0xFFE2E8F0);

  // Shadows
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
}

class AppSizes {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1000;
  static const double desktopBreakpoint = 1200;

  static const double defaultPadding = 20;
  static const double borderRadius = 12;
  static const double buttonHeight = 52;
  static const double iconSize = 24;
  static const double titleSizeMobile = 28;
  static const double titleSizeTablet = 32;
  static const double subtitleSizeMobile = 13;
  static const double subtitleSizeTablet = 14;
  static const double fieldFontSize = 14;

  static const double spacing2 = 4;
  static const double spacing4 = 8;
  static const double spacing8 = 12;
  static const double spacing12 = 16;
  static const double spacing16 = 20;
  static const double spacing20 = 24;
  static const double spacing24 = 28;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;

  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;
  static const double radiusFull = 999;

  static const double buttonHeightSmall = 36;
  static const double buttonHeightMedium = 44;
  static const double buttonHeightLarge = 52;
  static const double buttonHeightXLarge = 56;

  static const double iconSizeSmall = 16;
  static const double iconSizeMedium = 20;
  static const double iconSizeLarge = 24;
  static const double iconSizeXLarge = 32;

  static const double cardElevation = 2;
  static const double cardBorderWidth = 1;

  static const double inputHeight = 48;
  static const double inputPadding = 12;
  static const double inputBorderRadius = 12;
}

class AppTypography {
  static const String fontFamily = 'Cairo';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}

class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double xxxxl = 48;
}

class AppAnimations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration xslow = Duration(milliseconds: 500);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve emphasisCurve = Curves.easeOutCubic;
  static const Curve decelerateCurve = Curves.easeOutQuart;
  static const Curve accelerateCurve = Curves.easeInQuart;

  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Curve pageTransitionCurve = Curves.easeInOutCubic;

  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration buttonFeedback = Duration(milliseconds: 150);

  static const Duration loadingPulse = Duration(milliseconds: 1000);
  static const Duration listItemStagger = Duration(milliseconds: 50);
}

class AppShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get large => [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.shadowLight.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: AppColors.shadowMedium.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}

class AppBorders {
  static const double width = 1;
  static const double widthThick = 2;

  static BorderSide get defaultBorderSide =>
      BorderSide(color: AppColors.border, width: width);

  static BorderSide get primaryBorderSide =>
      BorderSide(color: AppColors.primary, width: width);

  static BorderSide get focusBorderSide =>
      BorderSide(color: AppColors.primary, width: widthThick);

  static Border get defaultBorder =>
      Border.all(color: AppColors.border, width: width);
  static Border get primaryBorder =>
      Border.all(color: AppColors.primary, width: width);

  static BorderRadius get radiusSmall =>
      BorderRadius.circular(AppSizes.radiusSmall);
  static BorderRadius get radiusMedium =>
      BorderRadius.circular(AppSizes.radiusMedium);
  static BorderRadius get radiusLarge =>
      BorderRadius.circular(AppSizes.radiusLarge);
  static BorderRadius get radiusXLarge =>
      BorderRadius.circular(AppSizes.radiusXLarge);
  static BorderRadius get radiusFull =>
      BorderRadius.circular(AppSizes.radiusFull);
}