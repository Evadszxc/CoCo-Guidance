import 'package:flutter/material.dart';

class Videocall extends StatefulWidget {
  @override
  _VideocallState createState() => _VideocallState();
}

class _VideocallState extends State<Videocall> {
  Widget _buildDrawerItem({required IconData icon, required String title}) {
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
      onTap: () {
        // Add navigation logic here
      },
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
                  Image.asset(
                    'assets/profile.png',
                    width: 80,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Nariah Sy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Guidance@uic.edu.ph',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(icon: Icons.list, title: 'Student List'),
            _buildDrawerItem(icon: Icons.person, title: 'Profile'),
            _buildDrawerItem(icon: Icons.message, title: 'Messages'),
            _buildDrawerItem(icon: Icons.notifications, title: 'Notification'),
            _buildDrawerItem(icon: Icons.local_hospital, title: 'Consultation'),
            _buildDrawerItem(icon: Icons.summarize, title: 'Summary Reports'),
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
        padding: const EdgeInsets.all(16.0),
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
                    width: 1100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          // Grey Box containing the video call layout
                          Container(
                            width: 1300,
                            height: 400, // Fixed height for the grey box
                            decoration: BoxDecoration(
                              color: Color(0xFFF4F6F6),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: const EdgeInsets.all(40.0),
                            child: Stack(
                              children: [
                                // Main Video Feed Placeholder (Guidance Counselor)
                                Center(
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: Icon(
                                      Icons.person_outline,
                                      size: 200,
                                      color: Colors.grey,
                                    ), // Placeholder for guidance counselor
                                  ),
                                ),
                                // Student Video Feed Placeholder (bottom-right)
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: Container(
                                    width: 120,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Center(
                                        child: Icon(
                                          Icons.person_outline,
                                          size: 100,
                                          color: Colors.grey,
                                        ), // Placeholder for student
                                      ),
                                    ),
                                  ),
                                ),
                                // Bottom Control Buttons (Mute, Share Screen, etc.)
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.mic_off,
                                            color: Colors.white),
                                        onPressed: () {}, // Mute action
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.screen_share,
                                            color: Colors.white),
                                        onPressed: () {}, // Share screen action
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.videocam_off,
                                            color: Colors.white),
                                        onPressed:
                                            () {}, // Camera on/off action
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.settings,
                                            color: Colors.white),
                                        onPressed: () {}, // Settings action
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.call_end,
                                            color: Colors.red),
                                        onPressed: () {}, // End call action
                                      ),
                                    ],
                                  ),
                                )
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
    home: Videocall(),
  ));
}
