import 'package:flutter/material.dart';
import 'package:guidance/chat/chat/pages/guidancelist.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';
import 'studentlist.dart';
import 'guidanceprofile/guidanceprofile.dart';
import 'messages.dart';
import 'notification.dart';
import 'consultation.dart';
import 'upload.dart';
import 'login.dart';

class Summaryreports extends StatefulWidget {
  final String userId;

  Summaryreports({required this.userId});

  @override
  _SummaryreportsState createState() => _SummaryreportsState();
}

class _SummaryreportsState extends State<Summaryreports> {
  String selectedType = '90-100'; // Default dropdown value for stress scale
  String selectedYear = '2024'; // Default dropdown value for year
  Map<String, dynamic>? profileData;
  List<Map<String, dynamic>> collegesData = [];
  String? userEmail;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final SupabaseClient supabase = Supabase.instance.client;
  final List<String> stressTypes = [
    '90-100',
    '70-80',
    '50-60',
    '30-40',
    '10-20'
  ];
  final List<String> years = List<String>.generate(
      2100 - 2024 + 1, (index) => (2024 + index).toString());

  @override
  void initState() {
    super.initState();
    fetchProfileData();
    fetchCollegeStressData();
    fetchUserEmail();
  }

  Future<void> fetchUserEmail() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        setState(() {
          userEmail = user.email; // Update the email
        });
      }
    } catch (e) {
      print("Error fetching user email: $e");
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
      } else {
        print("Error fetching profile data: No data found.");
      }
    } catch (error) {
      print("Error fetching profile data: $error");
    }
  }

  Future<void> fetchCollegeStressData() async {
    try {
      // Parse the stress range
      final int minStress = int.parse(selectedType.split('-')[0]);
      final int maxStress = int.parse(selectedType.split('-')[1]);

      // Query the stress table
      final response = await Supabase.instance.client
          .from('stress')
          .select(
              'student_id, stress_scale, timestamp, student:student_id (college)')
          .gte('stress_scale', minStress)
          .lte('stress_scale', maxStress)
          .gte(
              'timestamp',
              DateTime(int.parse(selectedYear), 1, 1)
                  .toIso8601String()) // Start of the year
          .lte(
              'timestamp',
              DateTime(int.parse(selectedYear), 12, 31)
                  .toIso8601String()); // End of the year

      if (response != null) {
        final List<dynamic> data = response;

        // Process data for monthly and college breakdown
        final Map<String, Map<String, int>> tempData = {};

        for (var entry in data) {
          final college = entry['student']['college'];
          final timestamp = DateTime.parse(entry['timestamp']);
          final month = timestamp.month;

          // Initialize college data if not present
          tempData.putIfAbsent(college, () {
            return {
              'Jan': 0,
              'Feb': 0,
              'Mar': 0,
              'Apr': 0,
              'May': 0,
              'Jun': 0,
              'Jul': 0,
              'Aug': 0,
              'Sep': 0,
              'Oct': 0,
              'Nov': 0,
              'Dec': 0,
            };
          });

          // Increment the count for the corresponding month
          final monthKey = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ][month - 1];

          tempData[college]![monthKey] = tempData[college]![monthKey]! + 1;
        }

        // Update state with the formatted data
        setState(() {
          collegesData = tempData.entries.map((entry) {
            return {
              'College': entry.key,
              ...entry.value,
            };
          }).toList();
        });
      } else {
        print('Error: No data available for the specified criteria.');
      }
    } catch (e) {
      print('Exception while fetching stress data: $e');
    }
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return DropdownButton<String>(
      value: value,
      onChanged: (String? newValue) {
        setState(() {
          onChanged(newValue!);
          fetchCollegeStressData();
        });
      },
      items: items.map<DropdownMenuItem<String>>((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
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

  Widget _buildDrawer() {
    return Drawer(
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
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => Home(userId: widget.userId)),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.list,
            title: 'Student List',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Studentlist(userId: widget.userId)),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuidanceProfile(userId: widget.userId)),
            ),
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NotificationPage(userId: widget.userId)),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.local_hospital,
            title: 'Consultation',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NotificationPage(userId: widget.userId)),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.summarize,
            title: 'Summary Reports',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Summaryreports(userId: widget.userId)),
            ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF3F8F8),
      drawer: _buildDrawer(),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Image.asset('assets/menu.png', width: 80, height: 21),
                  onPressed: () => _scaffoldKey.currentState!.openDrawer(),
                ),
                SizedBox(width: 10),
                Image.asset('assets/coco1.png', width: 140, height: 50),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: 1000,
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
                            'SUMMARY REPORTS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00B2B0),
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Color(0xFFF4F6F6),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildDropdown(
                                      value: selectedType,
                                      items: stressTypes,
                                      onChanged: (val) => selectedType = val,
                                    ),
                                    SizedBox(width: 20),
                                    _buildDropdown(
                                      value: selectedYear,
                                      items: years,
                                      onChanged: (val) => selectedYear = val,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Container(
                                  color: Colors.white,
                                  child: Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(3),
                                      1: FlexColumnWidth(1),
                                      2: FlexColumnWidth(1),
                                      3: FlexColumnWidth(1),
                                      4: FlexColumnWidth(1),
                                      5: FlexColumnWidth(1),
                                      6: FlexColumnWidth(1),
                                      7: FlexColumnWidth(1),
                                      8: FlexColumnWidth(1),
                                      9: FlexColumnWidth(1),
                                      10: FlexColumnWidth(1),
                                      11: FlexColumnWidth(1),
                                      12: FlexColumnWidth(1),
                                    },
                                    border:
                                        TableBorder.all(color: Colors.black26),
                                    children: [
                                      TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'College',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          ...[
                                            'Jan',
                                            'Feb',
                                            'Mar',
                                            'Apr',
                                            'May',
                                            'Jun',
                                            'Jul',
                                            'Aug',
                                            'Sep',
                                            'Oct',
                                            'Nov',
                                            'Dec'
                                          ].map((month) => Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  month,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              )),
                                        ],
                                      ),
                                      ...collegesData.map((college) {
                                        return TableRow(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(college['College']),
                                            ),
                                            ...[
                                              'Jan',
                                              'Feb',
                                              'Mar',
                                              'Apr',
                                              'May',
                                              'Jun',
                                              'Jul',
                                              'Aug',
                                              'Sep',
                                              'Oct',
                                              'Nov',
                                              'Dec'
                                            ].map((month) => Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(college[month]
                                                      .toString()),
                                                )),
                                          ],
                                        );
                                      }).toList(),
                                    ],
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Summaryreports(userId: 'sample_user_id'),
    debugShowCheckedModeBanner: false,
  ));
}
