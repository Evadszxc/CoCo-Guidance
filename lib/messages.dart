import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat/call/callpage.dart';
import 'chat/call/constant.dart';
import 'studentlist.dart';
import 'guidanceprofile/guidanceprofile.dart';
import 'notification.dart';
import 'consultation.dart';
import 'summaryreports.dart';
import 'home.dart';
import 'login.dart';
import 'dart:html' as html;

class Messages extends StatefulWidget {
  final String userId;

  Messages({required this.userId});

  @override
  _MessagesState createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();

  Map<String, dynamic>? profileData;
  String? userEmail;
  List<Map<String, String>> chatMessages = [
    {"sender": "Adrian Mark Cinchez", "message": "Hi", "isMe": "false"},
    {"sender": "You", "message": "Hello", "isMe": "true"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await supabase
          .from('user_guidance_profiles')
          .select('firstname, lastname, profile_image_url')
          .eq('user_id', widget.userId)
          .single();

      if (response != null) {
        setState(() {
          profileData = response;
          userEmail = supabase.auth.currentUser?.email;
        });
      } else {
        print("Error fetching profile data: No data found.");
      }
    } catch (e) {
      print("Error fetching profile data: $e");
    }
  }

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

  void _startCall(bool isVideoCall) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context); // Remove loading dialog
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPage(
            userID: widget.userId,
            userName: profileData?['firstname'] ?? "Unknown User",
            callID:
                "call_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}",
            isVideoCall: isVideoCall,
          ),
        ),
      );
    });
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF00848B)),
      title: Text(
        title,
        style: TextStyle(color: Color(0xFF00848B)),
      ),
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
                  SizedBox(height: 10),
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
                    builder: (context) => Home(userId: widget.userId),
                  ),
                );
              },
            ),
            // Other drawer items here...
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
            Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: Image.asset(
                    'assets/menu.png',
                    width: 30,
                    height: 30,
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 800,
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MESSAGES',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00B2B0),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.video_call,
                                    color: Color(0xFF00B2B0)),
                                onPressed: () => _startCall(true),
                              ),
                              IconButton(
                                icon:
                                    Icon(Icons.call, color: Color(0xFF00B2B0)),
                                onPressed: () => _startCall(false),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: chatMessages.length,
                          itemBuilder: (context, index) {
                            final chat = chatMessages[index];
                            return ListTile(
                              title: Text(chat['sender'] ?? 'Unknown'),
                              subtitle: Text(chat['message'] ?? ''),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send, color: Color(0xFF00B2B0)),
                            onPressed: _sendMessage,
                          ),
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
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Messages(userId: 'sample-user-id'),
    debugShowCheckedModeBanner: false,
  ));
}
