import 'package:flutter/material.dart';
import 'package:guidance/home.dart'; // Navigate to Home page after login
import 'signup.dart'; // Navigate to Sign-up page
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final SupabaseClient supabase = Supabase.instance.client;

  // Function to verify credentials and sign in using Supabase
  Future<bool> _verifyCredentials(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if session and user exist
      if (response.session != null && response.user != null) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      print('Error during login: $error');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: Form with title image
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/title.png',
                      width: 700,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 16.0),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 400,
                              child: TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                  fillColor: Colors.grey[200],
                                  filled: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                      .hasMatch(value)) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 16.0),
                            SizedBox(
                              width: 400,
                              child: TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
                                  fillColor: Colors.grey[200],
                                  filled: true,
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 24.0),
                            SizedBox(
                              width: 400,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    bool isValid = await _verifyCredentials(
                                      _emailController.text,
                                      _passwordController.text,
                                    );

                                    if (isValid) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('Login successful')),
                                      );

                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Home(
                                            email: _emailController.text,
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('Invalid credentials')),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF00848B),
                                ),
                                child: Text(
                                  'Log In',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.0),
                            SizedBox(
                              width: 400,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SignUpPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFCBE2BB),
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 32.0), // Space between form and image
              Image.asset(
                'assets/coco.png',
                width: 500,
                height: 500,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
