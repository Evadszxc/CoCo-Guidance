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

class Home extends StatefulWidget {
  final String email;

  Home({required this.email});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabaseClient supabase = Supabase.instance.client;

  DateTime selectedDate = DateTime.now();
  List<FlSpot> emotionDataPoints = [];
  List<FlSpot> sudsDataPoints = [];
  bool isEmotionGraph = true; // Toggle between Emotion and SUDS graphs
  Map<String, dynamic>? profileData;

  final Map<String, double> emotionMap = {
    'very_happy': 5,
    'happy': 4,
    'neutral': 3,
    'worried': 2,
    'sad': 1,
    'mad': 0,
  };

  @override
  void initState() {
    super.initState();
    fetchEmotionData();
    fetchSudsData();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    final response = await supabase
        .from('guidancecounselor')
        .select()
        .eq('email', widget.email)
        .single()
        .execute();

    if (response.status == 200) {
      setState(() {
        profileData = response.data;
      });
    } else {
      print(
          "Error fetching profile data: ${response.status}, ${response.data}");
    }
  }

  Future<void> fetchEmotionData() async {
    final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    final response = await supabase
        .from('emotionresponse')
        .select()
        .gte('timestamp', startOfMonth.toIso8601String())
        .lte('timestamp', endOfMonth.toIso8601String())
        .order('timestamp', ascending: true)
        .execute();

    if (response.status == 200 && response.data != null) {
      final data = response.data;
      Map<int, String> dailyDominantEmotion = {};

      for (var entry in data) {
        final timestamp = DateTime.parse(entry['timestamp']);
        final dayOfMonth = timestamp.day;
        final emotion = entry['emotion'] as String;

        if (!dailyDominantEmotion.containsKey(dayOfMonth)) {
          dailyDominantEmotion[dayOfMonth] = emotion;
        }
      }

      setState(() {
        emotionDataPoints = dailyDominantEmotion.entries.map<FlSpot>((entry) {
          final day = entry.key.toDouble();
          final yValue = emotionMap[entry.value] ?? 0.0;
          return FlSpot(day, yValue);
        }).toList();
      });
    } else {
      print(
          "Error fetching emotion data: ${response.status}, ${response.data}");
    }
  }

  Future<void> fetchSudsData() async {
    final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    final response = await supabase
        .from('stress')
        .select()
        .gte('timestamp', startOfMonth.toIso8601String())
        .lte('timestamp', endOfMonth.toIso8601String())
        .order('timestamp', ascending: true)
        .execute();

    if (response.status == 200 && response.data != null) {
      final data = response.data;

      setState(() {
        sudsDataPoints = data.map<FlSpot>((entry) {
          final timestamp = DateTime.parse(entry['timestamp']);
          final dayOfMonth = timestamp.day.toDouble();
          final stressScale = entry['stress_scale'].toDouble();
          return FlSpot(dayOfMonth, stressScale);
        }).toList();
      });
    } else {
      print("Error fetching SUDS data: ${response.status}, ${response.data}");
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
                    profileData?['firstname'] ?? 'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    profileData?['email'] ?? '',
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
                      builder: (context) => Home(email: widget.email)),
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
                      builder: (context) => Studentlist(email: widget.email)),
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
                          GuidanceProfile(email: widget.email)),
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
                      builder: (context) => Messages(email: widget.email)),
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
                          NotificationPage(email: widget.email)),
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
                      builder: (context) => Consultation(email: widget.email)),
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
                      builder: (context) =>
                          Summaryreports(email: widget.email)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Sign Out', style: TextStyle(color: Colors.red)),
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
                  child: Text("Emotion",
                      style: TextStyle(
                          color: isEmotionGraph
                              ? Colors.white
                              : Color(0xFF00A19D))),
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
                  child: Text("SUDS",
                      style: TextStyle(
                          color: !isEmotionGraph
                              ? Colors.white
                              : Color(0xFF00A19D))),
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
                    child: LineChart(
                      LineChartData(
                        minX: 1,
                        maxX: DateTime(
                                selectedDate.year, selectedDate.month + 1, 0)
                            .day
                            .toDouble(),
                        minY: isEmotionGraph ? 0 : 0,
                        maxY: isEmotionGraph ? 5 : 100,
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
                                      return Text("😢");
                                    case 2:
                                      return Text("😟");
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
                              interval: 5,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: isEmotionGraph
                                ? emotionDataPoints
                                : sudsDataPoints,
                            isCurved: false,
                            barWidth: 2,
                            color: Colors.black,
                            dotData: FlDotData(show: true),
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
    home: Home(email: 'Guidance@uic.edu.ph'),
    debugShowCheckedModeBanner: false,
  ));
}
