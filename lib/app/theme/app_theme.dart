import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.lightSurface,
    );

    return _baseTheme(
      scheme,
    ).copyWith(
      scaffoldBackgroundColor:
          AppColors.lightBackground,
      cardTheme:
          const CardThemeData(
        elevation: 0,
        color: AppColors.lightSurface,
        margin: EdgeInsets.zero,
      ),
      dividerTheme:
          const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme:
          _navigationBarTheme(
        scheme,
        AppColors.lightSurface,
      ),
    );
  }

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.darkSurface,
    ).copyWith(
      surface:
          AppColors.darkSurface,
      surfaceContainerLowest:
          AppColors.darkBackground,
      surfaceContainerLow:
          AppColors.darkSurface,
      surfaceContainer:
          AppColors.darkSurfaceHigh,
      surfaceContainerHigh:
          AppColors.darkSurfaceHigh,
      surfaceContainerHighest:
          const Color(0xFF181B22),
      outlineVariant:
          AppColors.darkBorder,
    );

    return _baseTheme(
      scheme,
    ).copyWith(
      scaffoldBackgroundColor:
          AppColors.darkBackground,
      canvasColor:
          AppColors.darkBackground,
      cardTheme:
          const CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        margin: EdgeInsets.zero,
      ),
      dividerTheme:
          const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme:
          _navigationBarTheme(
        scheme,
        AppColors.darkSurface,
      ),
      bottomSheetTheme:
          const BottomSheetThemeData(
        showDragHandle: true,
        elevation: 0,
        modalElevation: 0,
        backgroundColor:
            AppColors.darkSurface,
        modalBackgroundColor:
            AppColors.darkSurface,
      ),
      dialogTheme:
          DialogThemeData(
        elevation: 0,
        backgroundColor:
            AppColors.darkSurface,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            24,
          ),
        ),
      ),
    );
  }

  static ThemeData _baseTheme(
    ColorScheme scheme,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      splashFactory:
          InkRipple.splashFactory,
      visualDensity:
          VisualDensity.standard,

      appBarTheme:
          const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,
        fillColor:
            scheme.surfaceContainerLow,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      floatingActionButtonTheme:
          FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        backgroundColor:
            scheme.primary,
        foregroundColor:
            scheme.onPrimary,
        shape:
            const CircleBorder(),
      ),

      bottomSheetTheme:
          const BottomSheetThemeData(
        showDragHandle: true,
        elevation: 0,
        modalElevation: 0,
      ),

      dialogTheme:
          DialogThemeData(
        elevation: 0,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            24,
          ),
        ),
      ),

      chipTheme:
          ChipThemeData(
        side: BorderSide(
          color:
              scheme.outlineVariant,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  static NavigationBarThemeData
      _navigationBarTheme(
    ColorScheme scheme,
    Color background,
  ) {
    return NavigationBarThemeData(
      elevation: 0,
      height: 72,
      backgroundColor: background,
      indicatorColor:
          scheme.primaryContainer,
      indicatorShape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
    );
  }
}
