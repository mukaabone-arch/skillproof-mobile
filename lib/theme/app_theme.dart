import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Wires [AppColors] + [AppTypography] into a single Material 3 dark
/// ThemeData. This is the only theme the app ships — there is no light
/// variant — so [AppTheme.dark] is used for both `theme:` and `darkTheme:`
/// in MaterialApp, with `themeMode: ThemeMode.dark` forcing it regardless
/// of the device's system setting.
///
/// Component themes intentionally set explicit colors rather than relying
/// on ColorScheme-derived defaults wherever the web app's button/badge
/// colors don't follow Material's "primary fills, onPrimary text" pattern
/// (e.g. verified badges use verified-green fills, which must never leak
/// into ColorScheme.secondary or any other role Material applies broadly —
/// see the "never use green for anything else" rule in app_colors.dart).
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      // Used for whatever unthemed M3 defaults still read primary directly
      // (text selection handles, default Switch/Radio, CircularProgressIndicator).
      // Explicit component themes below override this for buttons/badges/nav.
      primary: AppColors.indigoLight,
      onPrimary: AppColors.background,
      secondary: AppColors.purpleLight,
      onSecondary: AppColors.background,
      error: AppColors.dangerBright,
      onError: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
    );

    final textTheme = TextTheme(
      displayLarge: AppTypography.displayLarge,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,
      titleMedium: AppTypography.titleMedium,
      titleSmall: AppTypography.titleSmall,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineSmall,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // NOTE: Flutter renamed ThemeData.cardTheme's type from `CardTheme` to
      // `CardThemeData` (CardTheme itself became a separate widget-level
      // class). Using CardThemeData here since that's correct on any
      // reasonably current Flutter; if your SDK predates that rename,
      // change this one constructor call to `CardTheme(...)`  and it's the
      // same fields either way.
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // Primary action — mirrors web's solid `--indigo` button with white
      // text (8.2:1 contrast; see app_colors.dart). Deliberately not
      // derived from colorScheme.primary (which is the *light* indigo
      // meant for text-on-dark, not a button fill).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.indigo,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.indigo.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5, vertical: AppSpacing.space4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.indigo,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.indigo.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
          elevation: 0,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5, vertical: AppSpacing.space4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      // Secondary action — mirrors web's `.btn-secondary` (transparent fill,
      // outlined, ink-colored text).
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textTertiary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5, vertical: AppSpacing.space4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.indigoLight,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.textTertiary),
        labelStyle: AppTypography.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.indigoLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.dangerBright, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.dangerBright, width: 2),
        ),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.dangerBright),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.indigoSoft,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.labelSmall.copyWith(
            color: selected ? AppColors.indigoLight : AppColors.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.indigoLight : AppColors.textTertiary);
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.indigoLight,
        linearTrackColor: AppColors.border,
        circularTrackColor: AppColors.border,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        actionTextColor: AppColors.indigoLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
