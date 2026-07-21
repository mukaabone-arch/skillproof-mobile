import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Text styles translated from web's type system (globals.css):
///   --font-display: 'Space Grotesk'  (headings)
///   --font-body:    'Inter'          (everything else — body copy, buttons,
///                                     labels, meta, eyebrows, status chips)
///
/// Strict 2-font system, identical to web. Both families are bundled as
/// static per-weight TTFs under assets/fonts/ (declared in pubspec.yaml) —
/// deliberately NOT the google_fonts runtime-fetch package, which crashed
/// the app offline via fonts.gstatic.com. Note Space Grotesk has no 800
/// face (tops out at 700), so styles declaring w800 render at the 700
/// asset — same clamping web gets from the browser.
///
/// The former IBM Plex Mono label styles ([meta], [metaLabel], previously
/// mono/monoLabel) keep their exact sizes, weights, and letter-spacing —
/// only the family moved to Inter, mirroring web's same conversion of
/// .eyebrow/.status-card-label/.ui-badge.
///
/// Sizes are converted 1:1 from web's rem scale (1rem = 16px) — the two
/// responsive `clamp()` sizes (--text-2xl/-3xl) are pinned to their clamp
/// *minimum*, which is what they resolve to on a phone-width viewport.
///   --text-xs .72rem→12  --text-sm .85rem→14(rounded from 13.6)
///   --text-base 1rem→16  --text-lg 1.05rem→17(rounded)
///   --text-xl 1.3rem→21(rounded)
///   --text-2xl clamp(1.7rem,...)→27   --text-3xl clamp(2.4rem,...)→38
class AppTypography {
  AppTypography._();

  static const String _displayFamily = 'SpaceGrotesk';
  static const String _bodyFamily = 'Inter';

  static TextStyle _display({required double size, required FontWeight weight, double? letterSpacing, double? height}) {
    return TextStyle(
      fontFamily: _displayFamily,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle _body({required double size, required FontWeight weight, double? height, Color? color}) {
    return TextStyle(
      fontFamily: _bodyFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? AppColors.textPrimary,
    );
  }

  // ---- Display / headline (Space Grotesk) ----
  static final TextStyle displayLarge = _display(size: 38, weight: FontWeight.w800, letterSpacing: -0.6, height: 1.08);
  static final TextStyle headlineMedium = _display(size: 27, weight: FontWeight.w700, letterSpacing: -0.4, height: 1.15);
  static final TextStyle headlineSmall = _display(size: 21, weight: FontWeight.w700, letterSpacing: -0.2, height: 1.2);

  // ---- Titles (Inter, semibold) ----
  static final TextStyle titleMedium = _body(size: 17, weight: FontWeight.w600, height: 1.3);
  static final TextStyle titleSmall = _body(size: 16, weight: FontWeight.w600, height: 1.3);

  // ---- Body (Inter) ----
  static final TextStyle bodyLarge = _body(size: 16, weight: FontWeight.w400, height: 1.5);
  static final TextStyle bodyMedium = _body(size: 14, weight: FontWeight.w400, height: 1.5, color: AppColors.textSecondary);
  static final TextStyle bodySmall = _body(size: 12, weight: FontWeight.w400, height: 1.4, color: AppColors.textSecondary);

  // ---- Labels (Inter, semibold — this is what buttons render with) ----
  static final TextStyle labelLarge = _body(size: 15, weight: FontWeight.w600, height: 1.2);
  static final TextStyle labelMedium = _body(size: 13, weight: FontWeight.w600, height: 1.2);
  static final TextStyle labelSmall = _body(size: 11, weight: FontWeight.w600, height: 1.2);

  // ---- Meta (Inter, was IBM Plex Mono) — meta text, timestamps, score
  // numerals, status/eyebrow labels. Never headings, never button text.
  // Sizes/weights/letter-spacing unchanged from the mono era. ----
  static TextStyle meta({double size = 13, FontWeight weight = FontWeight.w500, Color? color, double? letterSpacing}) {
    return TextStyle(
      fontFamily: _bodyFamily,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing ?? 0.2,
      color: color ?? AppColors.textSecondary,
    );
  }

  /// Uppercase eyebrow/status-chip style — mirrors web's `.eyebrow` /
  /// `.status-card-label` (small, wide tracking, uppercase — now Inter,
  /// matching web's own mono→Inter label conversion). Apply
  /// `.toUpperCase()` to the string at the call site; this only sets style.
  static TextStyle metaLabel({Color? color}) {
    return TextStyle(
      fontFamily: _bodyFamily,
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      color: color ?? AppColors.textSecondary,
    );
  }
}
