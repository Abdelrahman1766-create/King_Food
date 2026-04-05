import 'package:flutter/material.dart';

/// فئة مساعدة للتعامل مع التصميم المتجاوب
class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  /// تحديد إذا كانت الشاشة موبايل صغير
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// تحديد إذا كانت الشاشة تابلت
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// تحديد إذا كانت الشاشة كبيرة جداً
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// الحصول على عرض الشاشة
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// الحصول على ارتفاع الشاشة
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// حساب حجم الخط بناءً على حجم الشاشة
  static double getResponsiveFontSize(
    BuildContext context, {
    double mobileSize = 14,
    double tabletSize = 16,
    double desktopSize = 18,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize;
    return desktopSize;
  }

  /// حساب حجم الأيقونة بناءً على حجم الشاشة
  static double getResponsiveIconSize(
    BuildContext context, {
    double mobileSize = 24,
    double tabletSize = 32,
    double desktopSize = 40,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize;
    return desktopSize;
  }

  /// حساب حجم الأيقونة الصغيرة
  static double getSmallIconSize(
    BuildContext context, {
    double mobileSize = 16,
    double tabletSize = 20,
    double desktopSize = 24,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize;
    return desktopSize;
  }

  /// حساب حجم الأيقونة الكبيرة
  static double getLargeIconSize(
    BuildContext context, {
    double mobileSize = 48,
    double tabletSize = 64,
    double desktopSize = 80,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize;
    return desktopSize;
  }

  /// حساب الحشو (Padding) بناءً على حجم الشاشة
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    double mobileHorizontal = 16,
    double mobileVertical = 16,
    double tabletHorizontal = 24,
    double tabletVertical = 24,
    double desktopHorizontal = 32,
    double desktopVertical = 32,
  }) {
    if (isMobile(context)) {
      return EdgeInsets.symmetric(
        horizontal: mobileHorizontal,
        vertical: mobileVertical,
      );
    }
    if (isTablet(context)) {
      return EdgeInsets.symmetric(
        horizontal: tabletHorizontal,
        vertical: tabletVertical,
      );
    }
    return EdgeInsets.symmetric(
      horizontal: desktopHorizontal,
      vertical: desktopVertical,
    );
  }

  /// حساب عدد الأعمدة (Columns) للشبكة بناءً على حجم الشاشة
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  /// حساب حجم العنصر في الشبكة
  static double getGridItemHeight(
    BuildContext context, {
    double mobileHeight = 200,
    double tabletHeight = 250,
    double desktopHeight = 300,
  }) {
    if (isMobile(context)) return mobileHeight;
    if (isTablet(context)) return tabletHeight;
    return desktopHeight;
  }

  /// حساب أقصى عرض للمحتوى
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) return screenWidth(context);
    if (isTablet(context)) return screenWidth(context) * 0.9;
    return 1200;
  }

  /// حساب حجم الزر
  static double getButtonHeight(BuildContext context) {
    if (isMobile(context)) return 48;
    if (isTablet(context)) return 56;
    return 64;
  }

  /// حساب نسبة حجم النص بناءً على حجم الشاشة
  static TextStyle getResponsiveTextStyle(
    BuildContext context, {
    TextStyle? baseStyle,
    double mobileSizeScale = 1.0,
    double tabletSizeScale = 1.2,
    double desktopSizeScale = 1.4,
  }) {
    final scale = isMobile(context)
        ? mobileSizeScale
        : isTablet(context)
        ? tabletSizeScale
        : desktopSizeScale;

    baseStyle ??= Theme.of(context).textTheme.bodyMedium;
    final baseFontSize = baseStyle?.fontSize ?? 14;

    return (baseStyle ?? const TextStyle()).copyWith(
      fontSize: baseFontSize * scale,
    );
  }

  /// حساب حجم الصورة بناءً على حجم الشاشة
  static double getImageSize(
    BuildContext context, {
    double mobileSize = 80,
    double tabletSize = 120,
    double desktopSize = 160,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize;
    return desktopSize;
  }

  /// حساب حجم صورة المنتج
  static double getProductImageHeight(BuildContext context) {
    if (isMobile(context)) return 150;
    if (isTablet(context)) return 200;
    return 250;
  }
}
