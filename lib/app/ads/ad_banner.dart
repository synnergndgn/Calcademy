import 'dart:async';

import 'package:calcademy/app/ads/ad_config.dart';
import 'package:calcademy/app/ads/ad_service.dart';
import 'package:calcademy/app/ads/consent_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A low-intrusion anchored banner that reserves **no** layout space until an
/// ad has actually loaded.
///
/// It only ever requests an ad after the SDK reports a successful init
/// ([AdService.isAvailable]) *and* consent gathering says ads may be requested.
/// When ads are disabled (every test, web, desktop), init failed, consent is
/// unavailable, the ad has not yet loaded, or loading failed (including
/// offline), it renders [SizedBox.shrink] — so it can never overflow, block
/// interaction, or crash. Safe to drop into any `bottomNavigationBar` slot.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key, this.enabled});

  /// Test seam. When `null`, gating falls back to [AdConfig.adsEnabled] (which
  /// is already `false` in the test host), so tests never touch the plugin.
  final bool? enabled;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  bool get _enabled => widget.enabled ?? AdConfig.adsEnabled;

  @override
  void initState() {
    super.initState();
    if (_enabled) unawaited(_prepareAndLoad());
  }

  /// Fully guarded: SDK init, consent, and ad load can each fail without ever
  /// throwing out of here or affecting the widget tree beyond staying hidden.
  Future<void> _prepareAndLoad() async {
    try {
      final ready = await AdService.ensureInitialized();
      if (!ready || !mounted) return;
      await ConsentService.ensureGathered();
      if (!mounted) return;
      final canRequest = await ConsentService.canRequestAds();
      if (!canRequest || !mounted) return;
      _load();
    } on Object catch (error) {
      debugPrint('AdBanner preparation failed (staying hidden): $error');
    }
  }

  void _load() {
    final ad = BannerAd(
      adUnitId: AdConfig.activeBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _loaded = true);
          } else {
            _ad?.dispose();
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_enabled || !_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: ad.size.height.toDouble(),
        child: Center(
          child: SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        ),
      ),
    );
  }
}
