import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'studentlist.dart';
import 'package:guidance/guidanceprofile/guidanceprofile.dart';
import 'messages.dart';
import 'consultation.dart';
import 'summaryreports.dart';
import 'home.dart';

class NotificationPage extends StatefulWidget {
  final String email; // Accept the logged-in user's email

  NotificationPage({required this.email}); // Constructor to accept email

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> consultationRequests =
      []; // List to store consultation requests
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    fetchConsultationRequests();
    fetchProfileData();
  }

  // Function to fetch consultation requests
  Future<void> fetchConsultationRequests() async {
    final response = await supabase.from('session').select().execute();

    if (response.status == 200 && response.data != null) {
      setState(() {
        consultationRequests = response.data;
      });
    } else {
      print(
          "Error fetching consultation requests: ${response.status}, ${response.data}");
    }
  }

  // Function to fetch profile data for the drawer avatar
  Future<void> fetchProfileData() async {
    final response = await supabase
        .from('guidancecounselor')
        .select()
        .eq('email', widget.email)
        .single()
        .execute();

    if (response.status == 200 && response.data != null) {
      setState(() {
        profileData = response.data;
      });
    } else {
      print(
          "Error fetching profile data: ${response.status}, ${response.data}");
    }
  }

  // Widget to build each consultation request card with avatar
  Widget _buildConsultationRequestCard(Map<String, dynamic> request) {
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
            backgroundImage: AssetImage(
                'assets/profile.png'), // Avatar for each notification
            radius: 30,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consultation Request from ${request['firstname']}',
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
                        // Accept consultation request logic
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
                        // Reject consultation request logic
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Color(0xFF00848B),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Color(0xFF00848B),
        ),
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
                    backgroundImage: profileData?['profile_image_url'] != null
                        ? NetworkImage(profileData!['profile_image_url'])
                        : AssetImage('assets/profile.png') as ImageProvider,
                    radius: 40,
                  ),
                  SizedBox(height: 3),
                  Text(
                    profileData?['firstname'] ?? 'Nariah Sy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    profileData?['email'] ?? 'Guidance@uic.edu.ph',
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Home(email: widget.email),
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
                    builder: (context) => Studentlist(email: widget.email),
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
                    builder: (context) => GuidanceProfile(email: widget.email),
                  ),
                );
              },
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationPage(email: widget.email),
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
                    builder: (context) => Consultation(email: widget.email),
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
                    builder: (context) => Summaryreports(email: widget.email),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                // Add sign-out logic here
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
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    SizedBox(width: 1),
                    Image.asset(
                      'assets/coco1.png',
                      width: 200,
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                  ],
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: 800,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NOTIFICATION',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00B2B0),
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            width: 1300,
                            decoration: BoxDecoration(
                              color: Color(0xFFF4F6F6),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: consultationRequests
                                  .map((request) =>
                                      _buildConsultationRequestCard(request))
                                  .toList(),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
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
    home: NotificationPage(email: 'Guidance@uic.edu.ph'), // Pass the email
  ));
}
