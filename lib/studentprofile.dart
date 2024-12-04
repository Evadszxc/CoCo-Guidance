import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:guidance/chat/chat/pages/guidancelist.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'guidanceprofile/guidanceprofile.dart';
import 'messages.dart';
import 'notification.dart';
import 'consultation.dart';
import 'summaryreports.dart';
import 'home.dart';
import 'studentlist.dart';
import 'upload.dart';

class Studentprofile extends StatefulWidget {
  final String userId; // Add this field
  final String email; // Guidance user's email
  final String studentEmail; // Student's email
  final String firstname;
  final String lastname;
  final String college;
  final String? yearLevel;
  final String studentId; // Use student_id instead of email

  Studentprofile({
    required this.userId, // Add this parameter
    required this.email,
    required this.studentEmail,
    required this.studentId,
    required this.firstname,
    required this.lastname,
    required this.college,
    this.yearLevel,
  });

  @override
  _StudentprofileState createState() => _StudentprofileState();
}

class _StudentprofileState extends State<Studentprofile> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabaseClient supabase = Supabase.instance.client;

  DateTime _selectedDate = DateTime.now();

  List<FlSpot> emotionDataPoints = [];
  List<FlSpot> sudsDataPoints = [];
  bool isEmotionGraph = true;
  String? latestStressScale;

  Map<String, dynamic>? profileData; // For guidance profile in the drawer
  Map<String, dynamic>? studentProfileData; // For the student's profile data
  String? userEmail;

  final Map<String, double> emotionToValue = {
    'mad': 0,
    'worried': 1,
    'sad': 2,
    'meh': 3,
    'happy': 4,
    'very happy': 5,
  };

  final Map<double, String> emotionLabels = {
    0: "😡", // mad
    1: "😨", // worried
    2: "😢", // sad
    3: "😐", // meh
    4: "🙂", // happy
    5: "😀", // very happy
  };

  @override
  void initState() {
    super.initState();
    fetchProfileData(); // Fetch guidance profile for drawer
    fetchStudentProfileData(); // Fetch specific student's profile
    fetchEmotionData();
    fetchSudsData();
    fetchLatestStressScale();
  }

  Future<void> fetchProfileData() async {
    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        print("Error: User ID is null.");
        return;
      }

      final response = await supabase
          .from('user_guidance_profiles')
          .select('firstname, lastname, profile_image_url')
          .eq('user_id', userId)
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

  Future<void> fetchStudentProfileData() async {
    try {
      // Fetch student profile data using student_id
      final profileResponse = await supabase
          .from('user_student_profile')
          .select('firstname, lastname, year_level')
          .eq('student_id', widget.studentId)
          .single();

      if (profileResponse != null) {
        setState(() {
          studentProfileData = profileResponse;
        });
      } else {
        print("Error fetching student profile data: No data found.");
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> fetchLatestStressScale() async {
    try {
      final response = await supabase
          .from('stress')
          .select('stress_scale')
          .eq('student_id', widget.studentId);

      if (response != null && response.isNotEmpty) {
        double totalStress = response.fold<double>(
            0.0, (sum, item) => sum + (item['stress_scale'] ?? 0.0));

        double stressAverage = totalStress / response.length;

        setState(() {
          latestStressScale = stressAverage.toStringAsFixed(2);
        });
      } else {
        setState(() {
          latestStressScale = "No Data";
        });
      }
    } catch (error) {
      setState(() {
        latestStressScale = "Error Fetching";
      });
      print("Error fetching stress scale: $error");
    }
  }

  Future<void> fetchEmotionData() async {
    try {
      final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

      final response = await supabase
          .from('emotionresponse')
          .select('created_at, emotions')
          .eq('student_id', widget.studentId)
          .gte('created_at', startDate.toIso8601String())
          .lt('created_at', endDate.toIso8601String());

      if (response != null) {
        final groupedByDay = <int, Map<String, int>>{};

        for (var record in response) {
          final createdAt = DateTime.parse(record['created_at']);
          final day = createdAt.day;
          final emotion = record['emotions'] as String;

          groupedByDay.putIfAbsent(day, () => {});
          groupedByDay[day]![emotion] = (groupedByDay[day]?[emotion] ?? 0) + 1;
        }

        setState(() {
          emotionDataPoints = groupedByDay.entries.map((entry) {
            final day = entry.key.toDouble();
            final dominantEmotion = entry.value.entries.reduce(
                (a, b) => a.value >= b.value ? a : b); // Find dominant emotion
            return FlSpot(day, emotionToValue[dominantEmotion.key]!);
          }).toList();
        });
      } else {
        print("Error fetching emotion data: No data found.");
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> fetchSudsData() async {
    try {
      final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

      final response = await supabase
          .from('stress')
          .select('timestamp, stress_scale')
          .eq('student_id', widget.studentId)
          .gte('timestamp', startDate.toIso8601String())
          .lt('timestamp', endDate.toIso8601String());

      if (response != null) {
        final groupedByDay = <int, Map<int, int>>{};

        for (final item in response) {
          final date = DateTime.parse(item['timestamp']);
          final day = date.day;
          final stressScale = item['stress_scale'];

          groupedByDay.putIfAbsent(day, () => {});
          groupedByDay[day]![stressScale] =
              (groupedByDay[day]![stressScale] ?? 0) + 1;
        }

        setState(() {
          sudsDataPoints = groupedByDay.entries.map((entry) {
            final day = entry.key.toDouble();
            final dominantStressScale = entry.value.entries.reduce((a, b) =>
                a.value > b.value ? a : b); // Get dominant stress scale
            return FlSpot(day, dominantStressScale.key.toDouble());
          }).toList();
        });
      } else {
        print("Error fetching SUDS data: No data found.");
      }
    } catch (error) {
      print("Error: $error");
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

  Widget buildBarGraph({
    required List<FlSpot> dataPoints,
    required bool isEmotionGraph,
    required double maxY,
  }) {
    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: dataPoints.map((spot) {
          return BarChartGroupData(
            x: spot.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: spot.y,
                width: 8,
                color: isEmotionGraph ? Colors.blue : Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                if (isEmotionGraph) {
                  switch (value.toInt()) {
                    case 0:
                      return Text("😡");
                    case 1:
                      return Text("😨");
                    case 2:
                      return Text("😢");
                    case 3:
                      return Text("😐");
                    case 4:
                      return Text("🙂");
                    case 5:
                      return Text("😀");
                    default:
                      return Text("");
                  }
                } else {
                  return Text(value.toInt().toString());
                }
              },
              interval: isEmotionGraph ? 1 : 10,
              reservedSize: 30,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) {
                return Text(value.toInt().toString());
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      ),
    );
  }

  Widget _buildLegendItem(int value, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: Text(
              "$value",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF3F8F8),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF00848B),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: profileData?['profile_image_url'] != null
                          ? NetworkImage(profileData!['profile_image_url'])
                          : const AssetImage('assets/profile.png')
                              as ImageProvider,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${profileData?['firstname'] ?? 'Admin'} ${profileData?['lastname'] ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userEmail ?? 'Email Not Available',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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
                      builder: (context) => Home(userId: widget.email),
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
                      builder: (context) => Studentlist(
                          userId: supabase.auth.currentUser?.id ?? ''),
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
                      builder: (context) => GuidanceProfile(
                          userId: supabase.auth.currentUser?.id ?? ''),
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
                      builder: (context) => NotificationPage(
                          userId: supabase.auth.currentUser?.id ?? ''),
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
                      builder: (context) => Consultation(
                          userId: supabase.auth.currentUser?.id ?? ''),
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
                      builder: (context) => Summaryreports(
                          userId: supabase.auth.currentUser?.id ?? ''),
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
                    MaterialPageRoute(builder: (context) => Home(userId: '')),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar with Menu and Logo
                      Row(
                        children: [
                          IconButton(
                            icon: Image.asset(
                              'assets/menu.png',
                              width: 80,
                              height: 21,
                            ),
                            onPressed: () {
                              _scaffoldKey.currentState!.openDrawer();
                            },
                          ),
                          Image.asset(
                            'assets/coco1.png',
                            width: 140,
                            height: 50,
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Student Details Section
                      Center(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: 1100, // Maximum width for responsiveness
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundImage:
                                        const AssetImage('assets/profile.png'),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Email: ${widget.studentEmail}'),
                                        Text(
                                            'Fullname: ${widget.firstname} ${widget.lastname}'),
                                        Text('Course: ${widget.college}'),
                                        Text(
                                            'Year Level: ${widget.yearLevel ?? "Not Available"}'),
                                        Text(
                                          'Stress Average: ${latestStressScale ?? "Not Available"}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Graph Section with Legend
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.arrow_left,
                                                  color: Color(0xFF00848B)),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedDate = DateTime(
                                                    _selectedDate.year,
                                                    _selectedDate.month - 1,
                                                  );
                                                  fetchEmotionData();
                                                  fetchSudsData();
                                                });
                                              },
                                            ),
                                            Text(
                                              DateFormat('MMMM yyyy')
                                                  .format(_selectedDate),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF00848B),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.arrow_right,
                                                  color: Color(0xFF00848B)),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedDate = DateTime(
                                                    _selectedDate.year,
                                                    _selectedDate.month + 1,
                                                  );
                                                  fetchEmotionData();
                                                  fetchSudsData();
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  isEmotionGraph = true;
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isEmotionGraph
                                                    ? const Color(0xFF00848B)
                                                    : Colors.grey[300],
                                              ),
                                              child: Text(
                                                'Emotion',
                                                style: TextStyle(
                                                  color: isEmotionGraph
                                                      ? Colors.white
                                                      : const Color(0xFF00848B),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  isEmotionGraph = false;
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: !isEmotionGraph
                                                    ? const Color(0xFF00848B)
                                                    : Colors.grey[300],
                                              ),
                                              child: Text(
                                                'SUDS',
                                                style: TextStyle(
                                                  color: !isEmotionGraph
                                                      ? Colors.white
                                                      : const Color(0xFF00848B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Container(
                                          height: 250,
                                          padding: const EdgeInsets.all(10.0),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.1),
                                                spreadRadius: 2,
                                                blurRadius: 3,
                                              ),
                                            ],
                                          ),
                                          child: buildBarGraph(
                                            dataPoints: isEmotionGraph
                                                ? emotionDataPoints
                                                : sudsDataPoints,
                                            isEmotionGraph: isEmotionGraph,
                                            maxY: isEmotionGraph ? 5 : 100,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Center(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              // Define what happens when Message is pressed
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF00848B),
                                            ),
                                            child: const Text(
                                              'Message',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        _buildLegendItem(
                                            100,
                                            "Highest distress/fear/anxiety/discomfort that you have ever felt",
                                            Colors.red),
                                        _buildLegendItem(
                                            90,
                                            "Extremely anxious/distressed",
                                            Colors.red.shade400),
                                        _buildLegendItem(
                                            80,
                                            "Very anxious/distressed",
                                            Colors.orange),
                                        _buildLegendItem(
                                            70,
                                            "Quite anxious/distressed, interfering with performance",
                                            Colors.orangeAccent),
                                        _buildLegendItem(
                                            60,
                                            "Moderate anxiety/distress",
                                            Colors.yellow),
                                        _buildLegendItem(
                                            50,
                                            "Moderate anxiety/distress",
                                            Colors.yellow.shade300),
                                        _buildLegendItem(
                                            40,
                                            "Moderate anxiety/distress",
                                            Colors.greenAccent),
                                        _buildLegendItem(
                                            30,
                                            "Mild anxiety/distress",
                                            Colors.green),
                                        _buildLegendItem(
                                            20,
                                            "Minimal anxiety/distress",
                                            Colors.lightGreen),
                                        _buildLegendItem(
                                            10, "Alert and awake", Colors.blue),
                                        _buildLegendItem(
                                            0, "Totally relaxed", Colors.cyan),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]))));
  }
}
