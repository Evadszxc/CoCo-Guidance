import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConnection {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://thmrzgktprlvjpfooeyi.supabase.co/', // Your Supabase URL
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRobXJ6Z2t0cHJsdmpwZm9vZXlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjQ1MjY1OTEsImV4cCI6MjA0MDEwMjU5MX0.790U_hZqTh61lxy7GGRMesMgTO4Y9DmPsTiWsaWIyS0', // Your Supabase anon key
    );
  }
}
