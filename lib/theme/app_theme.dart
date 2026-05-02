import 'package:flutter/material.dart';

/// 商家端：偏商务、清晰的浅色主题；主色为琥珀强调运营动作。
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFFC67C00);
  static const Color surface = Color(0xFFF7F5F2);
  static const Color onSurfaceMuted = Color(0xFF6B6560);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: surface,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: primary.withOpacity(0.12),
      ),
    );
  }
}
