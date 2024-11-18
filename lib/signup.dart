import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _collegeHandledController =
      TextEditingController(); // New controller for College Handled
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Function to insert a new guidance counselor into the database
  Future<void> _signUp() async {
    final firstname = _firstnameController.text.trim();
    final lastname = _lastnameController.text.trim();
    final email = _emailController.text.trim();
    final collegeHandled = _collegeHandledController.text.trim();
    final password = _passwordController.text.trim();

    // Ensure all fields are filled
    if (firstname.isEmpty ||
        lastname.isEmpty ||
        email.isEmpty ||
        collegeHandled.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required.')),
      );
      return;
    }

    try {
      // Insert the new user into the database
      final response =
          await Supabase.instance.client.from('guidancecounselor').insert({
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'college_handled': collegeHandled,
        'password': password, // Note: Use hashed passwords in production
      }).execute();

      // Check the response status
      if (response.status == 201) {
        // Account creation successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created successfully!')),
        );
        Navigator.pop(context); // Navigate back to the login page
      } else {
        // Handle errors using response.status
        final errorMessage = response.data != null
            ? 'Unknown error occurred'
            : 'Failed to create account';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMessage')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 3),
                  Image.asset(
                    'assets/title.png',
                    width: 500,
                    height: 100,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Create an Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00848B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Firstname TextField
                  SizedBox(
                    width: 300,
                    child: _buildCustomTextField(
                      controller: _firstnameController,
                      labelText: 'Firstname',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your firstname';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Lastname TextField
                  SizedBox(
                    width: 300,
                    child: _buildCustomTextField(
                      controller: _lastnameController,
                      labelText: 'Lastname',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your lastname';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Email TextField
                  SizedBox(
                    width: 300,
                    child: _buildCustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // College Handled TextField
                  SizedBox(
                    width: 300,
                    child: _buildCustomTextField(
                      controller: _collegeHandledController,
                      labelText: 'College Handled',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the college handled';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Password TextField
                  SizedBox(
                    width: 300,
                    child: _buildCustomTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Confirm Password TextField
                  SizedBox(
                    width: 300,
                    child: _buildCustomTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      isPassword: true,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sign Up Button
                  SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _signUp(); // Call the sign-up function
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00848B),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Log In section
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Navigate back to login
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCBE2BB),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: const Text(
                            'Log In',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Custom TextField Builder
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: Color(0xFF00848B),
          fontSize: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFF2F7F5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFF00848B),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFF00848B),
            width: 2.0,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      ),
      validator: validator,
    );
  }
}
