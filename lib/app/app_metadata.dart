abstract final class AppMetadata {
  static const appName = 'Calcademy';
  static const name = appName;
  static const applicationId = 'com.aligundogan.calcademy';
  static const publisherName = 'Ali Gündoğan';
  static const versionName = '1.0.0';
  static const buildNumber = 4;
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
  static const String privacyPolicyUrl =
      'https://synnergndgn.github.io/Calcademy/privacy_policy';
  static const privacyPolicyEffectiveDate = '2026-07-21';

  static Uri? get privacyPolicyUri => parsePublicHttpsUrl(privacyPolicyUrl);

  static Uri? parsePublicHttpsUrl(String? value) {
    final uri = value == null ? null : Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    final host = uri.host.toLowerCase();
    const blockedHosts = {
      'example.com',
      'example.org',
      'example.net',
      'localhost',
    };
    final isPlaceholder = blockedHosts.any(
      (blocked) => host == blocked || host.endsWith('.$blocked'),
    );
    if (isPlaceholder ||
        host.endsWith('.invalid') ||
        host.endsWith('.test') ||
        host.endsWith('.local')) {
      return null;
    }
    return uri;
  }
}
