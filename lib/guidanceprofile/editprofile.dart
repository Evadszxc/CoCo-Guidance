import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class EditProfile extends StatefulWidget {
  final String firstname;
  final String lastname;
  final String email;

  EditProfile({
    required this.firstname,
    required this.lastname,
    required this.email,
  });

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _emailController;
  late TextEditingController _collegeHandledController;

  Uint8List? _profileImage;
  String? _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _firstnameController = TextEditingController();
    _lastnameController = TextEditingController();
    _emailController = TextEditingController();
    _collegeHandledController = TextEditingController();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    final response = await Supabase.instance.client
        .from('guidancecounselor')
        .select<Map<String, dynamic>>()
        .eq('email', widget.email)
        .single();

    if (response != null) {
      setState(() {
        _firstnameController.text = response['firstname'] ?? '';
        _lastnameController.text = response['lastname'] ?? '';
        _emailController.text = response['email'] ?? '';
        _collegeHandledController.text = response['college_handled'] ?? '';
        _profileImageUrl = response['profile_image_url'] ?? '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching profile data.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String?> _uploadImage(Uint8List imageBytes) async {
    final fileName =
        '${widget.email}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final response = await Supabase.instance.client.storage
          .from('profile_image_url')
          .uploadBinary(fileName, imageBytes,
              fileOptions: const FileOptions(upsert: true));

      if (response != null) {
        // If upload is successful, get the public URL
        return Supabase.instance.client.storage
            .from('profile_image_url')
            .getPublicUrl(fileName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload failed.')),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
      return null;
    }
  }

  Future<void> _saveProfile() async {
    String firstname = _firstnameController.text.trim();
    String lastname = _lastnameController.text.trim();
    String email = _emailController.text.trim();
    String collegeHandled = _collegeHandledController.text.trim();

    if (_profileImage != null) {
      final imageUrl = await _uploadImage(_profileImage!);
      if (imageUrl != null) {
        _profileImageUrl = imageUrl;
      }
    }

    final response =
        await Supabase.instance.client.from('guidancecounselor').update({
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'college_handled': collegeHandled,
      'profile_image_url': _profileImageUrl,
    }).eq('email', widget.email);

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F8F8),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
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
                    'Guidance Profile',
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
                            : (_profileImageUrl != null &&
                                        _profileImageUrl!.isNotEmpty
                                    ? NetworkImage(_profileImageUrl!)
                                    : AssetImage('assets/profile.png'))
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
                  SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
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
        ),
      ),
    );
  }
}
