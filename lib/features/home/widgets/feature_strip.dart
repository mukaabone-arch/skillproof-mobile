import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Animated five-stage journey strip — the Home screen's footer flourish,
/// mirroring web's components/FeatureStrip.tsx exactly: Verify skills →
/// Earn badges → Match roles → Interview → Get hired on a connecting rail
/// a highlight travels along, 1.5s per stage on a 7.5s loop, with the rail
/// filling progressively behind the active node.
///
/// Token mapping from web (this app is dark-only, so roles translate, not
/// raw hexes — see AppColors' own class doc):
///   --indigo active fill  → [AppColors.primaryFill] under white (the
///                           filled-button pairing), rail fill [AppColors.primary]
///   --brand-50 rest wash  → [AppColors.primarySoft] under [AppColors.primary]
///   --ink-12 rail/border  → [AppColors.border]
///   --ink-60 inactive     → [AppColors.textSecondary]
///   --card node surface   → [AppColors.surface]
/// No new colors, no gradients, no new fonts, no packages — icons are the
/// bundled Material outlined set.
///
/// Reduced motion ([MediaQuery.disableAnimationsOf]) renders web's static
/// "journey complete" state: rail filled, every node resting in the
/// primarySoft/primary pairing, no controller running.
class FeatureStrip extends StatefulWidget {
  const FeatureStrip({super.key});

  @override
  State<FeatureStrip> createState() => _FeatureStripState();
}

class _Stage {
  final String label;
  final IconData icon;
  const _Stage(this.label, this.icon);
}

const List<_Stage> _stages = [
  _Stage('Verify skills', Icons.verified_user_outlined),
  _Stage('Earn badges', Icons.workspace_premium_outlined),
  _Stage('Match roles', Icons.track_changes),
  _Stage('Interview', Icons.chat_bubble_outline),
  _Stage('Get hired', Icons.work_outline),
];

/// 1.5s per stage × 5 stages.
const Duration _loop = Duration(milliseconds: 7500);
const int _stageCount = 5;

class _FeatureStripState extends State<FeatureStrip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: _loop);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Checked here (not initState) so a runtime toggle of the OS
    // reduce-motion setting takes effect without a restart.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// How "active" stage [i] is at loop position [t] ∈ [0,1) — the same
  /// envelope as web's keyframes: within a stage's 20% window, ease up over
  /// the first 15%, hold, ease back down over the last 25%.
  double _activation(int i, double t) {
    final u = (t - i / _stageCount) * _stageCount;
    if (u < 0 || u >= 1) return 0;
    if (u < 0.15) return Curves.easeOut.transform(u / 0.15);
    if (u < 0.75) return 1;
    return 1 - Curves.easeIn.transform((u - 0.75) / 0.25);
  }

  /// Rail-fill fraction: the fill front arrives at node i's position
  /// (i/4 of the span) exactly as that stage's window opens, easing within
  /// each segment so the advance reads as surge-then-settle, matching
  /// web's per-keyframe easing.
  double _fillFraction(double t) {
    final seg = (t * _stageCount).floor();
    if (seg >= _stageCount - 1) return 1;
    final v = t * _stageCount - seg;
    return (seg + Curves.easeInOut.transform(v)) / (_stageCount - 1);
  }

  /// Smooth loop reset, as on web: hold the full rail, fade it out, snap
  /// back while invisible, fade the (near-empty) fill in on the next pass.
  double _fillOpacity(double t) {
    if (t < 0.02) return t / 0.02;
    if (t < 0.88) return 1;
    if (t < 0.96) return 1 - (t - 0.88) / 0.08;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Your SkillProof journey: verify your skills, earn badges, match with roles, interview, and get hired.',
      container: true,
      child: ExcludeSemantics(
        child: Container(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
          padding: const EdgeInsets.only(top: AppSpacing.space5, bottom: AppSpacing.space2),
          child: RepaintBoundary(
            child: reduced
                ? _Rail(activations: List.filled(_stageCount, 0), fill: 1, fillOpacity: 1, resting: true)
                : AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = _controller.value;
                      return _Rail(
                        activations: List.generate(_stageCount, (i) => _activation(i, t)),
                        fill: _fillFraction(t),
                        fillOpacity: _fillOpacity(t),
                        resting: false,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  final List<double> activations;
  final double fill;
  final double fillOpacity;

  /// Reduced-motion "journey complete" state: fill full, every node in the
  /// primarySoft/primary resting wash instead of the inactive surface look.
  final bool resting;

  const _Rail({required this.activations, required this.fill, required this.fillOpacity, required this.resting});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final nodeSize = compact ? 28.0 : 34.0;
        // Rail spans first to last node center — columns are 20% of the
        // width each, so the centers sit at 10% and 90%.
        final inset = constraints.maxWidth * 0.1;
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              left: inset,
              right: inset,
              top: nodeSize / 2 - 1.5,
              height: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: ColoredBox(
                  color: AppColors.border,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fill.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: ColoredBox(color: AppColors.primary.withValues(alpha: fillOpacity)),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _stages.length; i++)
                  Expanded(child: _StageColumn(stage: _stages[i], activation: activations[i], nodeSize: nodeSize, resting: resting)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StageColumn extends StatelessWidget {
  final _Stage stage;
  final double activation;
  final double nodeSize;
  final bool resting;

  const _StageColumn({required this.stage, required this.activation, required this.nodeSize, required this.resting});

  @override
  Widget build(BuildContext context) {
    final a = activation;
    final Color circleColor;
    final Color borderColor;
    final Color iconColor;
    final Color labelColor;
    if (resting) {
      circleColor = AppColors.primarySoft;
      borderColor = Colors.transparent;
      iconColor = AppColors.primary;
      labelColor = AppColors.textSecondary;
    } else {
      circleColor = Color.lerp(AppColors.surface, AppColors.primaryFill, a)!;
      borderColor = Color.lerp(AppColors.border, AppColors.primaryFill, a)!;
      iconColor = Color.lerp(AppColors.textSecondary, Colors.white, a)!;
      labelColor = Color.lerp(AppColors.textSecondary, AppColors.textPrimary, a)!;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: Offset(0, -3 * a),
          child: Transform.scale(
            scale: 1 + 0.08 * a,
            child: Container(
              width: nodeSize,
              height: nodeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
                border: Border.all(color: borderColor, width: 1.5),
                // AppShadows.sm's geometry, surfacing with the lift — no
                // shadow at rest, exactly web's active-only --shadow-sm.
                boxShadow: a == 0
                    ? null
                    : [BoxShadow(color: Color.fromARGB((0x40 * a).round(), 0, 0, 0), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(stage.icon, size: nodeSize < 30 ? 14 : 16, color: iconColor),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Opacity(
          opacity: resting ? 1 : 0.7 + 0.3 * a,
          child: Text(
            stage.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTypography.labelSmall.copyWith(fontSize: 10, height: 1.25, color: labelColor),
          ),
        ),
      ],
    );
  }
}
