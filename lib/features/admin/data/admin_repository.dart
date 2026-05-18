import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/database_constants.dart';
import 'package:kickr/core/constants/storage_constants.dart';
import 'package:kickr/features/admin/data/verification_review_entry.dart';
import 'package:kickr/features/profile/data/profile_model.dart';

class AdminRepository {
  const AdminRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Fetches all student profiles ordered by creation date.
  /// Pass [statusFilter] to narrow to a specific verification state.
  Future<List<VerificationReviewEntry>> fetchVerifications({
    VerificationStatus? statusFilter,
  }) async {
    var query = _supabase
        .from(DatabaseConstants.profiles)
        .select(
          'id, full_name, university, university_email, student_id_url, '
          'avatar_url, verification_status, verified_at, created_at',
        )
        .eq('role', 'student');

    if (statusFilter != null) {
      query = query.eq('verification_status', statusFilter.name);
    }

    final response = await query.order('created_at', ascending: false);
    return response.map(VerificationReviewEntry.fromJson).toList();
  }

  Future<void> approveVerification(String userId) async {
    await _supabase.from(DatabaseConstants.profiles).update({
      'verification_status': VerificationStatus.verified.name,
      'verified_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> rejectVerification(String userId) async {
    await _supabase.from(DatabaseConstants.profiles).update({
      'verification_status': VerificationStatus.unverified.name,
      'verified_at': null,
    }).eq('id', userId);
  }

  /// Generates a 1-hour signed URL for a private student ID document.
  /// The admin RLS policy on the storage bucket must grant read access.
  Future<String> getStudentIdSignedUrl(String storagePath) async {
    return _supabase.storage
        .from(StorageConstants.verificationBucket)
        .createSignedUrl(storagePath, 3600);
  }
}
