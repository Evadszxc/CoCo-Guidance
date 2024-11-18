import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';
import 'studentlist.dart';
import 'guidanceprofile/guidanceprofile.dart';
import 'messages.dart';
import 'notification.dart';
import 'consultation.dart';

class Summaryreports extends StatefulWidget {
  final String email;

  Summaryreports({required this.email});

  @override
  _SummaryreportsState createState() => _SummaryreportsState();
}

class _SummaryreportsState extends State<Summaryreports> {
  String selectedType = '90-100'; // Default dropdown value for stress scale
  String selectedYear = '2024'; // Default dropdown value for year
  Map<String, dynamic>? profileData;
  List<Map<String, dynamic>> collegesData = [];

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
  }

  Future<void> fetchProfileData() async {
    final response = await Supabase.instance.client
        .from('guidancecounselor')
        .select()
        .eq('email', widget.email)
        .single();

    if (response.status == 200 && response.data != null) {
      setState(() {
        profileData = response.data;
      });
    } else {
      print(
          "Error fetching profile data: ${response.error?.message ?? "Unknown error"}");
    }
  }

  Future<void> fetchCollegeStressData() async {
    // Query data based on selected stress range and year
    final int minStress = int.parse(selectedType.split('-')[0]);
    final int maxStress = int.parse(selectedType.split('-')[1]);

    final response = await Supabase.instance.client
        .from('stress')
        .select(
            'studentid, stress_scale, timestamp, student:studentid (college)')
        .gte('stress_scale', minStress)
        .lte('stress_scale', maxStress);

    if (response.status == 200 && response.data != null) {
      final data = response.data as List<dynamic>;
      final Map<String, Map<String, int>> tempData = {};

      for (var entry in data) {
        final college = entry['student']['college'];
        final timestamp = DateTime.parse(entry['timestamp']);
        final month = timestamp.month;

        if (!tempData.containsKey(college)) {
          tempData[college] = {
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
        }

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

      setState(() {
        collegesData = tempData.entries.map((entry) {
          return {
            'College': entry.key,
            ...entry.value,
          };
        }).toList();
      });
    } else {
      print(
          "Error fetching stress data: ${response.error?.message ?? "Unknown error"}");
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
          fetchCollegeStressData(); // Re-fetch data when dropdown changes
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Studentlist(email: widget.email),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () => Navigator.pushReplacement(
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
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPage(email: widget.email),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.local_hospital,
              title: 'Consultation',
              onTap: () => Navigator.pushReplacement(
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
                Navigator.pop(context);
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
                            width: 1300,
                            padding: const EdgeInsets.all(40.0),
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
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('College'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('January'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('February'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('March'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('April'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('May'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('June'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('July'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('August'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('September'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('October'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('November'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(1.0),
                                            child: Text('December'),
                                          ),
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
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  college['Jan'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  college['Feb'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  college['Mar'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  college['Apr'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  college['May'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  college['Jun'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  college['Jul'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  college['Aug'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  college['Sep'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  college['Oct'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  college['Nov'].toString()),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  college['Dec'].toString()),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ],
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
    home: Summaryreports(email: 'Guidance@uic.edu.ph'),
    debugShowCheckedModeBanner: false,
  ));
}
