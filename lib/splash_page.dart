import 'package:flutter/material.dart';
import 'home.dart';
import 'login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = supabase.auth.currentSession;

    if (session != null && session.user != null) {
      // User is logged in, navigate to the Home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Home(email: session.user!.email!),
        ),
      );
    } else {
      // No session found, navigate to the Login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(), // Show a loading spinner
      ),
    );
  }
}
