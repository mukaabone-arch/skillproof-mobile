import 'package:flutter/material.dart';

/// Color tokens translated from apps/web/app/globals.css, dark-adapted.
///
/// Source tokens (light theme, web):
///   --brand-purple #8b5cf6   --brand-green #22c55e   (logo colors — decorative
///     only, never UI state; see [brandPurple]/[brandGreen] below)
///   --paper #f5f6f2   --ink #141b2d   --card #fff
///   --indigo #3240b8   --indigo-dark #232e8f   --indigo-soft #e4e7fb
///   --verified #0b8a5c   --verified-soft #ddf0e7
///   --danger #b3261e   --warning #b45309
///
/// Dark adaptation notes:
///  - Background is #0F1115 — not invented, it's the exact fill color of the
///    logo's own dark chip (Logo.tsx: `fill="#0f1115"`), so the app's base
///    surface and the logo's chip disappear into each other by design.
///  - Every color meant to render as *text or an icon directly on the dark
///    background* was checked against WCAG AA (4.5:1 normal text, 3:1
///    large text / non-text UI) using the standard relative-luminance
///    formula, and brightened where the web's light-mode value fell short.
///    Two colors failed as-is and needed a dark-mode-only bright variant:
///      - brand purple #8b5cf6 on #0F1115 → 4.46:1 (fails 4.5:1 body text,
///        barely — this is the one the task called out specifically).
///        [purpleLight] #A78BFA → 6.95:1.
///      - --verified #0b8a5c on #0F1115 → 4.32:1 (also fails body text).
///        [verifiedBright] #54AD8D → 6.96:1.
///      - --indigo #3240b8 on #0F1115 → 2.31:1 (fails even large-text/UI
///        3:1 — indigo is the *primary* action color, so this matters more
///        than purple). [indigoLight] #818CF8 → 6.33:1.
///      - --danger #b3261e on #0F1115 → 2.89:1 (fails). [dangerBright]
///        #F87171 → 6.83:1.
///      - --warning #b45309 on #0F1115 → passes comfortably once brightened
///        the same way for consistency. [warningBright] #FBBF24 → 11.3:1.
///    The raw/base hues (`indigo`, `verified`, `danger`, `warning`) are kept
///    for filled surfaces (button/badge backgrounds) where a light
///    foreground sits on top of them instead — e.g. white-on-#3240B8 is
///    8.2:1, so that direction never needed adjusting.
///  - --verified is used *exclusively* for verified skills/badges/
///    certificates, per the web app's own rule (see the comment on
///    --verified in globals.css). It must never be reached for for
///    progress, success toasts, or any other "good/done" signal — those
///    all use [indigo]/[indigoLight]. This file does not export a generic
///    "success" color on purpose, to make that mistake harder to make.
class AppColors {
  AppColors._();

  // ---- Surfaces ----
  /// Scaffold/page background. Same hex as the logo's own chip fill.
  static const Color background = Color(0xFF0F1115);
  /// Card / elevated-content surface (one step up from [background]).
  static const Color surface = Color(0xFF16181D);
  /// App bar, nav bar, dialogs, bottom sheets (one step up from [surface]).
  static const Color surfaceElevated = Color(0xFF1C1F26);
  /// Hairline borders/dividers — white at 12% alpha, the dark-mode mirror
  /// of web's --ink-12.
  static const Color border = Color(0x1FFFFFFF);

  // ---- Text (on [background] / [surface]) ----
  /// Primary text/icons. Same hex as web's --paper (#f5f6f2) — the light
  /// theme's *background* becomes the dark theme's *foreground*.
  /// Contrast vs [background]: 17.4:1.
  static const Color textPrimary = Color(0xFFF5F6F2);
  /// Secondary text (captions, meta lines) — textPrimary at 70% alpha.
  /// Contrast vs [background]: 7.9:1. Safe for body text.
  static const Color textSecondary = Color(0xB3F5F6F2);
  /// Tertiary text — disabled labels, placeholders, hint text ONLY.
  /// textPrimary at 40% alpha. Contrast vs [background]: 3.6:1 — meets the
  /// large-text/UI-component AA floor but NOT the 4.5:1 normal-body-text
  /// floor, so never use this for readable paragraph copy.
  static const Color textTertiary = Color(0x66F5F6F2);

  // ---- Brand (decorative only — logo, marketing accents. Never a UI
  // state color; see class doc.) ----
  static const Color brandPurple = Color(0xFF8B5CF6);
  static const Color brandGreen = Color(0xFF22C55E);

  /// Brand purple, brightened for direct use as text/icons on dark
  /// surfaces (6.95:1 vs [background]) — the raw [brandPurple] falls just
  /// short of AA (4.46:1) at normal text sizes on this background.
  static const Color purpleLight = Color(0xFFA78BFA);

  // ---- Indigo — primary actions, progress, links (never green; see
  // class doc) ----
  /// Filled-button / solid-fill background. White text on top of this is
  /// 8.2:1 — only use as a *background*, not as text/icon color on dark.
  static const Color indigo = Color(0xFF3240B8);
  static const Color indigoDark = Color(0xFF232E8F);
  /// Indigo brightened for text/icons/progress-bar fills/links rendered
  /// directly on dark surfaces (6.33:1 vs [background]). This is the one
  /// to reach for anywhere indigo needs to *be* the foreground color rather
  /// than a button's fill.
  static const Color indigoLight = Color(0xFF818CF8);
  /// Soft tinted background (selected nav item, info banners) — indigoLight
  /// at 16% alpha over [surface].
  static const Color indigoSoft = Color(0x29818CF8);

  // ---- Verified — exclusively skills/badges/certificates ----
  /// Filled badge/icon background, cert border. Pair with a light
  /// foreground (textPrimary) or [verifiedBright], not both raw.
  static const Color verified = Color(0xFF0B8A5C);
  /// verified, brightened for text/icons directly on dark surfaces
  /// (6.96:1 vs [background]).
  static const Color verifiedBright = Color(0xFF54AD8D);
  /// Soft tinted background for badge chips — verified at 16% alpha.
  static const Color verifiedSoft = Color(0x290B8A5C);

  // ---- Danger ----
  static const Color danger = Color(0xFFB3261E);
  /// danger, brightened for text/icons on dark (6.83:1 vs [background]).
  static const Color dangerBright = Color(0xFFF87171);
  static const Color dangerSoft = Color(0x29B3261E);

  // ---- Warning ----
  static const Color warning = Color(0xFFB45309);
  /// warning, brightened for text/icons on dark (11.3:1 vs [background]).
  static const Color warningBright = Color(0xFFFBBF24);
  static const Color warningSoft = Color(0x29B45309);
}

/// Spacing scale — identical values to web's --space-1..--space-8 (4px base).
class AppSpacing {
  AppSpacing._();

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;
  static const double space8 = 48;
}

/// Border radius scale — identical values to web's --radius-sm/md/lg/full.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double full = 999;
}

/// Elevation shadows. Same blur/spread/offset geometry as web's
/// --shadow-sm/md/lg, but recolored: web's shadows are a dark tint
/// (rgba(20,27,45,x)) meant to lift a card off a *light* page, which reads
/// as almost nothing on a dark page. Pure black at a higher alpha is what
/// actually produces visible depth against [AppColors.background]/[surface].
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x59000000), blurRadius: 60, spreadRadius: -24, offset: Offset(0, 24)),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x66000000), blurRadius: 60, spreadRadius: -20, offset: Offset(0, 24)),
  ];
}
