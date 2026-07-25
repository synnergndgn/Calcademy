import 'package:calcademy/app/ads/ad_config.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A low-intrusion anchored banner that reserves **no** layout space until an
/// ad has actually loaded.
///
/// When ads are disabled (every test, web, and desktop) or the ad has not yet
/// loaded — including permanent failure and offline — it renders
/// [SizedBox.shrink], so it can never overflow its parent, block interaction,
/// or crash. This makes it safe to drop into any `bottomNavigationBar` slot.
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
    if (_enabled) _load();
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
