import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'studentlist.dart';
import 'guidanceprofile/guidanceprofile.dart';
import 'messages.dart';
import 'consultation.dart';
import 'summaryreports.dart';
import 'home.dart';
import 'login.dart';
import 'upload.dart';

class NotificationPage extends StatefulWidget {
  final String userId;

  NotificationPage({required this.userId});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<dynamic> consultationRequests = [];
  Map<String, dynamic>? profileData;
  List<Map<String, dynamic>> highStressNotifications = [];
  String? userEmail;

  @override
  void initState() {
    super.initState();
    fetchConsultationRequests();
    fetchHighStressNotifications();
    fetchProfileData();
    _fetchUserEmail();
  }

  Future<void> fetchConsultationRequests() async {
    try {
      // Ensure you filter by the guidance counselor's userId
      final response = await supabase
          .from('session')
          .select(
              'id, schedule, sessiontype, student:student_id (firstname, lastname)')
          .eq(
              'guidance_id',
              widget
                  .userId) // Fetch only sessions related to this guidance counselor
          .is_('schedule', null) // Optional: Only fetch unscheduled requests
          .order('id', ascending: false) // Sort by latest requests
          .execute();

      if (response.status == 200 && response.data != null) {
        setState(() {
          consultationRequests = List<Map<String, dynamic>>.from(response.data);
        });
      } else {
        print("Error fetching consultation requests: ${response.status}");
      }
    } catch (error) {
      print("Exception fetching consultation requests: $error");
    }
  }

  Future<void> fetchProfileData() async {
    try {
      final response = await supabase
          .from('user_guidance_profiles')
          .select('firstname, lastname, profile_image_url, college_handled')
          .eq('user_id', widget.userId)
          .single()
          .execute();

      if (response.status == 200) {
        setState(() {
          profileData = response.data;
        });
      } else {
        print("Error fetching profile data: ${response.status}");
      }
    } catch (error) {
      print("Exception fetching profile data: $error");
    }
  }

  Future<void> fetchHighStressNotifications() async {
    try {
      final response = await supabase
          .from('stress')
          .select(
              'stress_scale, timestamp, student_id, student:student_id (firstname, lastname)')
          .in_('stress_scale', [80, 90, 100])
          .order('timestamp', ascending: false) // Sort by latest stress levels
          .execute();

      if (response.status == 200 && response.data != null) {
        setState(() {
          highStressNotifications =
              List<Map<String, dynamic>>.from(response.data);
        });
      } else {
        print("Error fetching stress notifications: ${response.status}");
      }
    } catch (error) {
      print("Exception fetching stress notifications: $error");
    }
  }

  Future<void> _fetchUserEmail() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          userEmail = user.email;
        });
      }
    } catch (e) {
      print("Error fetching user email: $e");
    }
  }

  Widget _buildConsultationRequestCard(Map<String, dynamic> request) {
    final student = request['student'];
    final studentName =
        '${student['firstname'] ?? 'Unknown'} ${student['lastname'] ?? ''}';

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF00B2B0),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(4, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage('assets/profile.png'),
            radius: 30,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consultation Request from $studentName',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        print('Accept pressed for $studentName');
                      },
                      child: Text('Accept'),
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFFCBE2BB),
                        foregroundColor: Colors.black,
                      ),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        print('Reject pressed for $studentName');
                      },
                      child: Text('Reject'),
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFFCBE2BB),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighStressNotificationCard(Map<String, dynamic> notification) {
    final student = notification['student'];
    final studentName =
        '${student['firstname'] ?? 'Unknown'} ${student['lastname'] ?? ''}';
    final stressScale = notification['stress_scale'];

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF00B2B0),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(4, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage('assets/profile.png'),
            radius: 30,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$studentName\'s Stress Level Reached $stressScale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        print('View Profile for $studentName');
                      },
                      child: Text('View Profile'),
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFFCBE2BB),
                        foregroundColor: Colors.black,
                      ),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        print('Message pressed for $studentName');
                      },
                      child: Text('Message'),
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFFCBE2BB),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF3F8F8),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF00848B)),
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
                    userEmail ?? 'Email Not Available',
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
                    builder: (context) => Messages(userId: widget.userId),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.notifications,
              title: 'Notification',
              onTap: () {
                Navigator.pop(context);
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
            Row(
              children: [
                IconButton(
                  icon: Image.asset('assets/menu.png', width: 30, height: 30),
                  onPressed: () => _scaffoldKey.currentState!.openDrawer(),
                ),
                SizedBox(width: 1),
                Image.asset('assets/coco1.png', width: 200, height: 70),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: 800,
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: consultationRequests.isEmpty &&
                          highStressNotifications.isEmpty
                      ? Center(child: Text('No notifications available'))
                      : Column(
                          children: [
                            ...consultationRequests.map(
                              (request) =>
                                  _buildConsultationRequestCard(request),
                            ),
                            ...highStressNotifications.map(
                              (notification) =>
                                  _buildHighStressNotificationCard(
                                      notification),
                            ),
                          ],
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
    home: NotificationPage(userId: 'user-id-placeholder'),
    debugShowCheckedModeBanner: false,
  ));
}
