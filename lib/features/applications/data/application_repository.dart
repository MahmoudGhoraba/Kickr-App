import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/database_constants.dart';
import 'package:kickr/features/applications/data/application_model.dart';

class ApplicationRepository {
  const ApplicationRepository(this._supabase);

  final SupabaseClient _supabase;

  // ─── Student-facing ──────────────────────────────────────────────────────────

  Future<List<Application>> fetchUserApplications(String userId) async {
    final response = await _supabase
        .from(DatabaseConstants.applications)
        .select(
            '*, internship:${DatabaseConstants.internships}(*, company:${DatabaseConstants.companies}(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response.map(Application.fromJson).toList();
  }

  Future<Application> submitApplication({
    required String userId,
    required String internshipId,
    required String cvUrl,
  }) async {
    final response = await _supabase
        .from(DatabaseConstants.applications)
        .insert({
          'user_id': userId,
          'internship_id': internshipId,
          'cv_url': cvUrl,
          'status': 'pending',
        })
        .select(
            '*, internship:${DatabaseConstants.internships}(*, company:${DatabaseConstants.companies}(*))')
        .single();

    final app = Application.fromJson(response);

    // Fire-and-forget: notify the company owner of the new application.
    // Runs server-side via Edge Function — never send FCM directly from client.
    _notifyCompanyOfApplication(app).ignore();

    return app;
  }

  Future<void> _notifyCompanyOfApplication(Application app) async {
    try {
      final internship = app.internship;
      if (internship == null) return;
      final ownerId = internship.company?.ownerId;
      if (ownerId == null) return;

      await _supabase.functions.invoke(
        'send-notification',
        body: {
          'targetUserId': ownerId,
          'title': 'New application received',
          'body': 'Someone applied to "${internship.title}"',
          'data': {'internshipId': internship.id},
        },
      );
    } catch (_) {
      // Notification is non-critical; silently ignore failures.
    }
  }

  // ─── Profile CV helpers ───────────────────────────────────────────────────────

  Future<String?> fetchUserCvUrl(String userId) async {
    final response = await _supabase
        .from(DatabaseConstants.profiles)
        .select('cv_url')
        .eq('id', userId)
        .maybeSingle();

    return response?['cv_url'] as String?;
  }

  Future<void> updateUserCvUrl({
    required String userId,
    required String cvUrl,
  }) async {
    await _supabase
        .from(DatabaseConstants.profiles)
        .update({'cv_url': cvUrl}).eq('id', userId);
  }

  // ─── Company-facing foundation ────────────────────────────────────────────────

  /// Returns applications for a specific internship.
  /// Company-side read — no internship join needed (they already know it).
  Future<List<Application>> fetchApplicationsForInternship(
      String internshipId) async {
    final response = await _supabase
        .from(DatabaseConstants.applications)
        .select('*')
        .eq('internship_id', internshipId)
        .order('created_at', ascending: false);

    return response.map(Application.fromJson).toList();
  }
}
