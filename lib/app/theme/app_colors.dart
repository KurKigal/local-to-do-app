import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary =
      Color(0xFF7657FF);
  static const primaryLight =
      Color(0xFF927CFF);
  static const primaryDark =
      Color(0xFF5936F5);

  // AMOLED-first dark palette.
  // Large background regions use true black so OLED pixels can turn off.
  static const darkBackground =
      Color(0xFF000000);
  static const darkSurface =
      Color(0xFF090A0D);
  static const darkSurfaceHigh =
      Color(0xFF111319);
  static const darkBorder =
      Color(0xFF20232B);

  static const lightBackground =
      Color(0xFFF7F7FC);
  static const lightSurface =
      Color(0xFFFFFFFF);
  static const lightSurfaceHigh =
      Color(0xFFF0F0F8);
  static const lightBorder =
      Color(0xFFE6E6F0);

  static const success =
      Color(0xFF35C977);
  static const warning =
      Color(0xFFFFB84D);
  static const danger =
      Color(0xFFFF525D);
  static const info =
      Color(0xFF4F8CFF);
}
