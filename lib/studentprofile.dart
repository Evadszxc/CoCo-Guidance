import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'guidanceprofile/guidanceprofile.dart';
import 'messages.dart';
import 'notification.dart';
import 'consultation.dart';
import 'summaryreports.dart';
import 'home.dart';
import 'studentlist.dart';

class Studentprofile extends StatefulWidget {
  final String email; // Guidance user's email
  final String studentEmail; // Student's email
  final String firstname;
  final String lastname;
  final String college;
  final String? yearLevel;
  final String studentId; // Use student_id instead of email

  Studentprofile({
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
    final response = await supabase
        .from('user_guidance_profiles')
        .select('firstname, lastname, profile_image_url')
        .eq('user_id', supabase.auth.currentUser?.id)
        .single()
        .execute();

    if (response.status == 200 && response.data != null) {
      setState(() {
        profileData = response.data;
        userEmail = supabase.auth.currentUser?.email;
      });
    } else {
      print("Error fetching profile data: ${response.status}");
    }
  }

  Future<void> fetchStudentProfileData() async {
    try {
      // Fetch student_id from auth.users using email
      final userIdResponse = await supabase
          .from('auth.users')
          .select('id')
          .eq('email', widget.studentEmail)
          .single()
          .execute();

      if (userIdResponse.status == 200 && userIdResponse.data != null) {
        String studentId = userIdResponse.data['id'];

        // Fetch student profile data using student_id
        final profileResponse = await supabase
            .from('user_student_profile')
            .select('firstname, lastname, year_level')
            .eq('student_id', studentId)
            .single()
            .execute();

        if (profileResponse.status == 200 && profileResponse.data != null) {
          setState(() {
            studentProfileData = profileResponse.data;
          });
        } else {
          print(
              "Error fetching student profile data: ${profileResponse.status}");
        }
      } else {
        print("Error fetching student_id: ${userIdResponse.status}");
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  Future<void> fetchLatestStressScale() async {
    final response = await supabase
        .from('stress')
        .select('stress_scale')
        .eq('student_id', widget.studentId)
        .execute();

    if (response.status == 200 && response.data != null) {
      final stressData = response.data as List<dynamic>;

      if (stressData.isNotEmpty) {
        double totalStress = stressData.fold<double>(
            0.0, (sum, item) => sum + (item['stress_scale'] ?? 0.0));

        double stressAverage = totalStress / stressData.length;

        setState(() {
          latestStressScale = stressAverage.toStringAsFixed(2);
        });
      } else {
        setState(() {
          latestStressScale = "No Data";
        });
      }
    } else {
      setState(() {
        latestStressScale = "Error Fetching";
      });
      print("Error fetching stress scale: ${response.status}");
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
          .lt('created_at', endDate.toIso8601String())
          .execute();

      if (response.status == 200 && response.data != null) {
        final groupedByDay = <int, Map<String, int>>{};

        for (var record in response.data) {
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
        print("Error fetching emotion data: ${response.status}");
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
          .lt('timestamp', endDate.toIso8601String())
          .execute();

      if (response.status == 200 && response.data != null) {
        final groupedByDay = <int, Map<int, int>>{};

        for (final item in response.data) {
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
        print("Error fetching SUDS data: ${response.status}");
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
                      builder: (context) =>
                          Messages(userId: supabase.auth.currentUser?.id ?? ''),
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
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Image.asset(
                      'assets/menu.png',
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                    ),
                    onPressed: () {
                      _scaffoldKey.currentState!.openDrawer();
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
              ),
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage('assets/profile.png'),
                        ),
                        SizedBox(height: 10),
                        Text('Email: ${widget.studentEmail}'),
                        Text(
                            'Fullname: ${widget.firstname} ${widget.lastname}'),
                        Text('College: ${widget.college}'),
                        Text(
                            'Year Level: ${widget.yearLevel ?? "Not Available"}'),
                        Text(
                          'Stress Average: ${latestStressScale ?? "Not Available"}',
                          style: TextStyle(
                            color: latestStressScale != null
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00848B),
                          ),
                          child: Text('Message',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_left,
                                  color: Color(0xFF00848B)),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = DateTime(_selectedDate.year,
                                      _selectedDate.month - 1);
                                  fetchEmotionData();
                                  fetchSudsData();
                                });
                              },
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00848B),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_right,
                                  color: Color(0xFF00848B)),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = DateTime(_selectedDate.year,
                                      _selectedDate.month + 1);
                                  fetchEmotionData();
                                  fetchSudsData();
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isEmotionGraph = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEmotionGraph
                                    ? Color(0xFF00A19D)
                                    : Colors.grey[300],
                              ),
                              child: Text(
                                "Emotion",
                                style: TextStyle(
                                  color: isEmotionGraph
                                      ? Colors.white
                                      : Color(0xFF00A19D),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isEmotionGraph = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !isEmotionGraph
                                    ? Color(0xFF00A19D)
                                    : Colors.grey[300],
                              ),
                              child: Text(
                                "SUDS",
                                style: TextStyle(
                                  color: !isEmotionGraph
                                      ? Colors.white
                                      : Color(0xFF00A19D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 40,
                          width: 20,
                        ),
                        SizedBox(
                          width: 1200, // Adjust the length (width) of the graph
                          child: Container(
                            padding: EdgeInsets.all(10.0),
                            height: 300, // Adjust the height of the graph
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: BarChart(
                              BarChartData(
                                maxY: isEmotionGraph ? 5 : 100,
                                barGroups: (isEmotionGraph
                                        ? emotionDataPoints
                                        : sudsDataPoints)
                                    .map((spot) {
                                  return BarChartGroupData(
                                    x: spot.x.toInt(),
                                    barRods: [
                                      BarChartRodData(
                                        toY: spot.y,
                                        width: 8,
                                        color: isEmotionGraph
                                            ? Colors.blue
                                            : Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                }).toList(),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, _) {
                                        return Text(value.toInt().toString());
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: isEmotionGraph ? 1 : 10,
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
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: FlGridData(show: false),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
