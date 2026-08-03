abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isSupabaseConfigured => isValidSupabaseConfiguration(
    url: supabaseUrl,
    publicKey: supabaseAnonKey,
  );

  static bool isValidSupabaseConfiguration({
    required String url,
    required String publicKey,
  }) {
    final uri = Uri.tryParse(url.trim());
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        publicKey.trim().isNotEmpty;
  }
}
