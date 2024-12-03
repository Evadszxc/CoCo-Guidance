import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat/chat/pages/guidancelist.dart';
import 'studentlist.dart';
import 'messages.dart';
import 'notification.dart';
import 'summaryreports.dart';
import 'guidanceprofile/guidanceprofile.dart';
import 'home.dart';
import 'login.dart';
import 'upload.dart';

class Consultation extends StatefulWidget {
  final String userId;

  Consultation({required this.userId});

  @override
  _ConsultationState createState() => _ConsultationState();
}

class _ConsultationState extends State<Consultation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? profileData;
  String? userEmail;
  String? guidanceId;
  TimeOfDay? _selectedTime;
  DateTime? _selectedDate;
  List<Map<String, dynamic>> consultationRequests = [];
  List<Map<String, dynamic>> scheduledConsultations = [];

  @override
  void initState() {
    super.initState();

    // Fetch the guidance ID first, then execute dependent fetches
    _initialize();
  }

  Future<void> _initialize() async {
    // Fetch guidanceId first
    await fetchGuidanceId();

    // Now call the other dependent fetch methods
    await fetchConsultationRequests();
    await fetchScheduledConsultations();
    await fetchProfileData();
    await _fetchUserEmail();
  }

  Future<void> fetchGuidanceId() async {
    try {
      final response = await supabase
          .from('user_guidance_profiles')
          .select('guidance_id')
          .eq('user_id', widget.userId)
          .single();

      if (response != null) {
        setState(() {
          guidanceId = response['guidance_id'];
        });
      }
    } catch (e) {
      print('Error fetching guidanceId: $e');
    }
  }

  Future<void> fetchProfileData() async {
    try {
      final response = await supabase
          .from('user_guidance_profiles')
          .select('firstname, lastname, profile_image_url')
          .eq('user_id', widget.userId)
          .single();

      if (response != null) {
        setState(() {
          profileData = response;
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  Future<void> _fetchUserEmail() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        setState(() {
          userEmail = user.email;
        });
      }
    } catch (e) {
      print("Error fetching user email: $e");
    }
  }

  Future<void> fetchConsultationRequests() async {
    if (guidanceId == null || guidanceId!.isEmpty) {
      print('guidanceId is null or empty. Skipping fetchConsultationRequests.');
      return;
    }

    try {
      final response = await supabase
          .from('consultation_request')
          .select(
              'id, description, student_id, student:student_id (firstname, lastname)')
          .eq('guidance_id',
              guidanceId!) // Use guidanceId! to assert non-null value
          .eq('status', 'Pending');

      if (response != null && response is List<dynamic>) {
        setState(() {
          consultationRequests = List<Map<String, dynamic>>.from(
              response); // Cast the response properly
        });
      } else {
        print('Error: Invalid response format or empty data.');
      }
    } catch (e) {
      print('Exception fetching consultation requests: $e');
    }
  }

  Future<void> fetchScheduledConsultations() async {
    if (guidanceId == null || guidanceId!.isEmpty) {
      print(
          'guidanceId is null or empty. Skipping fetchScheduledConsultations.');
      return;
    }

    try {
      final response = await supabase
          .from('session')
          .select(
              'id, schedule, sessiontype, location, consultation_status, student:student_id (firstname, lastname)')
          .eq('guidance_id',
              guidanceId!); // Use guidanceId! to assert non-null value

      if (response != null && response is List<dynamic>) {
        setState(() {
          scheduledConsultations = List<Map<String, dynamic>>.from(
              response); // Properly cast the response
        });
      } else {
        print('Error: Invalid response format or empty data.');
      }
    } catch (e) {
      print('Exception fetching scheduled consultations: $e');
    }
  }

  void _showScheduleDialog(int index, {bool isReschedule = false}) {
    setState(() {
      _selectedTime = null;
      _selectedDate = null;
    });

    String? selectedSessionType;
    String? selectedLocation;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isReschedule ? 'Reschedule Consultation' : 'Set Schedule',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                _buildTimePicker(),
                SizedBox(height: 10),
                _buildDatePicker(),
                SizedBox(height: 10),
                _buildDropdown(
                  label: 'Session Type',
                  value: selectedSessionType,
                  items: ['Video Call', 'Face-to-Face'],
                  onChanged: (value) {
                    setState(() {
                      selectedSessionType = value;
                    });
                  },
                ),
                SizedBox(height: 10),
                _buildDropdown(
                  label: 'Location',
                  value: selectedLocation,
                  items: ['Online', 'Main', 'Annex'],
                  onChanged: (value) {
                    setState(() {
                      selectedLocation = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedDate == null ||
                        _selectedTime == null ||
                        selectedSessionType == null ||
                        selectedLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill in all fields.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (isReschedule) {
                      // Update session details
                      await _updateSchedule(
                          index, selectedSessionType!, selectedLocation!);
                    } else {
                      // Create a new schedule
                      await _saveSchedule(
                          index, selectedSessionType!, selectedLocation!);
                    }

                    Navigator.pop(context);
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

  Future<void> _updateSchedule(
      int index, String sessionType, String location) async {
    final DateTime schedule = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      await supabase.from('session').update({
        'schedule': schedule.toIso8601String(),
        'sessiontype': sessionType,
        'location': location,
      }).eq('id', scheduledConsultations[index]['id']);

      fetchScheduledConsultations();
    } catch (e) {
      print('Error updating schedule: $e');
    }
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label:', style: TextStyle(fontSize: 16)),
        DropdownButton<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          hint: Text('Select $label'),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Time:', style: TextStyle(fontSize: 16)),
        InkWell(
          onTap: () async {
            TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: _selectedTime ?? TimeOfDay.now(),
            );
            if (pickedTime != null) {
              setState(() {
                _selectedTime = pickedTime;
              });
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_selectedTime?.format(context) ?? 'Select Time'),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Date:', style: TextStyle(fontSize: 16)),
        InkWell(
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
              });
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_selectedDate != null
                ? DateFormat.yMMMd().format(_selectedDate!)
                : 'Select Date'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSchedule(
      int index, String sessionType, String location) async {
    final DateTime schedule = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      // Extracting the student_id from consultationRequests
      final studentId = consultationRequests[index]['student_id'];
      if (studentId == null) {
        print('Error: student_id is null.');
        return;
      }

      // Combine firstname and lastname for the professional_name
      final professionalName =
          '${profileData?['firstname'] ?? ''} ${profileData?['lastname'] ?? ''}';

      // Insert into session table
      await supabase.from('session').insert({
        'student_id': studentId,
        'guidance_id': guidanceId,
        'schedule': schedule.toIso8601String(),
        'sessiontype': sessionType,
        'location': location,
        'consultation_status': 'Pending',
        'professional_name': professionalName, // Save professional name here
      });

      // Update consultation_request table
      await supabase.from('consultation_request').update(
          {'status': 'Approved'}).eq('id', consultationRequests[index]['id']);

      fetchConsultationRequests();
      fetchScheduledConsultations();
    } catch (e) {
      print('Error saving schedule: $e');
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
            onTap: () => Navigator.pop(context),
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
    print('Scheduled Consultations in UI: $scheduledConsultations');

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
            SizedBox(
              height: 5,
            ),
            Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: 0, left: 120),
                    child: Text(
                      "",
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
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONSULTATION REQUEST',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00848B),
                            ),
                          ),
                          SizedBox(height: 10),
                          Expanded(
                            child: consultationRequests.isNotEmpty
                                ? ListView.builder(
                                    itemCount: consultationRequests.length,
                                    itemBuilder: (context, index) {
                                      final request =
                                          consultationRequests[index];
                                      final fullname =
                                          '${request['student']['firstname']} ${request['student']['lastname']}';
                                      final description =
                                          request['description'] ??
                                              'No Description';

                                      return Card(
                                        child: ListTile(
                                          title: Text(fullname),
                                          subtitle: Text(description),
                                          trailing: ElevatedButton(
                                            onPressed: () =>
                                                _showScheduleDialog(index),
                                            child: Text('Set Schedule'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Color(0xFF00848B),
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      'No consultation requests found.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MY SCHEDULE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00848B),
                            ),
                          ),
                          SizedBox(height: 10),
                          Expanded(
                            child: scheduledConsultations.isNotEmpty
                                ? ListView.builder(
                                    itemCount: scheduledConsultations.length,
                                    itemBuilder: (context, index) {
                                      final schedule =
                                          scheduledConsultations[index];
                                      final fullname = schedule['student'] !=
                                              null
                                          ? '${schedule['student']['firstname'] ?? 'Unknown'} ${schedule['student']['lastname'] ?? ''}'
                                          : 'Unknown Student';
                                      final scheduleTime =
                                          schedule['schedule'] != null
                                              ? DateTime.tryParse(
                                                  schedule['schedule'])
                                              : null;
                                      final sessionType =
                                          schedule['sessiontype'] ?? 'N/A';
                                      final location =
                                          schedule['location'] ?? 'N/A';
                                      final status =
                                          schedule['consultation_status'] ??
                                              'Unknown';

                                      return Card(
                                        margin:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                        child: ListTile(
                                          title: Text(fullname),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Date: ${scheduleTime != null ? DateFormat('yyyy-MM-dd').format(scheduleTime) : 'N/A'}',
                                              ),
                                              Text(
                                                'Time: ${scheduleTime != null ? DateFormat('hh:mm a').format(scheduleTime) : 'N/A'}',
                                              ),
                                              Text('Status: $status'),
                                              Text('Type: $sessionType'),
                                              Text('Location: $location'),
                                            ],
                                          ),
                                          trailing: ElevatedButton(
                                            onPressed: () =>
                                                _showScheduleDialog(index,
                                                    isReschedule: true),
                                            child: Text('Reschedule'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Color(0xFF00848B),
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      'No scheduled consultations.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                          ),
                        ],
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
    home: Consultation(userId: 'user-id-placeholder'),
    debugShowCheckedModeBanner: false,
  ));
}
