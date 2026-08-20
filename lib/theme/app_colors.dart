import 'package:flutter/material.dart';

/// Raw token scale translated 1:1 from design_refs/brand-tokens.css (the
/// web app's source of truth). This class is a faithful mirror of the CSS
/// custom properties — it does not encode any app-specific usage rules.
/// [AppColors] below is the layer that actually decides what gets used
/// where; reach for that first, and only touch [BrandColors] directly when
/// wiring a new semantic role into [AppColors].
///
/// As of the Nocturne import (see [AppColors]'s own doc comment), the
/// `brand*` indigo-violet ramp below is entirely unconsumed — [AppColors]'
/// primary/interactive roles moved to Nocturne's own accent tokens. Kept
/// here rather than deleted, same reasoning as the two bands below: this
/// class's job is being a complete, faithful mirror of brand-tokens.css,
/// not just of whatever [AppColors] currently reaches for.
///
/// Three token bands from the CSS aren't consumed anywhere in this class:
///   - `brand50/100/200/400/600/800/900`: superseded by Nocturne's accent
///     family for every role [AppColors] used to draw these from.
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

/// App-facing color roles. This is what every screen/widget imports.
///
/// As of the Nocturne import (see the surfaces/text/brand section doc
/// comments above): [background], [surface], [surfaceElevated], [border],
/// [textPrimary]/[textSecondary]/[textTertiary], and [primary]/
/// [primarySoft]/[primaryFill]/[primaryMuted] all come from
/// nocturne-styles.css. [coral]/[success]/[warning]/[error] below are
/// deliberately UNCHANGED, still built on [BrandColors] — Nocturne defines
/// no warm/coral hue and no semantic success/warning/error tokens at all
/// (it's a single indigo/blurple + neutral palette), so there is nothing
/// in the source to import for these roles. Re-theming them would mean
/// inventing colors with no basis in the design being implemented.
///  - Re-checked against the new (slightly lighter) Nocturne [background]:
///    [BrandColors.success] 5.20:1 and [BrandColors.warning] 4.74:1 both
///    still clear 4.5:1, though warning's margin is tighter than before.
///  - [BrandColors.error] drops to 4.15:1 against the new background — it
///    was already documented "background-fill only, just under AA"
///    (never used for text-on-dark), so this doesn't change its contract.
///    [errorBright], the text/icon/border variant actually used on
///    [background]/[surface], is still comfortably clear at 5.71:1.
///  - Coral ([BrandColors.accent600]) is intentionally rationed to exactly
///    the earned-badge treatment (see [coral] doc below) — never a second
///    UI element, never a generic accent.
class AppColors {
  AppColors._();

  // ---- Surfaces — Nocturne palette (design import, claude.ai/design
  // project 8cae981e-8ca7-4a23-b995-d2ac92a4ea26, "Candidate Portal.dc.html"
  // + nocturne-styles.css). Replaces the prior brand-tokens.css-derived
  // dark foundation with Nocturne's own --color-bg/--color-surface. ----
  /// Scaffold/page background. Nocturne --color-bg.
  static const Color background = Color(0xFF161826);
  /// Card / elevated-content surface (one step up from [background]).
  /// Nocturne --color-surface — also what Nocturne uses for its nav bar;
  /// see [surfaceElevated] doc for why this app keeps a third tier anyway.
  static const Color surface = Color(0xFF232532);
  /// App bar, nav bar, dialogs, bottom sheets (one step up from [surface]).
  /// Nocturne itself has no third surface tier (its card/nav/dialog all
  /// share --color-surface) — this app keeps its existing 3-tier
  /// hierarchy for the same structural reason it had one before (dialogs
  /// and sheets need to read as "above" the cards behind them), extending
  /// Nocturne's own bg→surface step by the same proportion one tier further.
  static const Color surfaceElevated = Color(0xFF2B2E3D);
  /// Hairline borders/dividers. Nocturne --color-divider: #e9e9ed at 16%
  /// alpha (was plain white at 12%).
  static const Color border = Color(0x29E9E9ED);

  // ---- Text (on [background] / [surface]) ----
  /// Primary text/icons. Nocturne --color-text (#e9e9ed). Contrast vs
  /// [background]: 16.6:1.
  static const Color textPrimary = Color(0xFFE9E9ED);
  /// Secondary text (captions, meta lines) — textPrimary at 70% alpha.
  /// Contrast vs [background]: ~10.9:1. Safe for body text.
  static const Color textSecondary = Color(0xB3E9E9ED);
  /// Tertiary text — disabled labels, placeholders, hint text ONLY.
  /// textPrimary at 40% alpha. Meets the large-text/UI-component AA floor
  /// but NOT the 4.5:1 normal-body-text floor, so never use this for
  /// readable paragraph copy.
  static const Color textTertiary = Color(0x66E9E9ED);

  // ---- Brand — primary interactive color: buttons, active nav item,
  // links, progress bars, the home CTA. Nocturne --color-accent family. ----
  /// Text/icon/fill color for anything interactive rendered directly on a
  /// dark surface (5.45:1 vs [background]). This is the one to reach for
  /// almost everywhere — active nav, links, progress indicators, chip
  /// borders/labels. Nocturne --color-accent (#9184d9).
  static const Color primary = Color(0xFF9184D9);
  /// [primary] at 16% alpha — selected-state/tinted backgrounds (nav
  /// indicator pill, info chip fills).
  static const Color primarySoft = Color(0x299184D9);
  /// Filled primary button background. A *background*, not a foreground —
  /// pair with white text (6.78:1), not with itself as text/icon color on
  /// dark (fails AA body text). Nocturne's own .btn-primary is actually an
  /// outlined/text style with no filled variant (see AppTheme's doc
  /// comment on filledButtonTheme) — this app keeps its existing
  /// filled-vs-outlined *pattern* (a solid CTA distinct from a bordered
  /// secondary action) and recolors it with Nocturne's darker
  /// --color-accent-700, the closest in-family tone that clears white-text
  /// AA.
  static const Color primaryFill = Color(0xFF5D5294);
  /// Soft/secondary emphasis — wired into ColorScheme.secondary. Nothing
  /// else in this app currently needs it directly; reach for [primary]
  /// first. Nocturne --color-accent-2 (#a7a1db) — the system's own second
  /// accent hue.
  static const Color primaryMuted = Color(0xFFA7A1DB);

  // ---- Coral — rationed to exactly one UI element: the earned/verified
  // badge treatment (BadgeCard's medallion + its level pill on the Badges
  // screen). Never a generic accent, never a second CTA. Deliberately NOT
  // re-themed by the Nocturne import — Nocturne's palette has no warm hue
  // at all (indigo/blurple + neutral only), so there's no source color to
  // import here; still [BrandColors.accent600] from the pre-Nocturne
  // brand-tokens.css mirror. ----
  static const Color coral = BrandColors.accent600;
  /// [coral] at 16% alpha — the medallion/pill's tinted background.
  static const Color coralSoft = Color(0x29E85A3A);

  // ---- Success — status meaning only (a completed/passing state).
  // General "verified" signals that aren't the one coral-rationed badge
  // element (external-credential chips, profile/home badge-count stats,
  // the reusable SkillBadge chip) live here. Deliberately NOT re-themed —
  // Nocturne defines no semantic success token; see [coral] doc above for
  // why these roles stay on the old [BrandColors] mirror. ----
  static const Color success = BrandColors.success;
  static const Color successSoft = Color(0x291D9E75);

  // ---- Warning — same "no Nocturne equivalent" reasoning as [success]. ----
  static const Color warning = BrandColors.warning;
  static const Color warningSoft = Color(0x29BA7517);

  // ---- Error — same "no Nocturne equivalent" reasoning as [success]. ----
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
  /// Same reasoning as [googleBrandBlue] — GitHub's own near-black mark
  /// color for the "Sign in with GitHub" glyph.
  static const Color githubBrandBlack = Color(0xFF181717);
}

/// Spacing scale. Unchanged by the Nocturne import: nocturne-styles.css's
/// own --space-1..--space-8 (2.8/5.6/8.4/11.2/16.8/22.4px) is this exact
/// scale scaled by a uniform ×0.7 — i.e. the same 4px-base scale rendered
/// at the design canvas's phone-frame zoom, not a distinct set of values.
/// Kept as the pre-existing 4px-base numbers rather than importing the
/// scaled-down ones.
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

/// Border radius scale. sm/md/lg adopt nocturne-styles.css's
/// --radius-sm/md/lg exactly (4/8/14 — lg was already 14). [full] has no
/// Nocturne token to import (its pill/circle shapes use inline 50%/99px,
/// not a named radius) so it's kept at the prior effectively-round value.
class AppRadius {
  AppRadius._();

  static const double sm = 4;
  static const double md = 8;
  static const double lg = 14;
  static const double full = 999;
}

/// Elevation shadows. nocturne-styles.css's --shadow-sm/md/lg pair a
/// solid-color 1px "ring" (`0 0 0 1px <color>`) with a blur component on
/// md/lg only. The ring is already provided by this app's existing card
/// border ([AppColors.border] via CardTheme's [BorderSide]/[AppCard]), so
/// only the blur component is imported here — sm has none in the source
/// (hence the empty list), md/lg take Nocturne's blur/offset/color
/// (opacity converted to this app's 0-255 alpha) as-is.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> sm = [];
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x8C000000), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0xA6000000), blurRadius: 40, offset: Offset(0, 16)),
  ];
}
