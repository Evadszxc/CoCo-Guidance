import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'studentlist.dart';
import 'guidanceprofile/guidanceprofile.dart';
import 'messages.dart';
import 'notification.dart';
import 'consultation.dart';
import 'summaryreports.dart';
import 'login.dart';
import 'upload.dart';

class Home extends StatefulWidget {
  final String userId;

  Home({required this.userId});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabaseClient supabase = Supabase.instance.client;

  DateTime selectedDate = DateTime.now();
  List<FlSpot> emotionDataPoints = [];
  List<FlSpot> sudsDataPoints = [];
  bool isEmotionGraph = true;
  bool isLoading = true;
  Map<String, dynamic>? profileData;
  String? userEmail;

  final Map<String, double> emotionMap = {
    'very happy': 5,
    'happy': 4,
    'meh': 3,
    'worried': 2,
    'sad': 1,
    'mad': 0,
  };

  final Map<double, String> emotionLabels = {
    0: "😡",
    1: "😢",
    2: "😨",
    3: "😐",
    4: "🙂",
    5: "😀",
  };

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
      await Future.wait([
        fetchEmotionData(),
        fetchSudsData(),
        fetchProfileData(),
        _fetchUserEmail(),
      ]);
    } catch (e) {
      print("Error initializing data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchProfileData() async {
    final response = await supabase
        .from('user_guidance_profiles')
        .select('firstname, lastname, profile_image_url, college_handled')
        .eq('user_id', widget.userId)
        .single()
        .execute();

    if (response.status == 200 && response.data != null) {
      setState(() {
        profileData = response.data;
      });
    } else {
      print("Error fetching profile data. Status: ${response.status}");
    }
  }

  Future<void> fetchEmotionData() async {
    final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    final response = await supabase
        .from('emotionresponse')
        .select('created_at, emotions') // Fetch all emotions
        .gte('created_at', startOfMonth.toIso8601String())
        .lte('created_at', endOfMonth.toIso8601String())
        .order('created_at', ascending: true)
        .execute();

    if (response.status == 200 && response.data != null) {
      final data = response.data;

      Map<int, String> dailyDominantEmotion = {};
      Map<int, Map<String, int>> dailyEmotionCounts = {};

      for (var entry in data) {
        final timestamp = DateTime.parse(entry['created_at']);
        final dayOfMonth = timestamp.day;
        final emotion = entry['emotions'] as String;

        dailyEmotionCounts.putIfAbsent(dayOfMonth, () => {});
        dailyEmotionCounts[dayOfMonth]![emotion] =
            (dailyEmotionCounts[dayOfMonth]![emotion] ?? 0) + 1;
      }

      dailyEmotionCounts.forEach((day, emotions) {
        String dominantEmotion = '';
        int maxCount = 0;

        emotions.forEach((emotion, count) {
          if (count > maxCount) {
            maxCount = count;
            dominantEmotion = emotion;
          }
        });

        dailyDominantEmotion[day] = dominantEmotion;
      });

      setState(() {
        emotionDataPoints = dailyDominantEmotion.entries.map<FlSpot>((entry) {
          final day = entry.key.toDouble();
          final yValue = emotionMap[entry.value] ?? 0.0;
          return FlSpot(day, yValue);
        }).toList();
      });
    } else {
      print("Error fetching emotion data. Status: ${response.status}");
    }
  }

  Future<void> fetchSudsData() async {
    final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    final response = await supabase
        .from('stress')
        .select('timestamp, stress_scale') // Fetch stress data for all students
        .gte('timestamp', startOfMonth.toIso8601String())
        .lte('timestamp', endOfMonth.toIso8601String())
        .order('timestamp', ascending: true)
        .execute();

    if (response.status == 200 && response.data != null) {
      final data = response.data;

      Map<int, int> dailyDominantStress = {};
      for (var entry in data) {
        final timestamp = DateTime.parse(entry['timestamp']);
        final dayOfMonth = timestamp.day;
        final stressScale = entry['stress_scale'] as int;

        dailyDominantStress[dayOfMonth] = stressScale;
      }

      setState(() {
        sudsDataPoints = dailyDominantStress.entries.map<FlSpot>((entry) {
          final day = entry.key.toDouble();
          final stressValue = entry.value.toDouble();
          return FlSpot(day, stressValue);
        }).toList();
      });
    } else {
      print("Error fetching SUDS data. Status: ${response.status}");
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        fetchEmotionData();
        fetchSudsData();
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
                color: Colors.blue,
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
                  return Text(emotionLabels[value.toDouble()] ?? "");
                } else {
                  return Text(value.toInt().toString());
                }
              },
              interval: isEmotionGraph ? 1 : 10,
              reservedSize: 40,
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
    String formattedDate = DateFormat("MMMM yyyy").format(selectedDate);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Image.asset('assets/menu.png', width: 30, height: 30),
                  onPressed: () => _scaffoldKey.currentState!.openDrawer(),
                ),
                SizedBox(width: 10),
                Image.asset(
                  'assets/coco1.png',
                  width: 150,
                  height: 50,
                ),
              ],
            ),
            SizedBox(
              height: 30,
            ),
            Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: 0, left: 120),
                    child: Text(
                      "Home",
                      style: TextStyle(
                        fontSize: 24,
                        color: Color(0xFF00848B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00848B),
                ),
              ),
            ),
            SizedBox(height: 20),
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
                    backgroundColor:
                        isEmotionGraph ? Color(0xFF00A19D) : Colors.grey[200],
                  ),
                  child: Text(
                    "Emotion",
                    style: TextStyle(
                      color: isEmotionGraph ? Colors.white : Color(0xFF00A19D),
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
                    backgroundColor:
                        !isEmotionGraph ? Color(0xFF00A19D) : Colors.grey[200],
                  ),
                  child: Text(
                    "SUDS",
                    style: TextStyle(
                      color: !isEmotionGraph ? Colors.white : Color(0xFF00A19D),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Container(
                  width: 1000,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: buildBarGraph(
                      dataPoints:
                          isEmotionGraph ? emotionDataPoints : sudsDataPoints,
                      isEmotionGraph: isEmotionGraph,
                      maxY: isEmotionGraph ? 5 : 100,
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
    home: Home(userId: 'user-id-placeholder'),
    debugShowCheckedModeBanner: false,
  ));
}
