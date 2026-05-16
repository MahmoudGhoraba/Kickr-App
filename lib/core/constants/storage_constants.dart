abstract final class StorageConstants {
  /// Supabase Storage bucket that holds all CV files.
  static const String cvBucket = 'cv-files';

  /// Canonical storage path for a user's CV upload.
  /// Format: {userId}/{timestamp}_cv.pdf
  /// Matches the RLS policy path prefix in the cv-files bucket.
  static String cvPath(String userId) =>
      '$userId/${DateTime.now().millisecondsSinceEpoch}_cv.pdf';

  /// Supabase Storage bucket for user avatars.
  static const String avatarBucket = 'avatars';

  /// Fixed-name avatar path so each upload replaces the previous file.
  /// Format: {userId}/avatar.{ext}
  static String avatarPath(String userId, String ext) =>
      '$userId/avatar.$ext';
}
