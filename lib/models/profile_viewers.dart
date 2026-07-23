/// GET /profiles/me/viewers — count_only for Free, full viewer detail for
/// Premium (limits.profileViewers). Mirrors
/// apps/web/components/ProfileViewersPanel.tsx's ViewersResponse exactly.
class ProfileViewer {
  ProfileViewer({required this.viewedAt, required this.source, required this.orgName});

  factory ProfileViewer.fromJson(Map<String, dynamic> json) => ProfileViewer(
        viewedAt: DateTime.parse(json['viewedAt'] as String),
        source: json['source'] as String,
        orgName: json['orgName'] as String?,
      );

  final DateTime viewedAt;
  /// Raw DETAIL_VIEW | SHORTLIST | REJECT | MESSAGE | STATUS_CHANGE.
  final String source;
  final String? orgName;
}

sealed class ProfileViewersResult {
  const ProfileViewersResult();
}

class ProfileViewersCountOnly extends ProfileViewersResult {
  const ProfileViewersCountOnly(this.count);
  final int count;
}

class ProfileViewersFull extends ProfileViewersResult {
  const ProfileViewersFull(this.viewers);
  final List<ProfileViewer> viewers;
}

ProfileViewersResult profileViewersResultFromJson(Map<String, dynamic> json) {
  if (json['mode'] == 'full') {
    return ProfileViewersFull(
      (json['viewers'] as List<dynamic>)
          .map((v) => ProfileViewer.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
  return ProfileViewersCountOnly(json['count'] as int);
}
