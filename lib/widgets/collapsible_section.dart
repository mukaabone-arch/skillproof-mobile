import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

/// A card whose body is hidden until tapped, expanding in place — same
/// tap-to-expand chevron convention as AddCredentialForm's "How do I find
/// this?" hint (expand_more/expand_less_rounded in [AppColors.primary]),
/// scaled up to a whole section so long Profile-screen cards don't have to
/// stay permanently expanded. [summary], if given, is shown under the
/// title only while collapsed, so the card still says something useful
/// without being opened.
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    required this.title,
    required this.child,
    this.summary,
    this.initiallyExpanded = false,
    super.key,
  });

  final String title;
  final String? summary;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: AppTypography.titleMedium),
                      if (!_expanded && widget.summary != null) ...[
                        const SizedBox(height: AppSpacing.space1),
                        Text(widget.summary!, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Icon(
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.space3),
            widget.child,
          ],
        ],
      ),
    );
  }
}
