import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Studentprofile extends StatefulWidget {
  final String email;
  final String studentEmail;
  final String firstname;
  final String lastname;
  final String college;
  final String yearLevel;

  const Studentprofile({
    required this.email,
    required this.studentEmail,
    required this.firstname,
    required this.lastname,
    required this.college,
    required this.yearLevel,
    Key? key,
  }) : super(key: key);

  @override
  _StudentProfileState createState() => _StudentProfileState();
}

class _StudentProfileState extends State<Studentprofile> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabaseClient supabase = Supabase.instance.client;
  DateTime _selectedDate = DateTime.now();

  List<FlSpot> emotionDataPoints = [];
  List<FlSpot> sudsDataPoints = [];
  bool isEmotionGraph = true;
  String? latestStressScale;

  final Map<double, String> emotionLabels = {
    0: "😡", // Very Angry
    1: "😢", // Sad
    2: "😟", // Worried
    3: "😐", // Neutral
    4: "🙂", // Happy
    5: "😀", // Very Happy
  };

  @override
  void initState() {
    super.initState();
    fetchEmotionData();
    fetchSudsData();
    fetchLatestStressScale();
  }

  Future<String?> fetchStudentIdFromEmail(String email) async {
    try {
      final response = await supabase
          .from('student')
          .select('id')
          .eq('email', email)
          .single();
      return response['id'] as String?;
    } catch (e) {
      print("Error fetching student ID: $e");
      return null;
    }
  }

  Future<void> fetchLatestStressScale() async {
    final studentId = await fetchStudentIdFromEmail(widget.studentEmail);
    if (studentId == null) return;

    try {
      final response = await supabase
          .from('stress')
          .select('*')
          .eq('studentid', studentId)
          .order('timestamp', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        setState(() {
          latestStressScale = response[0]['stress_scale'].toString();
        });
      } else {
        setState(() {
          latestStressScale = null;
        });
      }
    } catch (e) {
      print("Error fetching latest stress scale: $e");
    }
  }

  Future<void> fetchEmotionData() async {
    final studentId = await fetchStudentIdFromEmail(widget.studentEmail);
    if (studentId == null) return;

    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    try {
      final response = await supabase
          .from('emotionresponse')
          .select()
          .eq('studentid', studentId)
          .gte('timestamp', startOfMonth.toIso8601String())
          .lte('timestamp', endOfMonth.toIso8601String());

      if (response.isNotEmpty) {
        final data = response;
        final dailyEmotions = <int, double>{};

        for (var entry in data) {
          final timestamp = DateTime.parse(entry['timestamp']);
          final day = timestamp.day;
          dailyEmotions[day] = entry['emotion'] == 'very_happy'
              ? 5.0
              : entry['emotion'] == 'happy'
                  ? 4.0
                  : entry['emotion'] == 'neutral'
                      ? 3.0
                      : entry['emotion'] == 'worried'
                          ? 2.0
                          : entry['emotion'] == 'sad'
                              ? 1.0
                              : 0.0;
        }

        setState(() {
          emotionDataPoints = dailyEmotions.entries
              .map((e) => FlSpot(e.key.toDouble(), e.value))
              .toList();
        });
      }
    } catch (e) {
      print("Error fetching emotion data: $e");
    }
  }

  Future<void> fetchSudsData() async {
    final studentId = await fetchStudentIdFromEmail(widget.studentEmail);
    if (studentId == null) return;

    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    try {
      final response = await supabase
          .from('stress')
          .select()
          .eq('studentid', studentId)
          .gte('timestamp', startOfMonth.toIso8601String())
          .lte('timestamp', endOfMonth.toIso8601String());

      if (response.isNotEmpty) {
        setState(() {
          sudsDataPoints = response
              .map<FlSpot>((entry) => FlSpot(
                  DateTime.parse(entry['timestamp']).day.toDouble(),
                  entry['stress_scale'].toDouble()))
              .toList();
        });
      }
    } catch (e) {
      print("Error fetching SUDS data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF3F8F8),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Navigation bar
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF00848B)),
                  onPressed: () {
                    _scaffoldKey.currentState!.openDrawer();
                  },
                ),
                const SizedBox(width: 1),
                Image.asset('assets/coco1.png', width: 200, height: 70),
              ],
            ),
            const SizedBox(height: 20),
            // Student details and buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left section: Student details
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage('assets/profile.png'),
                      ),
                      const SizedBox(height: 10),
                      Text('Email: ${widget.studentEmail}'),
                      Text('Fullname: ${widget.firstname} ${widget.lastname}'),
                      Text('College: ${widget.college}'),
                      Text('Year Level: ${widget.yearLevel}'),
                      Text(
                        'Stress Average: ${latestStressScale ?? "Not Available"}',
                        style: TextStyle(
                          color: latestStressScale != null
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {}, // Add messaging logic here
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00848B),
                        ),
                        child: const Text(
                          'Message',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right section: Graphs and buttons
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Date navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_left,
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
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00848B)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_right,
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
                      // Emotion and SUDS buttons
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
                                  ? const Color(0xFF00A19D)
                                  : Colors.grey[300],
                            ),
                            child: Text(
                              "Emotion",
                              style: TextStyle(
                                  color: isEmotionGraph
                                      ? Colors.white
                                      : const Color(0xFF00A19D)),
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
                                  ? const Color(0xFF00A19D)
                                  : Colors.grey[300],
                            ),
                            child: Text(
                              "SUDS",
                              style: TextStyle(
                                  color: !isEmotionGraph
                                      ? Colors.white
                                      : const Color(0xFF00A19D)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // Graph section
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: LineChart(
                          LineChartData(
                            minX: 1,
                            maxX: 30,
                            minY: isEmotionGraph ? 0 : 0,
                            maxY: isEmotionGraph ? 5 : 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: isEmotionGraph
                                    ? emotionDataPoints
                                    : sudsDataPoints,
                                isCurved: true,
                                barWidth: 2,
                                color: const Color(0xFF00848B),
                                dotData: FlDotData(show: true),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    if (isEmotionGraph) {
                                      return Text(emotionLabels[value] ?? '');
                                    } else {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 12),
                                      );
                                    }
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Studentprofile(
      email: 'guidance@uic.edu.ph',
      studentEmail: 'test1@gmail.com',
      firstname: 'Adrian',
      lastname: 'Cinchez',
      college: 'College of Computer Studies',
      yearLevel: '4',
    ),
    debugShowCheckedModeBanner: false,
  ));
}
