/// User roles across the platform.
/// The DB column `profiles.role` (added in Stage 4) stores these as lowercase
/// strings.  The default role for existing rows is [UserRole.student].
enum UserRole {
  student,
  company,
  admin;

  static UserRole fromString(String value) => switch (value.toLowerCase()) {
        'company' => UserRole.company,
        'admin'   => UserRole.admin,
        _         => UserRole.student,
      };
}
