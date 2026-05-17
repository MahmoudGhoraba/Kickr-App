import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/database_constants.dart';
import 'package:kickr/features/internships/data/internship_model.dart';
import 'package:kickr/features/internships/data/saved_search_model.dart';

class SavedSearchRepository {
  const SavedSearchRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<SavedSearch>> fetchSavedSearches(String userId) async {
    final response = await _supabase
        .from(DatabaseConstants.savedSearches)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response.map(SavedSearch.fromJson).toList();
  }

  Future<SavedSearch> saveSearch({
    required String userId,
    required String label,
    String? keyword,
    InternshipType? internshipType,
  }) async {
    final response = await _supabase
        .from(DatabaseConstants.savedSearches)
        .insert({
          'user_id': userId,
          'label': label,
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (internshipType != null) 'internship_type': internshipType.name,
        })
        .select()
        .single();

    return SavedSearch.fromJson(response);
  }

  Future<void> deleteSavedSearch(String searchId) async {
    await _supabase
        .from(DatabaseConstants.savedSearches)
        .delete()
        .eq('id', searchId);
  }
}
