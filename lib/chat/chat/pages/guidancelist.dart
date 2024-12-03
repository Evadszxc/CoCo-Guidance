import 'package:flutter/material.dart';
import '../models/profile.dart';
import 'chat_page.dart';
import '../utils/constants.dart';

class GuidanceCounselorListPage extends StatefulWidget {
  const GuidanceCounselorListPage({Key? key}) : super(key: key);

  @override
  State<GuidanceCounselorListPage> createState() =>
      _GuidanceCounselorListPageState();
}

class _GuidanceCounselorListPageState extends State<GuidanceCounselorListPage> {
  Future<List<Profile>> _fetchGuidanceCounselors() async {
    final data = await supabase
        .from('user_student_profile')
        .select('user_id, firstname, lastname');
    return data.map<Profile>((map) => Profile.fromGuidanceMap(map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student List')),
      body: FutureBuilder<List<Profile>>(
        future: _fetchGuidanceCounselors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            final counselors = snapshot.data!;
            return ListView.builder(
              itemCount: counselors.length,
              itemBuilder: (context, index) {
                final counselor = counselors[index];
                return ListTile(
                  title: Text(counselor.name),
                  onTap: () async {
                    final roomId =
                        await supabase.rpc('create_new_room', params: {
                      'other_user_id': counselor.userId,
                    });

                    // Pass both roomId and recipientName when navigating to ChatPage
                    Navigator.push(
                      context,
                      ChatPage.route(
                        roomId: roomId,
                        recipientName:
                            counselor.name, // Pass the counselor's name here
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return const Center(child: Text('No counselors found.'));
          }
        },
      ),
    );
  }
}
