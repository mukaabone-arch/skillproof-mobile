/// One skill from GET /taxonomy — mirrors apps/web/components/CandidateJobs.tsx's
/// `Skill` interface. The API groups these by domain (see JobsRepository.taxonomySkills,
/// which flattens the grouping away: this app's dropdowns are flat lists, matching
/// profile_edit_form.dart's Role field, with no optgroup-style header UI to hang a
/// domain name on).
class Skill {
  Skill({required this.id, required this.name});

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;
}
