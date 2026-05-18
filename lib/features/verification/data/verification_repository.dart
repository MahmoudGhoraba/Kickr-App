import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/database_constants.dart';
import 'package:kickr/core/constants/storage_constants.dart';
import 'package:kickr/core/constants/university_domains.dart';
import 'package:kickr/features/profile/data/profile_model.dart';

class VerificationRepository {
  const VerificationRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Submits [email] as the student's university email.
  ///
  /// If the domain is in [UniversityDomains.trusted], the account is
  /// auto-verified immediately. Otherwise the status becomes pending and
  /// an admin reviews it manually. Returns the resulting status.
  Future<VerificationStatus> submitUniversityEmail({
    required String userId,
    required String email,
  }) async {
    final isTrusted = UniversityDomains.isTrustedDomain(email);
    final newStatus =
        isTrusted ? VerificationStatus.verified : VerificationStatus.pending;

    await _supabase.from(DatabaseConstants.profiles).update({
      'university_email': email.trim().toLowerCase(),
      'verification_status': newStatus.name,
      if (isTrusted) 'verified_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);

    return newStatus;
  }

  /// Uploads a student ID image to the private verification bucket and
  /// sets verification_status to pending for manual admin review.
  Future<void> uploadStudentId({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = StorageConstants.studentIdPath(userId, extension);

    await _supabase.storage
        .from(StorageConstants.verificationBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _imageContentType(extension),
            upsert: true,
          ),
        );

    // Store path (not public URL) — bucket is restricted to service role.
    await _supabase.from(DatabaseConstants.profiles).update({
      'student_id_url': path,
      'verification_status': VerificationStatus.pending.name,
    }).eq('id', userId);
  }

  String _imageContentType(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
}
