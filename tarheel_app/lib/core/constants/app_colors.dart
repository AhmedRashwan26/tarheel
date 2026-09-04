import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors from Tarheel Logo
  static const Color primary = Color(0xFF153364); // Deep Navy Blue (كلمة ترحيل)
  static const Color primaryDark = Color(0xFF0D2244);
  static const Color primaryLight = Color(0xFF1E468A);
  
  static const Color accent = Color(0xFFF15A24); // Dynamic Vibrant Orange (السيارة وسهم الانطلاق)
  static const Color accentLight = Color(0xFFFF7A47);
  static const Color accentDark = Color(0xFFD64410);

  static const Color secondary = Color(0xFF1D84C6); // Speed Cyan Blue (قوس السرعة الأوسط)
  static const Color secondaryLight = Color(0xFFE0F2FE);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status & Financial Escrow
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  static const Color escrow = Color(0xFF0D9488); // تيل الضمان المالي
  static const Color escrowLight = Color(0xFFCCFBF1);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF1E468A)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFF7A47)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primary, Color(0xFF0D2244)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
