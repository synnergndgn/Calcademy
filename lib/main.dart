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

  // Start the app first. Ads must never delay or crash startup, so the app is
  // running before any Mobile Ads / UMP work begins.
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const CalcademyApp(),
    ),
  );

  // Fire-and-forget, fully guarded: any ad/consent failure leaves the app
  // running ad-free instead of crashing. Inert on unsupported platforms/tests.
  unawaited(_initializeAdsSafely());
}

Future<void> _initializeAdsSafely() async {
  try {
    final ready = await AdService.ensureInitialized();
    if (!ready) return;
    await ConsentService.gatherIfRequired();
  } on Object catch (error, stackTrace) {
    debugPrint(
      'Ads bootstrap failed (continuing ad-free): $error\n$stackTrace',
    );
  }
}
