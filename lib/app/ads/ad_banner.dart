import 'dart:async';

import 'package:calcademy/app/ads/ad_config.dart';
import 'package:calcademy/app/ads/ad_service.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_gate_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A low-intrusion anchored banner that reserves **no** layout space until an
/// ad has actually loaded.
///
/// This widget is also what drives Mobile Ads SDK initialization: the first
/// banner to mount calls [AdService.ensureInitialized]. Nothing touches the ads
/// SDK before `runApp`, so a native ad fault can never prevent the app from
/// starting.
///
/// When ads are disabled (every test, web, desktop), init failed, the ad has
/// not yet loaded, or loading failed (including offline), it renders
/// [SizedBox.shrink] — so it can never overflow, block interaction, or crash.
/// Safe to drop into any `bottomNavigationBar` slot.
///
/// UMP/consent is intentionally out of scope for the AdMob Retry 1.0 sprint;
/// see `docs/monetization_strategy.md`.
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key, this.enabled});

  /// Test seam. When `null`, gating falls back to [AdConfig.adsEnabled] (which
  /// is already `false` in the test host), so tests never touch the plugin.
  final bool? enabled;

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  bool get _enabled => widget.enabled ?? AdConfig.adsEnabled;

  /// Fully guarded: SDK init and ad load can each fail without ever throwing
  /// out of here or affecting the widget tree beyond staying hidden.
  Future<void> _prepareAndLoad() async {
    try {
      final ready = await AdService.ensureInitialized();
      if (!ready || !mounted) return;
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
    final removesAds = ref.watch(
      premiumGateControllerProvider.select(
        (entitlement) => entitlement.canUse(PremiumFeature.removeAds),
      ),
    );
    if (removesAds) {
      return const SizedBox.shrink(key: Key('ad-banner-premium-hidden'));
    }
    if (_enabled && !_requested) {
      _requested = true;
      unawaited(_prepareAndLoad());
    }
    final ad = _ad;
    if (!_enabled || !_loaded || ad == null) {
      return const SizedBox.shrink(key: Key('ad-banner-not-loaded'));
    }
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
