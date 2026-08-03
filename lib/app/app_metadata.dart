abstract final class AppMetadata {
  static const appName = 'Calcademy';
  static const name = appName;
  static const applicationId = 'com.aligundogan.calcademy';
  static const publisherName = 'Ali Gündoğan';
  static const versionName = '1.3.0';
  static const buildNumber = 12;
  static const versionCode = buildNumber;
  static const tagline = 'Calculate. Visualize. Optimize. Learn.';
  static const shortDescription =
      'A local-first academic workspace for calculation and engineering study.';

  // Release metadata only. User-facing equivalents remain localized.
  // AdMob was integrated in 1.0.0+5/+6, rolled back in 1.0.0+7 after a native
  // startup crash, and re-attempted successfully in 1.0.0+8. The crash was
  // an outdated androidx.work/Room pulled in by
  // play-services-ads, not the ads SDK itself; see
  // docs/monetization_strategy.md.
  //
  // The app stays local-first for user calculation data; the only third-party
  // SDK is Google AdMob, which serves a banner and processes ad/device
  // identifiers per its own policy. See docs/privacy_policy.md.
  static const privacyStatus = 'local-first';
  static const adsStatus = 'admob-banner';
  static const analyticsStatus = 'not-included';
  static const cloudSyncStatus = 'not-included';

  // Populate only after each destination is final, public, and verified.
  // Null values intentionally keep external actions hidden from the UI.
  static const String? contactEmail = null;
  static const String? repositoryUrl = null;
  static const String privacyPolicyUrl =
      'https://synnergndgn.github.io/Calcademy/privacy_policy';
  static const privacyPolicyEffectiveDate = '2026-07-25';

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
