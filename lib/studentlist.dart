import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guidance/guidanceprofile/guidanceprofile.dart';
import 'home.dart';
import 'messages.dart';
import 'notification.dart';
import 'consultation.dart';
import 'summaryreports.dart';
import 'studentprofile.dart';

class Studentlist extends StatefulWidget {
  final String email;

  Studentlist({required this.email});

  @override
  _StudentlistState createState() => _StudentlistState();
}

class _StudentlistState extends State<Studentlist> {
  List<dynamic> students = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    final response = await Supabase.instance.client
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
          "Error fetching profile data: ${response.status == 404 ? "Not Found" : "Unknown error"}");
    }
  }

  Future<void> fetchStudentData() async {
    try {
      final response =
          await Supabase.instance.client.from('student').select().execute();

      if (response.status == 200 && response.data != null) {
        setState(() {
          students = response.data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              response.status == 404 ? "No data found" : "An error occurred";
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
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
                    radius: 40,
                    backgroundImage: profileData?['profile_image_url'] != null
                        ? NetworkImage(profileData!['profile_image_url'])
                        : AssetImage('assets/profile.png') as ImageProvider,
                    backgroundColor: Colors.grey[200],
                  ),
                  SizedBox(height: 3),
                  Text(
                    profileData?['firstname'] ?? 'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    profileData?['email'] ?? 'Admin@uic.edu.ph',
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
              child: Center(
                child: Container(
                  width: 1200,
                  height: 500,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                        Expanded(
                          child: Container(
                            width: 1300,
                            decoration: BoxDecoration(
                              color: Color(0xFFF4F6F6),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Stack(
                                children: [
                                  if (isLoading)
                                    Center(child: CircularProgressIndicator())
                                  else if (errorMessage != null)
                                    Center(child: Text('Error: $errorMessage'))
                                  else if (students.isEmpty)
                                    Center(child: Text('No students found'))
                                  else
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Spacer(),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  width: 200,
                                                  height: 35,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    border: Border.all(
                                                        color: Colors.grey),
                                                  ),
                                                  child: TextField(
                                                    decoration: InputDecoration(
                                                      hintText: 'Search...',
                                                      prefixIcon:
                                                          Icon(Icons.search),
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 8.0),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Divider(
                                                  color: Colors.grey,
                                                  thickness: 1,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        Table(
                                          columnWidths: const {
                                            0: FlexColumnWidth(1.5),
                                            1: FlexColumnWidth(1.5),
                                            2: FlexColumnWidth(1.5),
                                            3: FlexColumnWidth(1.5),
                                            4: FlexColumnWidth(1),
                                          },
                                          children: [
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(6.0),
                                                  child: Text('Email',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(6.0),
                                                  child: Text('Firstname',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(6.0),
                                                  child: Text('Lastname',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(6.0),
                                                  child: Text('College',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(6.0),
                                                  child: Text('Action',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                            for (var student in students)
                                              TableRow(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                        student['email'] ?? ''),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                        student['firstname'] ??
                                                            ''),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                        student['lastname'] ??
                                                            ''),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                        student['college'] ??
                                                            ''),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    child: TextButton(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                Studentprofile(
                                                              email:
                                                                  widget.email,
                                                              studentEmail: student[
                                                                      'email'] ??
                                                                  'Unknown Email',
                                                              firstname: student[
                                                                      'firstname'] ??
                                                                  'Unknown',
                                                              lastname: student[
                                                                      'lastname'] ??
                                                                  'Unknown',
                                                              college: student[
                                                                      'college'] ??
                                                                  'Unknown College',
                                                              yearLevel: student[
                                                                      'year_level'] ??
                                                                  'Unknown Year',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor:
                                                            Color(0xFF00848B),
                                                        foregroundColor:
                                                            Colors.white,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 18,
                                                                vertical: 10),
                                                      ),
                                                      child:
                                                          Text('View Details'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
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
