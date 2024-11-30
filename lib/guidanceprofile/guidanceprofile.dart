import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guidance/studentlist.dart';
import 'package:guidance/messages.dart';
import 'package:guidance/notification.dart';
import 'package:guidance/consultation.dart';
import 'package:guidance/summaryreports.dart';
import 'editprofile.dart'; // Import the EditProfile screen
import 'package:guidance/home.dart';
import 'package:guidance/login.dart';
import 'package:guidance/upload.dart';

class GuidanceProfile extends StatefulWidget {
  final String userId; // User ID from authentication

  GuidanceProfile({required this.userId});

  @override
  _GuidanceProfileState createState() => _GuidanceProfileState();
}

class _GuidanceProfileState extends State<GuidanceProfile> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? profileData;
  bool isLoading = true; // Track loading state
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        isLoading = true;
      });
      await Future.wait([
        fetchProfileData(),
        fetchUserEmail(),
      ]);
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchProfileData() async {
    final response = await supabase
        .from('user_guidance_profiles')
        .select('firstname, lastname, profile_image_url, college_handled')
        .eq('user_id', widget.userId)
        .single()
        .execute();

    if (response.status == 200 && response.data != null) {
      setState(() {
        profileData = response.data;
      });
    } else {
      print("Error fetching profile data. Status: ${response.status}");
    }
  }

  Future<void> fetchUserEmail() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
      });
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF00848B)),
      title: Text(
        title,
        style: TextStyle(color: Color(0xFF00848B)),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F8F8),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF00848B),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profileData?['profile_image_url'] != null
                        ? NetworkImage(profileData!['profile_image_url'])
                        : AssetImage('assets/profile.png') as ImageProvider,
                  ),
                  SizedBox(height: 3),
                  Text(
                    '${profileData?['firstname'] ?? 'Admin'} ${profileData?['lastname'] ?? ''}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5),
                  Text(
                    userEmail ?? 'Email Not Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Home(userId: widget.userId)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.list,
              title: 'Student List',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Studentlist(userId: widget.userId)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          GuidanceProfile(userId: widget.userId)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.message,
              title: 'Messages',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Messages(userId: widget.userId)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.notifications,
              title: 'Notification',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          NotificationPage(userId: widget.userId)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.local_hospital,
              title: 'Consultation',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          Consultation(userId: widget.userId)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.summarize,
              title: 'Summary Reports',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          Summaryreports(userId: widget.userId)),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.upload,
              title: 'Upload',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Upload(userId: widget.userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await supabase.auth.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00848B),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Builder(
                        builder: (BuildContext context) {
                          return Row(
                            children: [
                              IconButton(
                                icon: Image.asset(
                                  'assets/menu.png',
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.contain,
                                ),
                                onPressed: () {
                                  Scaffold.of(context).openDrawer();
                                },
                              ),
                              SizedBox(width: 10),
                              Image.asset(
                                'assets/coco1.png',
                                width: 150,
                                height: 50,
                                fit: BoxFit.contain,
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: 800,
                        padding: const EdgeInsets.all(
                            40), // Adjust padding to suit your design
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 3,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guidance Profile',
                              style: TextStyle(
                                fontSize: 22,
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
                                  backgroundImage:
                                      profileData?['profile_image_url'] != null
                                          ? NetworkImage(
                                              profileData!['profile_image_url'])
                                          : AssetImage('assets/profile.png')
                                              as ImageProvider,
                                  backgroundColor: Colors.grey[200],
                                ),
                                SizedBox(width: 30),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fullname: ${profileData?['firstname'] ?? ''} ${profileData?['lastname'] ?? ''}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Email: ${userEmail ?? 'Email Not Available'}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'College Handle: ${profileData?['college_handled'] ?? 'Not assigned'}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 30),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProfile(
                                          firstname:
                                              profileData?['firstname'] ?? '',
                                          lastname:
                                              profileData?['lastname'] ?? '',
                                          email: userEmail ?? '',
                                          userId:
                                              widget.userId, // Pass userId here
                                        ),
                                      ),
                                    ).then((_) {
                                      // Refresh the profile data after returning from the EditProfile screen
                                      _initializeData();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF00848B),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
