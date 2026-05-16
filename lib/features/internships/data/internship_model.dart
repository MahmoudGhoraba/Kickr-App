import 'package:kickr/features/internships/data/company_model.dart';

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
    this.company,
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
  final Company? company;

  factory Internship.fromJson(Map<String, dynamic> json) => Internship(
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
        company: json['company'] != null
            ? Company.fromJson(json['company'] as Map<String, dynamic>)
            : null,
      );
}
