import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Surface container matching web's `.ui-card` / `.card` — a bordered,
/// low-elevation panel. Set [elevated] for the rarer "lifted off the page"
/// treatment web reserves for `.ui-card-elevated` / `.auth-card`
/// (onboarding/auth surfaces), which adds [AppShadows.md] on top of the
/// same border.
///
/// Radius is [AppRadius.md] (8), matching nocturne-styles.css's own `.card`
/// rule exactly (`border-radius: var(--radius-md)`) — was [AppRadius.lg]
/// before the Nocturne import.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.space5),
    this.onTap,
    this.elevated = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: elevated ? AppShadows.md : null,
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Padding(padding: padding, child: child),
              ),
            ),
    );
    return content;
  }
}
