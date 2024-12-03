import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guidance/chat/call/callpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../utils/constants.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.roomId, required this.recipientName})
      : super(key: key);

  final String roomId;
  final String recipientName;

  static Route<void> route(
      {required String roomId, required String recipientName}) {
    return MaterialPageRoute(
      builder: (context) =>
          ChatPage(roomId: roomId, recipientName: recipientName),
    );
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Stream<List<Message>> _messagesStream;
  final Map<String, Profile> _profileCache = {};

  @override
  void initState() {
    super.initState();
    final myUserId = supabase.auth.currentUser!.id;

    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at')
        .map((maps) {
          print('Fetched messages: $maps');
          return maps
              .map((map) => Message.fromMap(
                  map: map, myUserId: supabase.auth.currentUser!.id))
              .toList();
        })
        .handleError((error) {
          print('Stream error: $error');
        });
  }

  Future<void> _loadProfileCache(String userId) async {
    if (_profileCache[userId] != null) return;

    try {
      final studentData = await supabase
          .from('user_student_profile')
          .select()
          .eq('user_id', userId)
          .single()
          .catchError((_) => null);

      _profileCache[userId] = Profile.fromStudentMap(studentData);

      setState(() {});
    } catch (error) {
      print('Error loading profile cache for $userId: $error');
    }
  }

  void _startCall(String callType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(
          userID: supabase.auth.currentUser!.id,
          userName: widget.recipientName,
          callID: widget.roomId,
          isVideoCall: callType == 'video',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
        actions: [
          IconButton(
            icon: const Icon(Icons.call), // Voice call icon
            onPressed: () => _startCall('voice'),
          ),
          IconButton(
            icon: const Icon(Icons.videocam), // Video call icon
            onPressed: () => _startCall('video'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Stream error: ${snapshot.error}');
                  return const Center(child: Text('Error loading messages'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No messages yet. Start the conversation!'));
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    _loadProfileCache(message.userId);

                    return _ChatBubble(
                      message: message,
                      profile: _profileCache[message.userId],
                    );
                  },
                );
              },
            ),
          ),
          const _MessageBar(),
        ],
      ),
    );
  }
}

class _MessageBar extends StatefulWidget {
  const _MessageBar({Key? key}) : super(key: key);

  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  late final TextEditingController _textController;

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final myUserId = supabase.auth.currentUser!.id;

    if (text.isEmpty) return;

    _textController.clear();
    try {
      await supabase.from('messages').insert({
        'user_id': myUserId,
        'room_id':
            (context.findAncestorStateOfType<_ChatPageState>()!).widget.roomId,
        'content': text,
      });
    } on PostgrestException catch (error) {
      print('Database error: ${error.message}');
      context.showErrorSnackBar(message: error.message);
    } catch (error) {
      print('Unexpected error: $error');
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[200],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _textController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    Key? key,
    required this.message,
    required this.profile,
  }) : super(key: key);

  final Message message;
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final chatAlignment =
        message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: chatAlignment,
        children: [
          if (!message.isMine && profile != null)
            CircleAvatar(
              child: Text(profile!.name.substring(0, 1).toUpperCase()),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: message.isMine
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message.content),
            ),
          ),
        ],
      ),
    );
  }
}
