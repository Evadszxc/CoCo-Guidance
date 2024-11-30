import 'package:flutter/material.dart';
import 'studentlist.dart';
import 'package:guidance/guidanceprofile/guidanceprofile.dart';
import 'notification.dart';
import 'consultation.dart';
import 'summaryreports.dart';
import 'home.dart';

class Messages extends StatefulWidget {
  final String userId; // Accept the logged-in user's ID

  Messages({required this.userId}); // Constructor to accept userId

  @override
  _MessagesState createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> chatMessages = [
    {"sender": "Adrian Mark Cinchez", "message": "Hi", "isMe": "false"},
    {"sender": "You", "message": "Hello", "isMe": "true"},
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        chatMessages.add({
          "sender": "You",
          "message": _messageController.text.trim(),
          "isMe": "true",
        });
      });
      _messageController.clear();
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
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

  Widget _buildChatBubble({
    required String sender,
    required String message,
    required bool isMe,
  }) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe)
          CircleAvatar(
            backgroundImage: AssetImage('assets/profile.png'),
          ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMe ? Color(0xFF00B2B0) : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black,
            ),
          ),
        ),
        if (isMe)
          CircleAvatar(
            backgroundImage: AssetImage('assets/profile.png'),
          ),
      ],
    );
  }

  Widget _buildStudentItem(String name, String year, String stressScale) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Color(0xFF00B2B0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage('assets/profile.png'),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                year,
                style: TextStyle(color: Colors.white),
              ),
              Text(
                'STRESS SCALE: $stressScale',
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
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
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/profile.png'),
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
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Home(userId: widget.userId),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.list,
              title: 'Student List',
              onTap: () {
                Navigator.pushReplacement(
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
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              icon: Icons.notifications,
              title: 'Notification',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotificationPage(userId: widget.userId),
                  ),
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
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                SizedBox(width: 1),
                Image.asset('assets/coco1.png', width: 200, height: 70),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: 800,
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MESSAGES',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00B2B0),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildStudentItem(
                                    'Adrian Mark Cinchez',
                                    'BSIT - 3RD YEAR',
                                    '90',
                                  ),
                                  _buildStudentItem(
                                    'Jenny Babe Cano',
                                    'BSIT - 3RD YEAR',
                                    '60',
                                  ),
                                  _buildStudentItem(
                                    'Dave D. Laburada',
                                    'BSP - 4TH YEAR',
                                    '90',
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 400,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ListView(
                                        children: chatMessages.map((chat) {
                                          return _buildChatBubble(
                                            sender: chat['sender'] ?? 'Unknown',
                                            message: chat['message'] ?? '',
                                            isMe: chat['isMe'] == "true"
                                                ? true
                                                : false,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _messageController,
                                              decoration: InputDecoration(
                                                hintText: "Type here...",
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.send,
                                                color: Color(0xFF00B2B0)),
                                            onPressed: _sendMessage,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
    home: Messages(userId: 'some_user_id'), // Pass the user ID here
  ));
}
