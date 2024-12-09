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
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedProfession;
  String? _selectedCollege;

  final List<String> _colleges = [
    "College of Computer Studies",
    "College of Music",
    "College of Engineering and Architecture",
    "College of Accounting and Business Education",
    "College of Arts and Humanities",
    "College of Human Environmental Sciences and Food Studies",
    "College of Medical and Biological Science",
    "College of Nursing",
    "College of Pharmacy and Chemistry",
    "College of Teacher Education"
  ];
  final List<String> _professions = [
    "Psychologist",
    "Psychometrician",
    "Guidance Counselor"
  ];

  Future<void> _signUp() async {
    final firstname = _firstnameController.text.trim();
    final lastname = _lastnameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Ensure all fields are filled before proceeding
    if (firstname.isEmpty ||
        lastname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        _selectedCollege == null ||
        _selectedProfession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required.')),
      );
      return;
    }

    try {
      // Step 1: Create user in Supabase Auth
      final AuthResponse authResponse =
          await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;

      if (user != null) {
        // Step 2: Insert user profile into the 'user_guidance_profiles' table
        final response = await Supabase.instance.client
            .from('user_guidance_profiles')
            .insert({
          'user_id': user.id,
          'firstname': firstname,
          'lastname': lastname,
          'college_handled': _selectedCollege,
          'profession': _selectedProfession,
          'profile_image_url': null, // Optional field
        }).select();

        if (response != null && response.isNotEmpty) {
          // Notify the user of successful sign-up
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully.')),
          );
          Navigator.pop(context); // Navigate back to the login page
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create user profile.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign up user.')),
        );
      }
    } catch (error) {
      // Handle exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing up: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: Scrollbar(
          thumbVisibility: true, // Make the scrollbar visible
          thickness: 8.0, // Adjust thickness for better visibility
          radius:
              Radius.circular(10.0), // Add a rounded corner to the scrollbar
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical, // Ensure vertical scrolling
            child: Center(
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
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
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
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      // College Dropdown
                      SizedBox(
                        width: 300, // Ensures consistent width for the dropdown
                        child: DropdownButtonFormField<String>(
                          value: _selectedCollege,
                          items: _colleges.map((college) {
                            return DropdownMenuItem<String>(
                              value: college,
                              child: SizedBox(
                                width:
                                    260, // Adjust width for dropdown items to fit within the container
                                child: Text(
                                  college,
                                  overflow: TextOverflow
                                      .ellipsis, // Truncate the text with ellipsis
                                  maxLines: 1, // Keep the text on a single line
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCollege = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'College Handled',
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
                          ),
                          validator: (value) =>
                              value == null ? 'Please select a college' : null,
                          // Fix for showing ellipsis in selected value
                          selectedItemBuilder: (BuildContext context) {
                            return _colleges.map<Widget>((college) {
                              return SizedBox(
                                width: 250, // Same width as the dropdown items
                                child: Text(
                                  college,
                                  overflow: TextOverflow
                                      .ellipsis, // Truncate text with ellipsis
                                  maxLines: 1,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),

                      const SizedBox(height: 10),
                      // Profession Dropdown
                      SizedBox(
                        width: 300,
                        child: DropdownButtonFormField<String>(
                          value: _selectedProfession,
                          items: _professions.map((profession) {
                            return DropdownMenuItem<String>(
                              value: profession,
                              child: Text(profession),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProfession = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Profession',
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
                          ),
                          validator: (value) => value == null
                              ? 'Please select a profession'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                            style: TextStyle(
                                color: Color.fromARGB(
                                    255, 255, 255, 255), // White color
                                fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                                // Navigate back to login page
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCBE2BB),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
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
        ));
  }

  // Custom TextField Builder with validation and controller support
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
