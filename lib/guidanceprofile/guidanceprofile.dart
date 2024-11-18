import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guidance/studentlist.dart';
import 'package:guidance/messages.dart';
import 'package:guidance/notification.dart';
import 'package:guidance/consultation.dart';
import 'package:guidance/summaryreports.dart';
import 'editprofile.dart'; // Import the EditProfile screen
import 'package:guidance/home.dart';

class GuidanceProfile extends StatefulWidget {
  final String email; // Email passed from login

  GuidanceProfile({required this.email}); // Constructor to accept email

  @override
  _GuidanceProfileState createState() => _GuidanceProfileState();
}

class _GuidanceProfileState extends State<GuidanceProfile> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? guidanceData;

  @override
  void initState() {
    super.initState();
    if (guidanceData == null) {
      fetchGuidanceProfile(); // Fetch only if guidanceData is not set
    }
  }

  Future<void> fetchGuidanceProfile() async {
    try {
      final response = await Supabase.instance.client
          .from('guidancecounselor')
          .select<Map<String, dynamic>>()
          .eq('email', widget.email)
          .single();

      if (response != null) {
        // If the response contains data
        setState(() {
          guidanceData = response; // Assign the fetched data
        });
      } else {
        // Handle the case where response is null
        throw Exception('No data found for the given email.');
      }
    } catch (error) {
      // Handle any errors gracefully
      print('Error fetching guidance profile: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch profile: $error')),
      );
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
      backgroundColor: Color(0xFFF3F8F8), // Light background color
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF00848B), // Teal color for the header
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: guidanceData?['profile_image_url'] != null
                        ? NetworkImage(guidanceData!['profile_image_url'])
                        : AssetImage('assets/profile.png') as ImageProvider,
                    backgroundColor: Colors.grey[200],
                  ),
                  SizedBox(height: 3),
                  Text(
                    guidanceData?['firstname'] ?? 'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    guidanceData?['email'] ?? 'Admin@uic.edu.ph',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Home(email: widget.email),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.list,
              title: 'Student List',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Studentlist(email: widget.email),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuidanceProfile(email: widget.email),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.message,
              title: 'Messages',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => Messages(email: widget.email)),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.notifications,
              title: 'Notification',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPage(email: widget.email),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.local_hospital,
              title: 'Consultation',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Consultation(email: widget.email),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.summarize,
              title: 'Summary Reports',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Summaryreports(email: widget.email),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                // Add sign-out logic here
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                Center(
                  child: Container(
                    width: 800,
                    padding: const EdgeInsets.all(80),
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
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(8.0),
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
                                    guidanceData?['profile_image_url'] != null
                                        ? NetworkImage(
                                            guidanceData!['profile_image_url'])
                                        : AssetImage('assets/profile.png')
                                            as ImageProvider,
                                backgroundColor: Colors.grey[200],
                              ),
                              SizedBox(width: 30),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Firstname: ${guidanceData?['firstname'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Lastname: ${guidanceData?['lastname'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Email: ${guidanceData?['email'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Course Handle: ${guidanceData?['college_handled'] ?? 'Not assigned'}',
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
                                            guidanceData?['firstname'] ?? '',
                                        lastname:
                                            guidanceData?['lastname'] ?? '',
                                        email: guidanceData?['email'] ?? '',
                                      ),
                                    ),
                                  );
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
