import 'package:kickr/features/internships/data/internship_model.dart';

class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.userId,
    required this.label,
    required this.createdAt,
    this.keyword,
    this.internshipType,
  });

  final String id;
  final String userId;
  final String label;
  final DateTime createdAt;
  final String? keyword;
  final InternshipType? internshipType;

  factory SavedSearch.fromJson(Map<String, dynamic> json) => SavedSearch(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        label: json['label'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        keyword: json['keyword'] as String?,
        internshipType: json['internship_type'] != null
            ? InternshipType.fromString(json['internship_type'] as String)
            : null,
      );
}
