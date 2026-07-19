import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// primary → filled brand (web's `.btn-primary`); secondary → outlined,
/// ink-colored (web's `.btn-secondary`). Both ride on the FilledButton/
/// OutlinedButton styles set in AppTheme, so this is mainly a convenience
/// wrapper for the busy-spinner and full-width states every screen needs.
enum AppButtonVariant { primary, secondary }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = false,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool expand;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final spinnerColor = variant == AppButtonVariant.primary ? Colors.white : AppColors.textPrimary;

    final child = busy
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: spinnerColor),
          )
        : icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [icon!, const SizedBox(width: 8), Text(label)],
              );

    final button = variant == AppButtonVariant.primary
        ? FilledButton(onPressed: busy ? null : onPressed, child: child)
        : OutlinedButton(onPressed: busy ? null : onPressed, child: child);

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
