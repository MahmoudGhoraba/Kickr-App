import 'package:kickr/features/profile/data/profile_model.dart';

/// A student's verification record as seen by an admin reviewer.
class VerificationReviewEntry {
  const VerificationReviewEntry({
    required this.userId,
    required this.verificationStatus,
    required this.createdAt,
    this.fullName,
    this.university,
    this.universityEmail,
    this.studentIdUrl,
    this.avatarUrl,
    this.verifiedAt,
  });

  final String userId;
  final VerificationStatus verificationStatus;
  final DateTime createdAt;
  final String? fullName;
  final String? university;

  /// University email submitted for verification (may differ from auth email).
  final String? universityEmail;

  /// Private storage path of the uploaded student ID, or null if none uploaded.
  final String? studentIdUrl;
  final String? avatarUrl;
  final DateTime? verifiedAt;

  bool get hasStudentId =>
      studentIdUrl != null && studentIdUrl!.isNotEmpty;

  bool get hasUniversityEmail =>
      universityEmail != null && universityEmail!.isNotEmpty;

  String get displayName => fullName ?? 'Unknown Student';

  factory VerificationReviewEntry.fromJson(Map<String, dynamic> json) =>
      VerificationReviewEntry(
        userId: json['id'] as String,
        fullName: json['full_name'] as String?,
        university: json['university'] as String?,
        universityEmail: json['university_email'] as String?,
        studentIdUrl: json['student_id_url'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        verificationStatus: VerificationStatus.fromString(
          json['verification_status'] as String?,
        ),
        verifiedAt: json['verified_at'] != null
            ? DateTime.parse(json['verified_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
