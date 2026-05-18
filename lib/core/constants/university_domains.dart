/// Egyptian university email domains for student verification.
///
/// Trusted domains grant automatic verification on submission.
/// Unrecognised .edu.eg / .edu addresses are placed in pending review.
abstract final class UniversityDomains {
  /// Domains granted auto-verification immediately on submission.
  static const List<String> trusted = [
    'aucegypt.edu',
    'students.aucegypt.edu',
    'guc.edu.eg',
    'student.guc.edu.eg',
    'student.giu-uni.de',
    'eng.asu.edu.eg',
    'asu.edu.eg',
    'stud.asu.edu.eg',
    'cu.edu.eg',
    'sci.cu.edu.eg',
    'eng.cu.edu.eg',
    'fci.cu.edu.eg',
    'commerce.cu.edu.eg',
    'alexu.edu.eg',
    'mans.edu.eg',
    'fayoum.edu.eg',
    'bsu.edu.eg',
    'bu.edu.eg',
    'svu.edu.eg',
    'nub.edu.eg',
    'aun.edu.eg',
    'lu.edu.eg',
    'miuegypt.edu.eg',
    'nile.edu.eg',
    'msa.edu.eg',
    'bue.edu.eg',
    'nu.edu.eg',
    'students.nu.edu.eg',
    'pua.edu.eg',
    'ust.edu.eg',
    'must.edu.eg',
    'o6u.edu.eg',
    'htu.edu.eg',
  ];

  /// Returns true if [email]'s domain is in the trusted list → auto-verified.
  static bool isTrustedDomain(String email) {
    final at = email.lastIndexOf('@');
    if (at < 0) return false;
    final domain = email.substring(at + 1).toLowerCase().trim();
    return trusted.contains(domain);
  }

  /// Returns true if the email domain looks like any university email.
  /// Used to gate submission — rejects obviously non-university addresses.
  static bool isUniversityEmail(String email) {
    final at = email.lastIndexOf('@');
    if (at < 0) return false;
    final domain = email.substring(at + 1).toLowerCase().trim();
    return trusted.contains(domain) ||
        domain.endsWith('.edu.eg') ||
        domain.endsWith('.ac.eg') ||
        domain.endsWith('.edu');
  }
}
