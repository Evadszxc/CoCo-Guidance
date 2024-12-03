import 'package:flutter/material.dart';
import 'package:guidance/login.dart';
import 'package:guidance/home.dart'; // Import Home page
import 'supabase.dart'; // Supabase initialization logic
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase Flutter SDK
import 'package:universal_platform/universal_platform.dart'; // Platform checks for web compatibility

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase using your existing supabase.dart
  await SupabaseConnection.initialize();

  // Check if a session exists
  final session = Supabase.instance.client.auth.currentSession;

  // Get userId from session if available
  final userId = session?.user?.id;

  runApp(
    MyApp(
      initialPage: userId != null
          ? Home(userId: userId) // Pass userId to Home
          : LoginPage(), // Navigate to Login if no session
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialPage;

  MyApp({required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guidance Counselor',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: initialPage,
    );
  }
}

// Platform check for web, mobile, and desktop
bool isWeb() => UniversalPlatform.isWeb;
