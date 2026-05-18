abstract final class AppConstants {
  /// Deep-link URI used as the email confirmation redirect on sign-up.
  /// Registered in ios/Runner/Info.plist as the custom URL scheme.
  static const String emailRedirectUri = 'kickr://login-callback';

  /// Maximum permitted CV file size (5 MB).
  static const int cvMaxBytes = 5 * 1024 * 1024;

  /// Maximum permitted avatar image size (2 MB).
  static const int avatarMaxBytes = 2 * 1024 * 1024;

  /// Maximum permitted student ID image size (5 MB).
  static const int studentIdMaxBytes = 5 * 1024 * 1024;
}
