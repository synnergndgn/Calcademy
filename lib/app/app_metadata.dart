abstract final class AppMetadata {
  static const appName = 'Calcademy';
  static const name = appName;
  static const versionName = '1.0.0';
  static const buildNumber = 1;
  static const versionCode = buildNumber;
  static const tagline = 'Calculate. Visualize. Optimize. Learn.';
  static const shortDescription =
      'A local-first academic workspace for calculation and engineering study.';

  // Release metadata only. User-facing equivalents remain localized.
  static const privacyStatus = 'local-first';
  static const adsStatus = 'not-included';
  static const analyticsStatus = 'not-included';
  static const cloudSyncStatus = 'not-included';

  // Populate only after each destination is final, public, and verified.
  // Null values intentionally keep external actions hidden from the UI.
  static const String? contactEmail = null;
  static const String? repositoryUrl = null;
  static const String? privacyPolicyUrl = null;

  static Uri? get privacyPolicyUri => _verifiedHttpsUri(privacyPolicyUrl);

  static Uri? _verifiedHttpsUri(String? value) {
    final uri = value == null ? null : Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }
}
