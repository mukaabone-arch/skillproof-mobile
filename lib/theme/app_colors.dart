import 'package:flutter/material.dart';

/// Raw token scale translated 1:1 from design_refs/brand-tokens.css (the
/// web app's source of truth). This class is a faithful mirror of the CSS
/// custom properties — it does not encode any app-specific usage rules.
/// [AppColors] below is the layer that actually decides what gets used
/// where; reach for that first, and only touch [BrandColors] directly when
/// wiring a new semantic role into [AppColors].
///
/// Two token bands from the CSS aren't consumed anywhere in this class:
///   - `gray50..900`: the web scale is a *light*-theme neutral ramp (page
///     background, borders, text on a white page). This app's dark
///     foundation (background/surface/text hierarchy in [AppColors]) is a
///     separate, already-tuned set of near-black surfaces and is out of
///     scope for this pass — see the note on that section.
///   - `brand800`/`brand900`: the CSS marks these "text on brand-50/100
///     backgrounds" and "dark panels, hero, footer" — both light-theme-page
///     roles this app doesn't have. Kept here so the class stays a complete
///     mirror of the CSS.
class BrandColors {
  BrandColors._();

  // ---- Brand: indigo-violet ----
  static const Color brand50 = Color(0xFFEEEDFE);
  static const Color brand100 = Color(0xFFCECBF6);
  static const Color brand200 = Color(0xFFAFA9EC);
  static const Color brand400 = Color(0xFF7F77DD);
  static const Color brand600 = Color(0xFF5B4FE0);
  static const Color brand800 = Color(0xFF3C3489);
  static const Color brand900 = Color(0xFF26215C);

  // ---- Accent: warm coral (rationed — see [AppColors.coral]) ----
  static const Color accent50 = Color(0xFFFFF1EC);
  static const Color accent100 = Color(0xFFFFD9CB);
  static const Color accent400 = Color(0xFFFF8A65);
  static const Color accent600 = Color(0xFFE85A3A);
  static const Color accent800 = Color(0xFF8A2E1A);

  // ---- Neutrals (light-theme ramp; unused here, see class doc) ----
  static const Color gray50 = Color(0xFFF7F7F9);
  static const Color gray100 = Color(0xFFEBEBF0);
  static const Color gray300 = Color(0xFFC7C6D1);
  static const Color gray600 = Color(0xFF6E6D7A);
  static const Color gray900 = Color(0xFF18171F);

  // ---- Semantic (status only — never for brand/decoration) ----
  static const Color success = Color(0xFF1D9E75);
  static const Color warning = Color(0xFFBA7517);
  static const Color error = Color(0xFFD9483F);
}

/// App-facing color roles, built on top of [BrandColors]. This is what
/// every screen/widget imports.
///
/// Dark adaptation notes (this app is dark-only, the web tokens are
/// light-theme-first, so which shade "leads" a family differs):
///  - The surface/text hierarchy below is the app's own dark foundation —
///    unrelated to and unchanged by the brand-tokens.css rebrand. It was
///    tuned and WCAG-checked independently (background is the exact fill
///    of the logo's own dark chip) and this pass only re-keys accent
///    colors on top of it.
///  - Interactive/brand colors reach for [BrandColors.brand400] wherever
///    they render as text/icons/fills *directly on* the dark
///    background/surface (buttons' text-adjacent roles, links, active nav,
///    progress fills): 5.03:1 against [background], comfortably AA. Filled
///    button backgrounds are the one place [BrandColors.brand600] (the
///    web's "THE primary") is used as-is — it's a solid fill with white
///    text on top, not text-on-dark itself, and white-on-brand600 is
///    5.77:1, AA-safe.
///  - [BrandColors.success]/[BrandColors.warning] both clear 4.5:1 against
///    [background] (5.58:1 / 5.08:1) unbrightened, unlike the old
///    green/amber they replace — no dark-mode-only bright variant needed.
///  - [BrandColors.error] is 4.45:1 against [background] — a hair under
///    the 4.5:1 body-text floor. [errorBright] is the same hue lightened
///    to 6.12:1 for text/icon/border use directly on dark; [error] itself
///    stays available for the rare background-fill case.
///  - Coral ([BrandColors.accent600]) is intentionally rationed to exactly
///    the earned-badge treatment (see [coral] doc below) — never a second
///    UI element, never a generic accent.
class AppColors {
  AppColors._();

  // ---- Surfaces ----
  /// Scaffold/page background. Same hex as the logo's own chip fill.
  static const Color background = Color(0xFF0F1115);
  /// Card / elevated-content surface (one step up from [background]).
  static const Color surface = Color(0xFF16181D);
  /// App bar, nav bar, dialogs, bottom sheets (one step up from [surface]).
  static const Color surfaceElevated = Color(0xFF1C1F26);
  /// Hairline borders/dividers — white at 12% alpha.
  static const Color border = Color(0x1FFFFFFF);

  // ---- Text (on [background] / [surface]) ----
  /// Primary text/icons. Contrast vs [background]: 17.4:1.
  static const Color textPrimary = Color(0xFFF5F6F2);
  /// Secondary text (captions, meta lines) — textPrimary at 70% alpha.
  /// Contrast vs [background]: 7.9:1. Safe for body text.
  static const Color textSecondary = Color(0xB3F5F6F2);
  /// Tertiary text — disabled labels, placeholders, hint text ONLY.
  /// textPrimary at 40% alpha. Contrast vs [background]: 3.6:1 — meets the
  /// large-text/UI-component AA floor but NOT the 4.5:1 normal-body-text
  /// floor, so never use this for readable paragraph copy.
  static const Color textTertiary = Color(0x66F5F6F2);

  // ---- Brand — primary interactive color: buttons, active nav item,
  // links, progress bars, the home CTA. ----
  /// Text/icon/fill color for anything interactive rendered directly on a
  /// dark surface (5.03:1 vs [background]). This is the one to reach for
  /// almost everywhere — active nav, links, progress indicators, chip
  /// borders/labels.
  static const Color primary = BrandColors.brand400;
  /// [primary] at 16% alpha — selected-state/tinted backgrounds (nav
  /// indicator pill, info chip fills).
  static const Color primarySoft = Color(0x297F77DD);
  /// Filled primary button background. A *background*, not a foreground —
  /// pair with white text (5.77:1), not with itself as text/icon color on
  /// dark (3.28:1, fails AA body text).
  static const Color primaryFill = BrandColors.brand600;
  /// Soft/secondary emphasis — wired into ColorScheme.secondary. Nothing
  /// else in this app currently needs it directly; reach for [primary]
  /// first.
  static const Color primaryMuted = BrandColors.brand200;

  // ---- Coral — rationed to exactly one UI element: the earned/verified
  // badge treatment (BadgeCard's medallion + its level pill on the Badges
  // screen). Never a generic accent, never a second CTA. ----
  static const Color coral = BrandColors.accent600;
  /// [coral] at 16% alpha — the medallion/pill's tinted background.
  static const Color coralSoft = Color(0x29E85A3A);

  // ---- Success — status meaning only (a completed/passing state).
  // General "verified" signals that aren't the one coral-rationed badge
  // element (external-credential chips, profile/home badge-count stats,
  // the reusable SkillBadge chip) live here. ----
  static const Color success = BrandColors.success;
  static const Color successSoft = Color(0x291D9E75);

  // ---- Warning ----
  static const Color warning = BrandColors.warning;
  static const Color warningSoft = Color(0x29BA7517);

  // ---- Error ----
  /// Background-fill use only (see class doc) — 4.45:1 as text/icon on
  /// dark, just under AA. Use [errorBright] for anything rendered directly
  /// on [background]/[surface].
  static const Color error = BrandColors.error;
  /// error, brightened for text/icons/borders on dark (6.12:1 vs
  /// [background]).
  static const Color errorBright = Color(0xFFE2716A);
  static const Color errorSoft = Color(0x29D9483F);

  // ---- Third-party brand requirement — NOT part of the token system.
  // Google's own brand blue for the "Sign in with Google" glyph; Google's
  // brand guidelines fix this exact hue regardless of app theme. ----
  static const Color googleBrandBlue = Color(0xFF4285F4);
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
