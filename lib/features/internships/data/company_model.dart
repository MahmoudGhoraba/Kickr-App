class Company {
  const Company({
    required this.id,
    required this.name,
    this.logoUrl,
    this.website,
    this.description,
    this.industry,
    this.location,
    this.ownerId,
    this.companySize,
    this.cultureDescription,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? website;
  final String? description;
  final String? industry;
  final String? location;
  final String? companySize;
  final String? cultureDescription;

  /// Set when a company account created the record via the app.
  /// Null for seeded/demo companies without a linked owner account.
  final String? ownerId;

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'] as String,
        name: json['name'] as String,
        logoUrl: json['logo_url'] as String?,
        website: json['website'] as String?,
        description: json['description'] as String?,
        industry: json['industry'] as String?,
        location: json['location'] as String?,
        ownerId: json['owner_id'] as String?,
        companySize: json['company_size'] as String?,
        cultureDescription: json['culture_description'] as String?,
      );
}
