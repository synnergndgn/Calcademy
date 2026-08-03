import 'dart:io';

import 'package:flutter/foundation.dart';

/// Single, central source of truth for AdMob identifiers and gating.
///
/// The real AdMob identifiers live here and nowhere else — never in signing
/// secrets, `local.properties`, or `key.properties`. Debug and profile builds
/// serve Google's official *test* banner so development never generates
/// invalid traffic on the real unit; only release builds serve the real unit.
///
/// Ads run only on real mobile targets. Widget and unit tests execute on the
/// host VM (where `dart:io`'s [Platform] reports the desktop OS), so
/// [adsEnabled] is `false` throughout the test suite and no Mobile Ads plugin
/// call is ever made from a test.
abstract final class AdConfig {
  /// Android AdMob *application* id, tilde form. Mirrored in
  /// `AndroidManifest.xml` as the `com.google.android.gms.ads.APPLICATION_ID`
  /// meta-data; the two must stay in sync.
  static const androidAppId = 'ca-app-pub-5164539069315402~1162467024';

  /// Production banner ad *unit*, slash form (Android). Served in release
  /// builds only. Deliberately never declared in the manifest — app id and unit
  /// id are different namespaces and must not be interchanged.
  static const bannerAdUnitId = 'ca-app-pub-5164539069315402/4507529677';

  /// Google's official sample banner unit. Used in debug/profile so we never
  /// serve real ads (or risk policy strikes) while developing.
  /// https://developers.google.com/admob/flutter/test-ads
  static const testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  /// Publisher id used by `app-ads.txt`. The real value must be copied from the
  /// AdMob console; it is intentionally left `null` so no fabricated id ever
  /// ships. See `docs/app_ads_txt_setup.md`.
  static const String? appAdsTxtPublisherId = null;

  /// Comma-separated AdMob test device ids, supplied at build time:
  ///
  /// ```
  /// flutter build apk --release --dart-define=ADMOB_TEST_DEVICE_IDS=ABC123,DEF456
  /// ```
  ///
  /// A *release* build serves the real ad unit, so manually testing one would
  /// otherwise generate real impressions on the production unit — and any tap
  /// would be invalid traffic against the AdMob account. Registering the test
  /// device makes Google serve test ads from the real unit id instead, which is
  /// safe to interact with.
  ///
  /// Deliberately an environment value rather than a source constant: a
  /// personal device id can never be committed by accident, and omitting the
  /// define leaves production behaviour byte-for-byte unchanged.
  static const String _testDeviceIdsRaw = String.fromEnvironment(
    'ADMOB_TEST_DEVICE_IDS',
  );

  /// Parsed [_testDeviceIdsRaw]; empty in every normal build.
  static List<String> get testDeviceIds => _testDeviceIdsRaw
      .split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList(growable: false);

  /// Whether this build registers any AdMob test device.
  static bool get hasTestDevices => testDeviceIds.isNotEmpty;

  /// Whether the Mobile Ads SDK may run at all. `false` on web, desktop, and
  /// every test — so ad code is inert there and can never crash or overflow.
  static bool get adsEnabled {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Debug and profile builds use the test unit; only release uses the real
  /// unit.
  static bool get useTestAds => !kReleaseMode;

  /// The banner unit to request for the current build flavour.
  static String get activeBannerAdUnitId =>
      useTestAds ? testBannerAdUnitId : bannerAdUnitId;

  /// Fails fast before a release ships a broken configuration: the real app id
  /// and banner unit must be well-formed AdMob identifiers and free of any
  /// leftover placeholder token.
  static bool isValidReleaseConfig() =>
      _isValidAppId(androidAppId) && _isValidUnitId(bannerAdUnitId);

  static final _appIdPattern = RegExp(r'^ca-app-pub-\d{16}~\d{6,}$');
  static final _unitIdPattern = RegExp(r'^ca-app-pub-\d{16}/\d{6,}$');

  static bool _isValidAppId(String value) =>
      _appIdPattern.hasMatch(value) && !_looksLikePlaceholder(value);

  static bool _isValidUnitId(String value) =>
      _unitIdPattern.hasMatch(value) && !_looksLikePlaceholder(value);

  static bool _looksLikePlaceholder(String value) {
    final lower = value.toLowerCase();
    return lower.contains('xxxx') ||
        lower.contains('todo') ||
        lower.contains('placeholder');
  }
}
