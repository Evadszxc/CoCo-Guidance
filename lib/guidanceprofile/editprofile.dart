import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class EditProfile extends StatefulWidget {
  final String firstname;
  final String lastname;
  final String email;
  final String userId; // Add this field

  EditProfile({
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.userId, // Mark as required
  });

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _collegeHandledController;

  Uint8List? _profileImage;
  String? _profileImageUrl = '';
  bool isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _firstnameController = TextEditingController(text: widget.firstname);
    _lastnameController = TextEditingController(text: widget.lastname);
    _collegeHandledController = TextEditingController();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    try {
      setState(() => isLoading = true);
      final response = await Supabase.instance.client
          .from('user_guidance_profiles')
          .select()
          .eq('user_id', widget.userId) // Use user_id instead of email
          .single();

      if (response != null) {
        final data = response as Map<String, dynamic>; // Cast response to Map
        setState(() {
          _firstnameController.text = data['firstname'] ?? '';
          _lastnameController.text = data['lastname'] ?? '';
          _collegeHandledController.text = data['college_handled'] ?? '';
          _profileImageUrl = data['profile_image_url'] ?? '';
        });
      } else {
        print("Error: Failed to fetch profile data.");
      }
    } catch (e) {
      print("Error in fetchProfileData: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _profileImage = bytes;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<String?> _uploadImage(Uint8List imageBytes) async {
    final fileName =
        '${Supabase.instance.client.auth.currentUser?.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final response = await Supabase.instance.client.storage
          .from('profile_image_url')
          .uploadBinary(fileName, imageBytes,
              fileOptions: const FileOptions(upsert: true));

      if (response.isNotEmpty) {
        final publicUrl = Supabase.instance.client.storage
            .from('profile_image_url')
            .getPublicUrl(fileName);

        return publicUrl;
      } else {
        print("Error uploading image. Response: $response");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed. Please try again.')),
        );
        return null;
      }
    } catch (e) {
      print("Exception during image upload: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed. Please try again.')),
      );
      return null;
    }
  }

  Future<void> _saveProfile() async {
    String firstname = _firstnameController.text.trim();
    String lastname = _lastnameController.text.trim();
    String collegeHandled = _collegeHandledController.text.trim();

    // Use the existing profile image URL if no new image is uploaded
    String? imageUrl = _profileImageUrl;

    // Upload the image if a new one is selected
    if (_profileImage != null) {
      imageUrl = await _uploadImage(_profileImage!);
      if (imageUrl != null) {
        _profileImageUrl = imageUrl; // Update the profile image URL
      } else {
        return; // Exit the function if image upload fails
      }
    }

    try {
      // Update the profile data in Supabase
      final response = await Supabase.instance.client
          .from('user_guidance_profiles')
          .update({
            'firstname': firstname,
            'lastname': lastname,
            'college_handled': collegeHandled,
            'profile_image_url': _profileImageUrl, // Update image URL
          })
          .eq('user_id', widget.userId)
          .select(); // Fetch the updated data to verify success

      // Check if the response is not empty, indicating a successful update
      if (response != null && response.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context); // Navigate back to the previous screen
      } else {
        // Failed to update the profile
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update profile. Please try again.')),
        );
      }
    } catch (e) {
      // Handle unexpected errors
      print("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F8F8),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 600,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GUIDANCE PROFILE',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00848B),
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: _profileImage != null
                                      ? MemoryImage(_profileImage!)
                                      : (_profileImageUrl?.isNotEmpty == true
                                              ? NetworkImage(_profileImageUrl!)
                                              : AssetImage(
                                                  'assets/profile.png'))
                                          as ImageProvider<Object>?,
                                  backgroundColor: Colors.grey[200],
                                ),
                                SizedBox(width: 20),
                                ElevatedButton(
                                  onPressed: _pickImage,
                                  child: Text('Change Photo'),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: _firstnameController,
                              decoration: InputDecoration(
                                labelText: 'Firstname',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: _lastnameController,
                              decoration: InputDecoration(
                                labelText: 'Lastname',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller:
                                  TextEditingController(text: widget.email),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true, // Make email non-editable
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: _collegeHandledController,
                              decoration: InputDecoration(
                                labelText: 'College Handled',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 20),
                            Center(
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                child: Text(
                                  'Save',
                                  style: TextStyle(fontSize: 16),
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
            ),
    );
  }
}
