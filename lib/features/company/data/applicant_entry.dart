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
  });

  final Application application;
  final String? fullName;
  final String? university;
  final String? major;
  final String? avatarUrl;

  String get displayName => fullName ?? 'Applicant';

  String? get subtitle {
    final parts = [
      major,
      university,
    ].nonNulls.toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
