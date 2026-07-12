import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles translated from web's type system (globals.css):
///   --font-display: 'Bricolage Grotesque'  (headings)
///   --font-body:    'Instrument Sans'      (body copy, buttons)
///   --font-mono:    'IBM Plex Mono'        (labels, meta, eyebrows, status chips)
///
/// All three are loaded via google_fonts, which mirrors Google Fonts'
/// catalog exactly, so no substitution was needed for any of them —
/// Bricolage Grotesque, Instrument Sans, and IBM Plex Mono are all present
/// there. (If `google_fonts` on your machine resolves to a version whose
/// generated font list predates Bricolage Grotesque's addition and
/// `GoogleFonts.bricolageGrotesque` fails to resolve, the closest
/// available substitute is `GoogleFonts.spaceGrotesk` — same geometric,
/// slightly-quirky grotesque-display character. Swap it in
/// [AppTypography._display] and nowhere else needs to change.)
///
/// Sizes are converted 1:1 from web's rem scale (1rem = 16px) — the two
/// responsive `clamp()` sizes (--text-2xl/-3xl) are pinned to their clamp
/// *minimum*, which is what they resolve to on a phone-width viewport.
///   --text-xs .72rem→12  --text-sm .85rem→14(rounded from 13.6)
///   --text-base 1rem→16  --text-lg 1.05rem→17(rounded)
///   --text-xl 1.3rem→21(rounded)
///   --text-2xl clamp(1.7rem,...)→27   --text-3xl clamp(2.4rem,...)→38
///
/// Only the fontFamily/size/weight axis maps onto Flutter's TextTheme
/// slots below — mono is deliberately kept *out* of the TextTheme (it
/// would otherwise leak into things like button labels, which
/// Material pulls from `labelLarge`) and exposed as standalone styles
/// ([mono], [monoLabel]) for widgets that explicitly want it: SkillBadge,
/// ScoreBar, status/meta chips — matching exactly where web reaches for
/// --font-mono (.mono, .eyebrow, .ui-badge, status-card-label).
class AppTypography {
  AppTypography._();

  static TextStyle _display({required double size, required FontWeight weight, double? letterSpacing, double? height}) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle _body({required double size, required FontWeight weight, double? height, Color? color}) {
    return GoogleFonts.instrumentSans(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? AppColors.textPrimary,
    );
  }

  // ---- Display / headline (Bricolage Grotesque) ----
  static final TextStyle displayLarge = _display(size: 38, weight: FontWeight.w800, letterSpacing: -0.6, height: 1.08);
  static final TextStyle headlineMedium = _display(size: 27, weight: FontWeight.w700, letterSpacing: -0.4, height: 1.15);
  static final TextStyle headlineSmall = _display(size: 21, weight: FontWeight.w700, letterSpacing: -0.2, height: 1.2);

  // ---- Titles (Instrument Sans, semibold) ----
  static final TextStyle titleMedium = _body(size: 17, weight: FontWeight.w600, height: 1.3);
  static final TextStyle titleSmall = _body(size: 16, weight: FontWeight.w600, height: 1.3);

  // ---- Body (Instrument Sans) ----
  static final TextStyle bodyLarge = _body(size: 16, weight: FontWeight.w400, height: 1.5);
  static final TextStyle bodyMedium = _body(size: 14, weight: FontWeight.w400, height: 1.5, color: AppColors.textSecondary);
  static final TextStyle bodySmall = _body(size: 12, weight: FontWeight.w400, height: 1.4, color: AppColors.textSecondary);

  // ---- Labels (Instrument Sans, semibold — this is what buttons render
  // with, so it deliberately stays on the body font, not mono) ----
  static final TextStyle labelLarge = _body(size: 15, weight: FontWeight.w600, height: 1.2);
  static final TextStyle labelMedium = _body(size: 13, weight: FontWeight.w600, height: 1.2);
  static final TextStyle labelSmall = _body(size: 11, weight: FontWeight.w600, height: 1.2);

  // ---- Mono (IBM Plex Mono) — meta text, timestamps, score numerals,
  // status/eyebrow labels. Never headings, never button text. ----
  static TextStyle mono({double size = 13, FontWeight weight = FontWeight.w500, Color? color, double? letterSpacing}) {
    return GoogleFonts.ibmPlexMono(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing ?? 0.2,
      color: color ?? AppColors.textSecondary,
    );
  }

  /// Uppercase eyebrow/status-chip style — mirrors web's `.eyebrow` /
  /// `.status-card-label` (mono, small, wide tracking, uppercase). Apply
  /// `.toUpperCase()` to the string at the call site; this only sets style.
  static TextStyle monoLabel({Color? color}) {
    return GoogleFonts.ibmPlexMono(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      color: color ?? AppColors.textSecondary,
    );
  }
}
