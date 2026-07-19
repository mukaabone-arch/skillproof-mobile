import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Skill to scroll to and briefly highlight in the "Available to verify"
/// section next time BadgesScreen builds — set by Home's co-pilot CTA when
/// its message names a specific skill (the "Close the gap" branch), so the
/// CTA and the card it lands on always agree on which skill (see
/// hero_section.dart's _handleCopilotAction). BadgesScreen consumes and
/// clears it via ref.listen rather than reading it once, since the screen
/// is kept alive in RootScreen's IndexedStack and doesn't rebuild from
/// scratch on every tab switch.
final badgesHighlightSkillIdProvider = StateProvider<String?>((ref) => null);
