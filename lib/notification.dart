import 'package:flutter/material.dart';
import 'package:guidance/chat/chat/pages/guidancelist.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'studentlist.dart';
import 'guidanceprofile/guidanceprofile.dart';
import 'messages.dart';
import 'consultation.dart';
import 'summaryreports.dart';
import 'home.dart';
import 'login.dart';
import 'upload.dart';
import 'studentprofile.dart';

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
  List<dynamic> students = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchConsultationRequests();
    fetchHighStressNotifications();
    fetchProfileData();
    _fetchUserEmail();
    fetchStudentData(); // Fetch the data when the page loads
  }

  Future<void> fetchConsultationRequests() async {
    try {
      // Fetch the `guidance_id` for the logged-in user
      final guidanceResponse = await supabase
          .from('user_guidance_profiles')
          .select('guidance_id')
          .eq('user_id', widget.userId)
          .single();

      if (guidanceResponse == null) {
        print("Error fetching guidance_id");
        return;
      }

      final String guidanceId = guidanceResponse['guidance_id'];

      // Fetch consultation requests for the fetched `guidance_id`
      final response = await supabase
          .from('consultation_request')
          .select(
              'id, description, student:student_id (firstname, lastname), status')
          .eq('guidance_id', guidanceId)
          .eq('status', 'Pending')
          .order('created_at', ascending: false);

      if (response != null) {
        setState(() {
          consultationRequests =
              List<Map<String, dynamic>>.from(response as List);
        });
      }
    } catch (error) {
      print("Exception fetching consultation requests: $error");
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

  Future<void> fetchProfileData() async {
    try {
      final response = await supabase
          .from('user_guidance_profiles')
          .select('firstname, lastname, profile_image_url, college_handled')
          .eq('user_id', widget.userId)
          .single();

      if (response != null) {
        setState(() {
          profileData = response;
        });
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
          .or('stress_scale.eq.80,stress_scale.eq.90,stress_scale.eq.100') // Replaces `.inArray`
          .order('timestamp', ascending: false);

      if (response != null) {
        setState(() {
          highStressNotifications =
              List<Map<String, dynamic>>.from(response as List);
        });
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

  void navigateToStudentProfile(Map<String, dynamic> notification) {
    print("Notification Data: $notification");

    final student = notification['student'];
    final studentName =
        '${student['firstname'] ?? 'Unknown'} ${student['lastname'] ?? ''}';
    final stressScale = notification['stress_scale'];
    final studentId = notification['student_id'];
    final studentEmail = notification.containsKey('student_email')
        ? notification['student_email']['email']
        : 'Unknown';
    final college =
        student.containsKey('college') ? student['college'] : 'Unknown';
    final yearLevel = student.containsKey('year_level')
        ? student['year_level'].toString()
        : 'Unknown';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Studentprofile(
          userId: widget.userId,
          email: userEmail ?? '', // Guidance counselor's email
          studentEmail: studentEmail, // Student's email
          studentId: studentId, // Student's ID
          firstname: student['firstname'] ?? 'Unknown', // Student's first name
          lastname: student['lastname'] ?? 'Unknown', // Student's last name
          college: college, // Student's college
          yearLevel: yearLevel, // Student's year level
        ),
      ),
    );
  }

  Widget _buildConsultationRequestCard(Map<String, dynamic> request) {
    final student = request['student'];
    final studentName =
        '${student['firstname'] ?? 'Unknown'} ${student['lastname'] ?? ''}';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5), // Adjusted margin
      padding: EdgeInsets.all(8), // Adjusted padding
      decoration: BoxDecoration(
        color: Color(0xFF00B2B0),
        borderRadius: BorderRadius.circular(12), // Adjusted for smaller corners
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage('assets/profile.png'),
            radius: 25, // Smaller radius
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consultation Request from $studentName',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Smaller font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6), // Adjusted spacing
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Consultation(userId: widget.userId),
                          ),
                        );
                      },
                      child: Text('Accept'),
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
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFF00B2B0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage('assets/profile.png'),
            radius: 25,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$studentName's Stress Level Reached $stressScale",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => navigateToStudentProfile(notification),
                      child: Text('View Profile'),
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
                    builder: (context) => GuidanceCounselorListPage(),
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Image.asset('assets/menu.png', width: 80, height: 21),
                  onPressed: () => _scaffoldKey.currentState!.openDrawer(),
                ),
                SizedBox(width: 10),
                Image.asset(
                  'assets/coco1.png',
                  width: 140,
                  height: 50,
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: 0, left: 120),
                    child: Text(
                      "NOTIFICATION",
                      style: TextStyle(
                        fontSize: 24,
                        color: Color(0xFF00B2B0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20, // Adjust the height as needed
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: 800,
                  padding: EdgeInsets.all(25.0),
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
