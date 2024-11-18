import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting DateTime
import 'package:supabase_flutter/supabase_flutter.dart'; // To connect with Supabase
import 'studentlist.dart';
import 'messages.dart';
import 'notification.dart';
import 'summaryreports.dart';
import 'package:guidance/guidanceprofile/guidanceprofile.dart';
import 'home.dart';

class Consultation extends StatefulWidget {
  final String email; // Accept the logged-in user's email

  Consultation({required this.email}); // Constructor to accept email

  @override
  _ConsultationState createState() => _ConsultationState();
}

class _ConsultationState extends State<Consultation> {
  TimeOfDay? _selectedTime;
  DateTime? _selectedDate;
  List<Map<String, dynamic>> consultationRequests = [];
  List<Map<String, dynamic>> scheduledConsultations = [];
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    fetchConsultationRequests();
    fetchProfileData();
  }

  // Function to fetch consultation requests from the 'session' table
  Future<void> fetchConsultationRequests() async {
    final response = await supabase
        .from('session')
        .select('firstname, lastname, time, date')
        .execute();

    if (response.status == 200 && response.data != null) {
      setState(() {
        consultationRequests = List<Map<String, dynamic>>.from(response.data);
      });
    } else {
      print(
          'Error fetching consultation requests: ${response.status}, ${response.data}');
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

  // Function to show the schedule dialog and set the schedule
  void _showScheduleDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Set Schedule', style: TextStyle(fontSize: 20)),
                SizedBox(height: 20),
                _buildTimePicker(),
                SizedBox(height: 10),
                _buildDatePicker(),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00848B),
                  ),
                  onPressed: () async {
                    await _saveSchedule(index);
                    Navigator.pop(context);
                    fetchConsultationRequests(); // Refresh the list after saving
                  },
                  child: Text('SAVE'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget for Time Picker
  Widget _buildTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Time:'),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFCBE2BB),
          ),
          onPressed: () async {
            TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (pickedTime != null) {
              setState(() {
                _selectedTime = pickedTime;
              });
            }
          },
          child: Text(
            _selectedTime != null
                ? _selectedTime!.format(context)
                : 'Select Time',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  // Widget for Date Picker
  Widget _buildDatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Date:'),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFCBE2BB),
          ),
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
              });
            }
          },
          child: Text(
            _selectedDate != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                : 'Select Date',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }

  // Function to save the selected schedule into the 'session' table
  Future<void> _saveSchedule(int index) async {
    if (_selectedDate != null && _selectedTime != null) {
      final formattedTime = '${_selectedTime!.hour}:${_selectedTime!.minute}';
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final response = await supabase
          .from('session')
          .update({
            'time': formattedTime,
            'date': formattedDate,
          })
          .eq('firstname', consultationRequests[index]['firstname'])
          .eq('lastname', consultationRequests[index]['lastname'])
          .execute();

      if (response.status == 200) {
        setState(() {
          scheduledConsultations.add({
            'firstname': consultationRequests[index]['firstname'],
            'lastname': consultationRequests[index]['lastname'],
            'time': formattedTime,
            'date': formattedDate,
          });
        });
      } else {
        print('Error saving schedule: ${response.status}, ${response.data}');
      }
    }
  }

  Widget _buildDrawerItem(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
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
      backgroundColor: Colors.white,
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
            SizedBox(height: 20),
            // UI for consultation requests and scheduled consultations
            Expanded(
              child: Row(
                children: [
                  // Consultation Request Card (Left)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF3F8F8),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consultation Request',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00B2B0),
                              ),
                            ),
                            SizedBox(height: 10),
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(2),
                              },
                              children: [
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Name'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Action'),
                                    ),
                                  ],
                                ),
                                ...consultationRequests.map((request) {
                                  final index =
                                      consultationRequests.indexOf(request);
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                            '${request['firstname']} ${request['lastname']}'),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _showScheduleDialog(index),
                                          child: Text('Set Schedule'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF00B2B0),
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16), // Add space between the cards
                  // My Consultation Schedule Card (Right)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF3F8F8),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Consultation Schedule',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00B2B0),
                              ),
                            ),
                            SizedBox(height: 10),
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(1),
                                2: FlexColumnWidth(1),
                                3: FlexColumnWidth(1),
                              },
                              children: [
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Name'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Date'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Time'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Action'),
                                    ),
                                  ],
                                ),
                                ...scheduledConsultations.map((schedule) {
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                            '${schedule['firstname']} ${schedule['lastname']}'),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(schedule['date']),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(schedule['time']),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Scheduled'),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
    home: Consultation(email: 'Guidance@uic.edu.ph'), // Pass the email argument
  ));
}
