import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/database_constants.dart';
import 'package:kickr/features/applications/data/application_model.dart';
import 'package:kickr/features/company/data/applicant_entry.dart';
import 'package:kickr/features/internships/data/company_model.dart';
import 'package:kickr/features/internships/data/internship_model.dart';

class CompanyRepository {
  const CompanyRepository(this._supabase);

  final SupabaseClient _supabase;

  // ─── Company profile ──────────────────────────────────────────────────────────

  /// Returns the company owned by [userId], or null if none exists yet.
  Future<Company?> fetchCompanyByOwner(String userId) async {
    final response = await _supabase
        .from(DatabaseConstants.companies)
        .select()
        .eq('owner_id', userId)
        .maybeSingle();

    return response != null ? Company.fromJson(response) : null;
  }

  Future<Company> createCompany({
    required String ownerId,
    required String name,
    String? description,
    String? industry,
    String? location,
    String? website,
  }) async {
    final response = await _supabase
        .from(DatabaseConstants.companies)
        .insert({
          'name': name,
          'owner_id': ownerId,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (industry != null && industry.isNotEmpty) 'industry': industry,
          if (location != null && location.isNotEmpty) 'location': location,
          if (website != null && website.isNotEmpty) 'website': website,
        })
        .select()
        .single();

    return Company.fromJson(response);
  }

  Future<Company> updateCompany({
    required String companyId,
    required String name,
    String? description,
    String? industry,
    String? location,
    String? website,
  }) async {
    final response = await _supabase
        .from(DatabaseConstants.companies)
        .update({
          'name': name,
          'description': description,
          'industry': industry,
          'location': location,
          'website': website,
        })
        .eq('id', companyId)
        .select()
        .single();

    return Company.fromJson(response);
  }

  // ─── Internship management ────────────────────────────────────────────────────

  /// Returns all internships for [companyId] regardless of is_active status
  /// so the company portal shows their full portfolio.
  Future<List<Internship>> fetchCompanyInternships(String companyId) async {
    final response = await _supabase
        .from(DatabaseConstants.internships)
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return response.map(Internship.fromJson).toList();
  }

  Future<Internship> createInternship({
    required String companyId,
    required String title,
    required String description,
    String? shortDescription,
    required String location,
    required InternshipType type,
    String? category,
    List<String> requiredSkills = const [],
  }) async {
    final response = await _supabase
        .from(DatabaseConstants.internships)
        .insert({
          'company_id': companyId,
          'title': title,
          'description': description,
          if (shortDescription != null && shortDescription.isNotEmpty)
            'short_description': shortDescription,
          'location': location,
          'type': type.name,
          if (category != null && category.isNotEmpty) 'category': category,
          'required_skills': requiredSkills,
          'is_active': true,
        })
        .select()
        .single();

    return Internship.fromJson(response);
  }

  Future<Internship> updateInternship({
    required String internshipId,
    required String title,
    required String description,
    String? shortDescription,
    required String location,
    required InternshipType type,
    String? category,
    List<String> requiredSkills = const [],
    required bool isActive,
  }) async {
    final response = await _supabase
        .from(DatabaseConstants.internships)
        .update({
          'title': title,
          'description': description,
          'short_description':
              (shortDescription?.isNotEmpty ?? false) ? shortDescription : null,
          'location': location,
          'type': type.name,
          'category': (category?.isNotEmpty ?? false) ? category : null,
          'required_skills': requiredSkills,
          'is_active': isActive,
        })
        .eq('id', internshipId)
        .select()
        .single();

    return Internship.fromJson(response);
  }

  /// Soft delete — sets is_active = false so applications are preserved.
  Future<void> archiveInternship(String internshipId) async {
    await _supabase
        .from(DatabaseConstants.internships)
        .update({'is_active': false}).eq('id', internshipId);
  }

  // ─── Applicant review ─────────────────────────────────────────────────────────

  /// Returns applications with applicant profile data for the given internship.
  /// Two queries: applications, then profiles for the applicant user IDs.
  Future<List<ApplicantEntry>> fetchApplicants(String internshipId) async {
    final appResponse = await _supabase
        .from(DatabaseConstants.applications)
        .select()
        .eq('internship_id', internshipId)
        .order('created_at', ascending: false);

    if (appResponse.isEmpty) return [];

    final applications = appResponse.map(Application.fromJson).toList();
    final userIds = applications.map((a) => a.userId).toList();

    final profileResponse = await _supabase
        .from(DatabaseConstants.profiles)
        .select('id, full_name, university, major, avatar_url')
        .inFilter('id', userIds);

    final profileMap = <String, Map<String, dynamic>>{
      for (final p in profileResponse) p['id'] as String: p,
    };

    return applications.map((app) {
      final p = profileMap[app.userId];
      return ApplicantEntry(
        application: app,
        fullName: p?['full_name'] as String?,
        university: p?['university'] as String?,
        major: p?['major'] as String?,
        avatarUrl: p?['avatar_url'] as String?,
      );
    }).toList();
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    await _supabase
        .from(DatabaseConstants.applications)
        .update({'status': status.name}).eq('id', applicationId);
  }
}
