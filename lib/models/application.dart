class Application {
  Application({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.orgName,
    required this.status,
    required this.createdAt,
  });

  /// GET /applications/me nests job fields under `job: {id, title, orgName,
  /// ...}`; flattened here since the UI only ever needs these five fields
  /// together.
  factory Application.fromJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>;
    return Application(
      id: json['id'] as String,
      jobId: job['id'] as String,
      jobTitle: job['title'] as String,
      orgName: job['orgName'] as String? ?? '',
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String jobId;
  final String jobTitle;
  final String orgName;
  final String status;
  final DateTime createdAt;
}
