/// GET /copilot/plan — the candidate co-pilot's ordered next steps, computed
/// server-side (apps/api/src/modules/copilot/copilot-plan.ts) so the app and
/// the website show the same suggestion. `steps.first` is what the Home
/// co-pilot card shows; the rest feed a multi-step plan card later.
class CopilotPlan {
  const CopilotPlan({required this.steps, required this.generatedAt});

  final List<CopilotStep> steps;
  final DateTime generatedAt;

  factory CopilotPlan.fromJson(Map<String, dynamic> json) => CopilotPlan(
        steps: (json['steps'] as List<dynamic>? ?? const [])
            .map((s) => CopilotStep.fromJson(s as Map<String, dynamic>))
            .toList(),
        generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class CopilotStep {
  const CopilotStep({
    required this.id,
    required this.eyebrow,
    required this.message,
    this.meta,
    this.cta,
  });

  /// Stable per suggestion, e.g. `gap:<skillId>`.
  final String id;
  final String eyebrow;
  final String message;

  /// Status/expiry line, e.g. "~40 min · expires in 3 days".
  final String? meta;

  /// Null only when there is nothing for the candidate to do (an
  /// assessment already with a reviewer).
  final CopilotCta? cta;

  factory CopilotStep.fromJson(Map<String, dynamic> json) => CopilotStep(
        id: json['id'] as String,
        eyebrow: json['eyebrow'] as String,
        message: json['message'] as String,
        meta: json['meta'] as String?,
        cta: json['cta'] == null ? null : CopilotCta.fromJson(json['cta'] as Map<String, dynamic>),
      );
}

/// Where the step's button goes. The server names a semantic [target]
/// (profile, assessments, interviews, job, …) rather than only a web URL,
/// so the app maps it to its own screens — see HeroSection.
class CopilotCta {
  const CopilotCta({
    required this.kind,
    required this.label,
    this.target,
    this.href,
    this.jobId,
    this.skillId,
    this.sessionId,
    this.requestId,
    this.level,
  });

  /// 'navigate', or 'start_assessment_request' (an employer's single-level
  /// invite — started on the web, like every other assessment).
  final String kind;
  final String label;

  /// For 'navigate': profile | assessments | assessment_session |
  /// interviews | job | jobs_matched | jobs_applications. Unknown values
  /// (a newer server) fall back to Home's badges screen in HeroSection.
  final String? target;

  /// The web path for the same destination.
  final String? href;
  final String? jobId;
  final String? skillId;
  final String? sessionId;
  final String? requestId;
  final String? level;

  factory CopilotCta.fromJson(Map<String, dynamic> json) => CopilotCta(
        kind: json['kind'] as String,
        label: json['label'] as String,
        target: json['target'] as String?,
        href: json['href'] as String?,
        jobId: json['jobId'] as String?,
        skillId: json['skillId'] as String?,
        sessionId: json['sessionId'] as String?,
        requestId: json['requestId'] as String?,
        level: json['level'] as String?,
      );
}
