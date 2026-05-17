import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/database_constants.dart';
import 'package:kickr/features/internships/data/internship_model.dart';

class InternshipRepository {
  const InternshipRepository(this._supabase);

  final SupabaseClient _supabase;

  // ─── Feed ─────────────────────────────────────────────────────────────────────

  Future<List<Internship>> fetchInternships() async {
    final response = await _supabase
        .from(DatabaseConstants.internships)
        .select('*, company:${DatabaseConstants.companies}(*)')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return response.map(Internship.fromJson).toList();
  }

  // Server-side search extension point for Stage 4:
  // Add fetchInternships({String? query, InternshipType? type, int limit, int offset})
  // using .ilike('title', '%$query%') and .range(offset, offset + limit - 1).

  // ─── Detail ───────────────────────────────────────────────────────────────────

  Future<Internship> fetchInternshipById(String id) async {
    final response = await _supabase
        .from(DatabaseConstants.internships)
        .select('*, company:${DatabaseConstants.companies}(*)')
        .eq('id', id)
        .single();

    return Internship.fromJson(response);
  }

  // ─── Saved internships ────────────────────────────────────────────────────────

  Future<Set<String>> fetchSavedInternshipIds(String userId) async {
    final response = await _supabase
        .from(DatabaseConstants.savedInternships)
        .select('internship_id')
        .eq('user_id', userId);

    return response.map((r) => r['internship_id'] as String).toSet();
  }

  Future<void> saveInternship({
    required String userId,
    required String internshipId,
  }) async {
    await _supabase.from(DatabaseConstants.savedInternships).insert({
      'user_id': userId,
      'internship_id': internshipId,
    });
  }

  Future<void> unsaveInternship({
    required String userId,
    required String internshipId,
  }) async {
    await _supabase
        .from(DatabaseConstants.savedInternships)
        .delete()
        .match({'user_id': userId, 'internship_id': internshipId});
  }

  // ─── View tracking ────────────────────────────────────────────────────────────

  /// Records that [userId] viewed [internshipId]. Silently ignores duplicates
  /// (UNIQUE constraint on (internship_id, viewer_id) → onConflict: ignore).
  Future<void> trackView({
    required String internshipId,
    required String userId,
  }) async {
    await _supabase.from(DatabaseConstants.internshipViews).upsert(
      {
        'internship_id': internshipId,
        'viewer_id': userId,
      },
      onConflict: 'internship_id,viewer_id',
    );
  }
}
