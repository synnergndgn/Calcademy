import 'package:calcademy/app/app.dart';
import 'package:calcademy/app/auth/auth_providers.dart';
import 'package:calcademy/app/config/app_config.dart';
import 'package:calcademy/core/services/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  SupabaseClient? supabaseClient;
  if (AppConfig.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
      supabaseClient = Supabase.instance.client;
    } catch (error) {
      debugPrint('Supabase initialization unavailable: ${error.runtimeType}');
    }
  }
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        supabaseClientProvider.overrideWithValue(supabaseClient),
      ],
      child: const CalcademyApp(),
    ),
  );
}
