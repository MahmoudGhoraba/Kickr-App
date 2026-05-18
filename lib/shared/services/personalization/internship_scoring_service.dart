import 'package:kickr/features/internships/data/internship_model.dart';
import 'package:kickr/features/profile/data/profile_model.dart';

/// Returns a relevance score for [internship] against [profile].
///
/// Higher score = better match. Returns 0 when there is no overlap.
/// Scoring is deterministic and runs entirely in memory — no network calls.
///
/// Factors:
///   • Skill overlap (+15 per matching skill)
///   • Category matches major keywords (+20)
///   • Title contains major keywords (+8 per word, length > 3)
int scoreInternship(Internship internship, Profile profile) {
  var score = 0;

  // ── Skill overlap ───────────────────────────────────────────────────────────
  if (profile.skills.isNotEmpty && internship.requiredSkills.isNotEmpty) {
    final profileSkills =
        profile.skills.map((s) => s.toLowerCase()).toSet();
    final internshipSkills =
        internship.requiredSkills.map((s) => s.toLowerCase()).toSet();
    score += profileSkills.intersection(internshipSkills).length * 15;
  }

  // ── Major → category / title keywords ────────────────────────────────────
  final major = (profile.major ?? '').toLowerCase().trim();
  if (major.isNotEmpty) {
    final category = (internship.category ?? '').toLowerCase();
    final title = internship.title.toLowerCase();

    if (category.isNotEmpty &&
        (major.contains(category) || category.contains(major))) {
      score += 20;
    }

    for (final word in major.split(RegExp(r'\s+'))) {
      if (word.length > 3 &&
          (title.contains(word) || category.contains(word))) {
        score += 8;
      }
    }
  }

  return score;
}
