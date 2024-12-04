import 'package:flutter/material.dart';
import 'package:guidance/chat/chat/pages/guidancelist.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'guidanceprofile/guidanceprofile.dart';
import 'messages.dart';
import 'notification.dart';
import 'consultation.dart';
import 'summaryreports.dart';
import 'home.dart';
import 'studentprofile.dart';
import 'login.dart';
import 'upload.dart';

class Studentlist extends StatefulWidget {
  final String userId;

  Studentlist({required this.userId});

  @override
  _StudentlistState createState() => _StudentlistState();
}

class _StudentlistState extends State<Studentlist> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<dynamic> students = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? profileData;
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
      await Future.wait([fetchStudentData(), fetchProfileData()]);
    } catch (e) {
      print("Error initializing data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchProfileData() async {
    try {
      final response = await supabase
          .from('user_guidance_profiles')
          .select('firstname, lastname, profile_image_url')
          .eq('user_id', widget.userId)
          .single();

      if (response != null) {
        setState(() {
          profileData = response;
          userEmail = supabase.auth.currentUser?.email;
        });
      } else {
        print("Error fetching profile data: No data found.");
      }
    } catch (error) {
      print("Error fetching profile data: $error");
    }
  }

  Future<void> fetchStudentData() async {
    try {
      final response = await supabase.rpc('get_student_list_with_email');

      if (response.isNotEmpty) {
        setState(() {
          students = response as List<dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error: No data returned from RPC';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
        isLoading = false;
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
      title: Text(title, style: TextStyle(color: Color(0xFF00848B))),
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
                  SizedBox(height: 5),
                  Text(
                    '${profileData?['firstname'] ?? 'Admin'} ${profileData?['lastname'] ?? ''}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userEmail ?? 'Email Not Available', // Display email
                    style: TextStyle(color: Colors.white, fontSize: 14),
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
                    builder: (context) =>
                        Home(userId: supabase.auth.currentUser?.id ?? ''),
                  ),
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
                    builder: (context) => Studentlist(userId: widget.userId),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GuidanceProfile(userId: widget.userId),
                  ),
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
                    builder: (context) => GuidanceCounselorListPage(),
                  ),
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
                        NotificationPage(userId: widget.userId),
                  ),
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
                    builder: (context) => Consultation(userId: widget.userId),
                  ),
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
                    builder: (context) => Summaryreports(userId: widget.userId),
                  ),
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
      body: Padding(
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
                        width: 80,
                        height: 21,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    SizedBox(width: 10),
                    Image.asset(
                      'assets/coco1.png',
                      width: 140,
                      height: 50,
                    ),
                  ],
                );
              },
            ),
            SizedBox(
              height: 40, // Adjust the height to your desired spacing
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: 1100,
                  decoration: BoxDecoration(
                    color: Colors.white, // Outer white container
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STUDENT LIST',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00B2B0),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Color(
                                0xFFF6F6F6), // Light grey background for the table
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: EdgeInsets.all(
                              16.0), // Padding inside grey container
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1.5),
                              1: FlexColumnWidth(1.5),
                              2: FlexColumnWidth(1.5),
                              3: FlexColumnWidth(1.5),
                              4: FlexColumnWidth(1),
                            },
                            border: TableBorder.all(
                              color: Colors.grey[300]!, // Table border color
                              width: 1,
                            ),
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors
                                      .grey[200], // Light grey for the header
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      'Email',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      'Firstname',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      'Lastname',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      'College',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      'Action',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              // Dynamic Rows for Students
                              for (var student in students)
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(student['email'] ?? 'N/A'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child:
                                          Text(student['firstname'] ?? 'N/A'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(student['lastname'] ?? 'N/A'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(student['college'] ?? 'N/A'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: TextButton(
                                        onPressed: () {
                                          // Navigate to the Studentprofile screen
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  Studentprofile(
                                                userId: widget
                                                    .userId, // Pass the userId here
                                                email: widget.userId,
                                                studentEmail:
                                                    student['email'] ?? '',
                                                studentId:
                                                    student['student_id'],
                                                firstname:
                                                    student['firstname'] ?? '',
                                                lastname:
                                                    student['lastname'] ?? '',
                                                college:
                                                    student['college'] ?? '',
                                              ),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Color(0xFF00848B),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                        child: Text('View Details'),
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
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Studentlist(userId: 'sample-user-id'),
    debugShowCheckedModeBanner: false,
  ));
}
