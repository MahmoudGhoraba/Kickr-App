import 'package:kickr/core/constants/role_constants.dart';

/// Mirrors the `profiles` table.
/// `role` is nullable — DB column added in Stage 4, absent rows treated as student.
/// `academicYear` and `profileCompleted` added in Stage 5 profile-completion pass.
class Profile {
  const Profile({
    required this.id,
    required this.createdAt,
    this.fullName,
    this.university,
    this.major,
    this.bio,
    this.skills = const [],
    this.cvUrl,
    this.avatarUrl,
    this.role,
    this.academicYear,
    this.profileCompleted = false,
  });

  final String id;
  final DateTime createdAt;
  final String? fullName;
  final String? university;
  final String? major;
  final String? bio;
  final List<String> skills;
  final String? cvUrl;
  final String? avatarUrl;

  /// Null until the `profiles.role` column is added in Stage 4.
  /// Treated as [UserRole.student] by role-checking helpers when null.
  final UserRole? role;

  /// Student's current academic year (e.g. "3rd Year", "Fresh Graduate").
  final String? academicYear;

  /// True once the student has completed the mandatory profile setup flow.
  /// Defaults to false — drives the GoRouter redirect to CompleteProfileScreen.
  final bool profileCompleted;

  UserRole get effectiveRole => role ?? UserRole.student;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        fullName: json['full_name'] as String?,
        university: json['university'] as String?,
        major: json['major'] as String?,
        bio: json['bio'] as String?,
        skills: (json['skills'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        cvUrl: json['cv_url'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] != null
            ? UserRole.fromString(json['role'] as String)
            : null,
        academicYear: json['academic_year'] as String?,
        profileCompleted: json['profile_completed'] as bool? ?? false,
      );

  Map<String, dynamic> toUpdateJson() => {
        if (fullName != null) 'full_name': fullName,
        if (university != null) 'university': university,
        if (major != null) 'major': major,
        if (bio != null) 'bio': bio,
        'skills': skills,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (academicYear != null) 'academic_year': academicYear,
        'profile_completed': profileCompleted,
      };
}
