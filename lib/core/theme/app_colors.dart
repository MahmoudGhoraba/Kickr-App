import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand — orange
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryDark = Color(0xFFE55A24);
  static const Color primaryLight = Color(0xFFFFF4EF);

  // Secondary — deep blue (complementary)
  static const Color accent = Color(0xFF1A1F5E);

  // Surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF9FAFB);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFADB5BD);

  // Borders
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFFFF6B35);

  // Feedback — text colours
  static const Color error   = Color(0xFFDC2626); // red 600
  static const Color success = Color(0xFF16A34A); // green 600
  static const Color warning = Color(0xFFB45309); // amber 700
  static const Color info    = Color(0xFF2563EB); // blue 600

  // Feedback — background tints (paired with text colours above)
  static const Color errorBg   = Color(0xFFFEF2F2); // red 50
  static const Color successBg = Color(0xFFF0FDF4); // green 50
  static const Color warningBg = Color(0xFFFFFBEB); // amber 50
  static const Color infoBg    = Color(0xFFEFF6FF); // blue 50

  // Internship type palette (remote + onsite; hybrid reuses info/infoBg)
  static const Color typeRemoteText = Color(0xFF059669); // emerald 600
  static const Color typeRemoteBg   = Color(0xFFECFDF5); // emerald 50
  static const Color typeOnsiteText = Color(0xFF7C3AED); // violet 600
  static const Color typeOnsiteBg   = Color(0xFFF5F3FF); // violet 50

  // Primitives
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Utility
  static const Color cardShadow = Color(0x0D000000);
}
