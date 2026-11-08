import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../help/help_assistant_screen.dart';
import '../../root/root_tab_provider.dart';

/// Home's launcher: one rounded icon per feature, phone-home-screen style.
/// In-app features open by setting [rootTabIndexProvider] — RootScreen
/// listens and pushes the matching screen (see root_screen.dart), the same
/// path every other "go to X" button in the app already uses.
/// Help pushes the Ask MyAmbii assistant (help_assistant_screen.dart).
class FeatureGrid extends ConsumerWidget {
  const FeatureGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void openTab(int tab) => ref.read(rootTabIndexProvider.notifier).state = tab;

    final features = <_Feature>[
      _Feature('Jobs', Icons.work_outline, () => openTab(RootTab.jobs)),
      _Feature('Skills', Icons.verified_outlined, () => openTab(RootTab.badges)),
      _Feature('Interviews', Icons.event_note_outlined, () => openTab(RootTab.interviews)),
      _Feature('Profile', Icons.person_outline, () => openTab(RootTab.profile)),
      _Feature(
        'Help',
        Icons.help_outline,
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpAssistantScreen())),
      ),
    ];

    // Wrap rather than GridView: GridView gives every cell a fixed height
    // from its aspect ratio, which clips the label when the system text size
    // is larger. Wrap lets each tile take exactly the height it needs.
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const gap = AppSpacing.space4;
        final tileWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: AppSpacing.space5,
          children: [
            for (final f in features) SizedBox(width: tileWidth, child: _FeatureIcon(feature: f)),
          ],
        );
      },
    );
  }

}

class _Feature {
  const _Feature(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({required this.feature});
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: feature.label,
      child: InkWell(
        onTap: feature.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryFill, AppColors.primaryFill.withValues(alpha: 0.7)],
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(feature.icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              feature.label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
