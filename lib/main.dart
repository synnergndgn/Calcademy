import 'dart:async';

import 'package:calcademy/app/ads/ad_service.dart';
import 'package:calcademy/app/ads/consent_service.dart';
import 'package:calcademy/app/app.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  // Ads are gated by AdConfig.adsEnabled: on unsupported platforms and in
  // tests both calls are inert no-ops. Consent gathering is fire-and-forget so
  // it never blocks first frame.
  await AdService.ensureInitialized();
  unawaited(ConsentService.gatherIfRequired());

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const CalcademyApp(),
    ),
  );
}
