import 'package:kickr/features/applications/data/application_model.dart';

/// Combines an [Application] with the applicant's profile data for
/// display in the company portal's applicant list.
class ApplicantEntry {
  const ApplicantEntry({
    required this.application,
    this.fullName,
    this.university,
    this.major,
    this.avatarUrl,
    this.academicYear,
    this.skills = const [],
  });

  final Application application;
  final String? fullName;
  final String? university;
  final String? major;
  final String? avatarUrl;
  final String? academicYear;
  final List<String> skills;

  String get displayName => fullName ?? 'Applicant';

  /// Single-line identity summary shown beneath the applicant's name.
  String? get subtitle {
    final parts = [major, academicYear, university].nonNulls.toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
