/// Supabase table name constants.
/// Use these in every repository `.from(...)` call instead of raw strings.
abstract final class DatabaseConstants {
  static const String profiles            = 'profiles';
  static const String companies           = 'companies';
  static const String internships         = 'internships';
  static const String savedInternships    = 'saved_internships';
  static const String applications        = 'applications';
  static const String internshipViews     = 'internship_views';
  static const String notificationTokens  = 'notification_tokens';
  static const String savedSearches       = 'saved_searches';
}
