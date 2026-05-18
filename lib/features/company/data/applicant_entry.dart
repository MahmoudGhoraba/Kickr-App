import 'package:kickr/features/applications/data/application_model.dart';
import 'package:kickr/features/profile/data/profile_model.dart';

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
    this.verificationStatus = VerificationStatus.unverified,
  });

  final Application application;
  final String? fullName;
  final String? university;
  final String? major;
  final String? avatarUrl;
  final String? academicYear;
  final List<String> skills;

  /// The applicant's verification status — shown as a trust indicator to
  /// companies reviewing the applicant list.
  final VerificationStatus verificationStatus;

  String get displayName => fullName ?? 'Applicant';

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  /// Single-line identity summary shown beneath the applicant's name.
  String? get subtitle {
    final parts = [major, academicYear, university].nonNulls.toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
