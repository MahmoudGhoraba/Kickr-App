import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/database_constants.dart';
import 'package:kickr/features/profile/data/profile_model.dart';

class ProfileRepository {
  const ProfileRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<Profile?> fetchProfile(String userId) async {
    final response = await _supabase
        .from(DatabaseConstants.profiles)
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response != null ? Profile.fromJson(response) : null;
  }

  /// Updates editable profile fields. Never changes `id` or `created_at`.
  Future<Profile> updateProfile({
    required String userId,
    required Map<String, dynamic> fields,
  }) async {
    final response = await _supabase
        .from(DatabaseConstants.profiles)
        .update(fields)
        .eq('id', userId)
        .select()
        .single();

    return Profile.fromJson(response);
  }
}
