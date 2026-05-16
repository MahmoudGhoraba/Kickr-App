/// Supabase table name constants.
/// Use these in every repository `.from(...)` call instead of raw strings.
abstract final class DatabaseConstants {
  static const String profiles         = 'profiles';
  static const String companies        = 'companies';
  static const String internships      = 'internships';
  static const String savedInternships = 'saved_internships';
  static const String applications     = 'applications';
}
