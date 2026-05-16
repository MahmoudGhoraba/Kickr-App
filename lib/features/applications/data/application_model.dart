import 'package:kickr/features/internships/data/internship_model.dart';

enum ApplicationStatus {
  pending,
  reviewed,
  accepted,
  rejected;

  String get label => switch (this) {
        ApplicationStatus.pending => 'Pending',
        ApplicationStatus.reviewed => 'Reviewed',
        ApplicationStatus.accepted => 'Accepted',
        ApplicationStatus.rejected => 'Rejected',
      };

  static ApplicationStatus fromString(String value) =>
      switch (value.toLowerCase()) {
        'reviewed' => ApplicationStatus.reviewed,
        'accepted' => ApplicationStatus.accepted,
        'rejected' => ApplicationStatus.rejected,
        _ => ApplicationStatus.pending,
      };
}

class Application {
  const Application({
    required this.id,
    required this.userId,
    required this.internshipId,
    required this.cvUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.internship,
  });

  final String id;
  final String userId;
  final String internshipId;
  final String cvUrl;
  final ApplicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Internship? internship;

  factory Application.fromJson(Map<String, dynamic> json) => Application(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        internshipId: json['internship_id'] as String,
        cvUrl: json['cv_url'] as String,
        status: ApplicationStatus.fromString(
            json['status'] as String? ?? 'pending'),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        internship: json['internship'] != null
            ? Internship.fromJson(
                json['internship'] as Map<String, dynamic>)
            : null,
      );
}
