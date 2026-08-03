abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isSupabaseConfigured {
    final uri = Uri.tryParse(supabaseUrl.trim());
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        supabaseAnonKey.trim().isNotEmpty;
  }
}
