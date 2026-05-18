import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/database_constants.dart';
import 'package:kickr/features/applications/data/application_model.dart';
import 'package:kickr/features/company/data/applicant_entry.dart';
import 'package:kickr/features/internships/data/company_model.dart';
import 'package:kickr/features/internships/data/internship_model.dart';
import 'package:kickr/features/profile/data/profile_model.dart';

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
    String? companySize,
    String? cultureDescription,
    String? logoUrl,
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
          'company_size': ?companySize,
          if (cultureDescription != null && cultureDescription.isNotEmpty)
            'culture_description': cultureDescription,
          'logo_url': ?logoUrl,
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
    String? companySize,
    String? cultureDescription,
    String? logoUrl,
  }) async {
    final response = await _supabase
        .from(DatabaseConstants.companies)
        .update({
          'name': name,
          'description': description,
          'industry': industry,
          'location': location,
          'website': website,
          'company_size': companySize,
          'culture_description': cultureDescription,
          'logo_url': ?logoUrl,
        })
        .eq('id', companyId)
        .select()
        .single();

    return Company.fromJson(response);
  }

  // ─── Internship management ────────────────────────────────────────────────────

  /// Returns all internships for [companyId] regardless of is_active status
  /// so the company portal shows their full portfolio.
  /// Embedded counts for applications, saves, and views power the analytics row.
  Future<List<Internship>> fetchCompanyInternships(String companyId) async {
    final response = await _supabase
        .from(DatabaseConstants.internships)
        .select(
          '*, '
          'applications(count), '
          'saved_internships(count), '
          'internship_views(count)',
        )
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
    DateTime? deadline,
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
          if (deadline != null) 'deadline': deadline.toUtc().toIso8601String(),
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
    DateTime? deadline,
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
          'deadline': deadline?.toUtc().toIso8601String(),
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
        .select(
          'id, full_name, university, major, avatar_url, '
          'academic_year, skills, verification_status',
        )
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
        academicYear: p?['academic_year'] as String?,
        skills: (p?['skills'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        verificationStatus: VerificationStatus.fromString(
          p?['verification_status'] as String?,
        ),
      );
    }).toList();
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    final response = await _supabase
        .from(DatabaseConstants.applications)
        .update({'status': status.name})
        .eq('id', applicationId)
        .select('user_id, internship:${DatabaseConstants.internships}(title)')
        .single();

    // Fire-and-forget: notify the student of the status change.
    _notifyStudentOfStatusChange(response, status).ignore();
  }

  Future<void> _notifyStudentOfStatusChange(
    Map<String, dynamic> appData,
    ApplicationStatus status,
  ) async {
    try {
      final userId = appData['user_id'] as String?;
      if (userId == null) return;
      final internship =
          appData['internship'] as Map<String, dynamic>?;
      final title = internship?['title'] as String? ?? 'your application';

      final statusLabel = switch (status) {
        ApplicationStatus.accepted => 'Congratulations! You\'ve been accepted',
        ApplicationStatus.reviewed => 'Your application was reviewed',
        ApplicationStatus.rejected => 'Your application status was updated',
        ApplicationStatus.pending => 'Your application is pending',
      };

      await _supabase.functions.invoke(
        'send-notification',
        body: {
          'targetUserId': userId,
          'title': statusLabel,
          'body': 'Re: "$title"',
          'data': {'type': 'status_update'},
        },
      );
    } catch (_) {
      // Notification is non-critical; silently ignore failures.
    }
  }
}
