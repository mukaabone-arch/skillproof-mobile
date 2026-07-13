import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Renders a job description with real paragraph/list structure instead of
/// one undifferentiated block. Mirrors
/// apps/web/components/ui/JobDescription.tsx exactly — see that file's doc
/// comment for why: source descriptions carry single `\n` line breaks but no
/// blank-line paragraph separation and (for the demo fixture) no bullet
/// markers, so splitting each line into its own spaced block is what
/// actually fixes the "wall of text" read, regardless of source; consecutive
/// marker-prefixed lines (-, *, •, "1.") group into a real bullet list for
/// descriptions that do use them.
class JobDescription extends StatelessWidget {
  const JobDescription({required this.description, super.key});

  final String description;

  static final _listMarkerRe = RegExp(r'^(?:[-*•]|\d+[.)])\s+(.*)$');

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(description);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space3),
            child: block is _ListBlock
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in block.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.space1),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('•  ', style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
                              Expanded(child: Text(item, style: AppTypography.bodyLarge)),
                            ],
                          ),
                        ),
                    ],
                  )
                : Text((block as _ParagraphBlock).text, style: AppTypography.bodyLarge),
          ),
      ],
    );
  }

  List<_DescriptionBlock> _parseBlocks(String description) {
    final lines = description
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final blocks = <_DescriptionBlock>[];
    for (final line in lines) {
      final match = _listMarkerRe.firstMatch(line);
      if (match != null) {
        final last = blocks.isNotEmpty ? blocks.last : null;
        if (last is _ListBlock) {
          last.items.add(match.group(1)!);
        } else {
          blocks.add(_ListBlock([match.group(1)!]));
        }
      } else {
        blocks.add(_ParagraphBlock(line));
      }
    }
    return blocks;
  }
}

sealed class _DescriptionBlock {}

class _ParagraphBlock extends _DescriptionBlock {
  _ParagraphBlock(this.text);
  final String text;
}

class _ListBlock extends _DescriptionBlock {
  _ListBlock(this.items);
  final List<String> items;
}
