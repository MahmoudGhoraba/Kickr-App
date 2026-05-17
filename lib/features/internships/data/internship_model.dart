import 'package:kickr/features/internships/data/company_model.dart';

class InternshipStats {
  const InternshipStats({
    this.viewCount = 0,
    this.saveCount = 0,
    this.applicationCount = 0,
  });

  final int viewCount;
  final int saveCount;
  final int applicationCount;
}

enum InternshipType {
  remote,
  onsite,
  hybrid;

  String get label => switch (this) {
        InternshipType.remote => 'Remote',
        InternshipType.onsite => 'Onsite',
        InternshipType.hybrid => 'Hybrid',
      };

  static InternshipType fromString(String value) =>
      switch (value.toLowerCase()) {
        'remote' => InternshipType.remote,
        'onsite' => InternshipType.onsite,
        'hybrid' => InternshipType.hybrid,
        _ => InternshipType.onsite,
      };
}

class Internship {
  const Internship({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    this.shortDescription,
    required this.location,
    required this.type,
    this.category,
    required this.requiredSkills,
    required this.isActive,
    required this.createdAt,
    this.deadline,
    this.company,
    this.stats,
  });

  final String id;
  final String companyId;
  final String title;
  final String description;
  final String? shortDescription;
  final String location;
  final InternshipType type;
  final String? category;
  final List<String> requiredSkills;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? deadline;
  final Company? company;
  final InternshipStats? stats;

  bool get isExpired =>
      deadline != null && deadline!.isBefore(DateTime.now());

  factory Internship.fromJson(Map<String, dynamic> json) {
    InternshipStats? stats;
    final appCount = _embeddedCount(json['applications']);
    final saveCount = _embeddedCount(json['saved_internships']);
    final viewCount = _embeddedCount(json['internship_views']);
    if (appCount != null || saveCount != null || viewCount != null) {
      stats = InternshipStats(
        applicationCount: appCount ?? 0,
        saveCount: saveCount ?? 0,
        viewCount: viewCount ?? 0,
      );
    }

    return Internship(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      shortDescription: json['short_description'] as String?,
      location: json['location'] as String,
      type: InternshipType.fromString(json['type'] as String),
      category: json['category'] as String?,
      requiredSkills: (json['required_skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String).toLocal()
          : null,
      company: json['company'] != null
          ? Company.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      stats: stats,
    );
  }

  static int? _embeddedCount(dynamic value) {
    if (value == null) return null;
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map) return first['count'] as int? ?? 0;
    }
    return null;
  }
}
