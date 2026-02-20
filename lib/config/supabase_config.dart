/// Supabase Configuration
///
/// Replace these values with your actual Supabase project credentials
/// Find them in: Supabase Dashboard → Project Settings → API
class SupabaseConfig {
  // Your Supabase project URL
  // Example: 'https://xxxxxxxxxxxxx.supabase.co'
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hxfvqjcnsfndtgwartjh.supabase.co',
  );

  // Your Supabase anonymous key (public key)
  // This is safe to use in client-side code
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4ZnZxamNuc2ZuZHRnd2FydGpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2MzA2OTksImV4cCI6MjA3OTIwNjY5OX0.v-1bK8fGbSpFvCBFuS5z9JuRVQNYdVRSXp5eebE5Gs0',
  );

  // Google OAuth Web Client ID (configured in Supabase Dashboard)
  // This is used as the serverClientId for Google Sign In on Android
  // TODO: Update this with your NEW Client ID from Google Cloud Console
  static const String googleWebClientId =
      '153383158944-tfm0ordit83vft9k7j8tl2pgg6m3b92t.apps.googleusercontent.com';

  /// Check if Supabase is properly configured
  static bool get isConfigured {
    return url != 'YOUR_SUPABASE_URL_HERE' &&
        anonKey != 'YOUR_SUPABASE_ANON_KEY_HERE' &&
        url.isNotEmpty &&
        anonKey.isNotEmpty;
  }

  /// Get configuration status message
  static String get configurationMessage {
    if (!isConfigured) {
      return 'Supabase is not configured.\n\n'
          'Please add your Supabase credentials to:\n'
          'lib/config/supabase_config.dart\n\n'
          'Steps:\n'
          '1. Create a Supabase project at https://supabase.com\n'
          '2. Copy your project URL and anon key\n'
          '3. Update supabase_config.dart with your credentials\n'
          '4. Enable Google OAuth in Supabase Dashboard';
    }
    return 'Supabase is configured';
  }
}
