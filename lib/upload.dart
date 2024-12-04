import 'dart:io';
import 'package:flutter/material.dart';
import 'package:guidance/chat/chat/pages/guidancelist.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'studentlist.dart';
import 'notification.dart';
import 'summaryreports.dart';
import 'guidanceprofile/guidanceprofile.dart';
import 'home.dart';
import 'login.dart';
import 'consultation.dart';

class Upload extends StatefulWidget {
  final String userId;

  Upload({required this.userId});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  final SupabaseClient supabase = Supabase.instance.client;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? profileData;
  String? userEmail;

  bool isUploading = false;
  String selectedTab = "Audio"; // Default selected tab
  bool isHoveringAudio = false;
  bool isHoveringVideo = false;
  String selectedCategory = "Motivational Speech"; // Default category

  @override
  void initState() {
    super.initState();
    fetchProfileData();
    fetchUserEmail();
  }

  Future<String?> _showCategorySelectionDialog() async {
    List<String> categories = ["Breathing Exercises", "Meditation", "Music"];

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Self Help Category"),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(categories[index]),
                  onTap: () {
                    Navigator.of(context).pop(categories[index]);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel the dialog
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
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

  Future<void> fetchUserEmail() async {
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

  Future<String?> _showVideoCategorySelectionDialog() async {
    List<String> categories = ["Yoga", "Inspirational Videos"];

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Video Category"),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(categories[index]),
                  onTap: () {
                    Navigator.of(context).pop(categories[index]);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel the dialog
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showInspirationalSubcategoryDialog() async {
    // Ensure the enum values exactly match the database
    List<String> subcategories = [
      "Acts of Kindness",
      "Athletic Achievements",
      "Educational",
      "Growth and Development",
      "Motivational Speech",
      "Success Stories"
    ];

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Inspirational Video Subcategory"),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subcategories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(subcategories[index]),
                  onTap: () {
                    Navigator.of(context)
                        .pop(subcategories[index]); // Use exact value
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel the dialog
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> uploadAudio() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User is not authenticated')),
      );
      return;
    }

    try {
      // Show category selection dialog
      String? selectedCategory = await _showCategorySelectionDialog();
      if (selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload canceled: No category selected')),
        );
        return;
      }

      if (selectedCategory != "Music") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload canceled: Only Music is supported.')),
        );
        return;
      }

      // Fetch guidance ID
      final response = await supabase
          .from('user_guidance_profiles')
          .select('guidance_id')
          .eq('user_id', userId)
          .single();

      if (response == null || response['guidance_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Guidance ID not found for this user')),
        );
        return;
      }

      final guidanceId = response['guidance_id'];

      // Show genre selection dialog and store the result
      String? selectedGenre = await _showGenreSelectionDialog();
      if (selectedGenre == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload canceled: No genre selected')),
        );
        return;
      }

      // File picker for selecting an audio file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result == null || result.files.single.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No file selected or file is empty')),
        );
        return;
      }

      final fileBytes = result.files.single.bytes!;
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';

      // Upload the audio file to the corresponding genre folder in Supabase storage
      final uploadResponse = await supabase.storage
          .from('audio_uploads')
          .uploadBinary('$selectedGenre/$fileName', fileBytes);

      if (uploadResponse.isEmpty) {
        throw Exception('Audio upload failed: response is empty');
      }

      String fileUrl = supabase.storage
          .from('audio_uploads')
          .getPublicUrl('$selectedGenre/$fileName');

      // Prepare data to insert into the database
      Map<String, dynamic> data = {
        'file_url': fileUrl,
        'title': result.files.single.name.split('.').first,
        'artist': 'Unknown Artist', // Default artist
        'genre': selectedGenre,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert the uploaded file information into the 'music' table
      await supabase.from('music').insert(data);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Audio uploaded successfully: $fileName'),
        backgroundColor: Colors.green,
      ));
    } catch (e, stacktrace) {
      print('Error: $e');
      print('Stacktrace: $stacktrace');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> uploadVideo() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: User is not authenticated')),
      );
      return;
    }

    try {
      final response = await supabase
          .from('user_guidance_profiles')
          .select('guidance_id')
          .eq('user_id', userId)
          .single();

      if (response == null || response['guidance_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Guidance ID not found for this user')),
        );
        return;
      }

      final guidanceId = response['guidance_id'];

      String? selectedCategory = await _showVideoCategorySelectionDialog();
      if (selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload canceled: No category selected')),
        );
        return;
      }

      String selectedBucket = '';
      String? subCategory;

      Map<String, String> folderMapping = {
        "Acts of Kindness": "acts_of_kindness",
        "Athletic Achievements": "athletic_achievements",
        "Educational": "educational",
        "Growth and Development": "growth_and_development",
        "Motivational Speech": "motivational_speech",
        "Success Stories": "success_stories",
      };

      if (selectedCategory == "Yoga") {
        selectedBucket = "yoga";
      } else if (selectedCategory == "Inspirational Videos") {
        subCategory = await _showInspirationalSubcategoryDialog();
        if (subCategory == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload canceled: No subcategory selected')),
          );
          return;
        }

        String? folderName = folderMapping[subCategory];
        if (folderName == null) {
          throw Exception('Invalid subcategory selected');
        }

        selectedBucket = "videos/$folderName";
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );

      if (result == null || result.files.single.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No file selected or file is empty')),
        );
        return;
      }

      final fileBytes = result.files.single.bytes!;
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';

      final uploadResponse = await supabase.storage
          .from(selectedBucket)
          .uploadBinary(fileName, fileBytes);

      if (uploadResponse.isEmpty) {
        throw Exception('Video upload failed: response is empty');
      }

      String fileUrl =
          supabase.storage.from(selectedBucket).getPublicUrl(fileName);

      Map<String, dynamic> data = {
        'file_url': fileUrl,
        'file_format': result.files.single.extension ?? 'unknown',
        'title': result.files.single.name.split('.').first,
        'uploader_id': guidanceId,
        'category': subCategory,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('video_uploads').insert(data);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Video uploaded successfully: $fileName'),
        backgroundColor: Colors.green,
      ));
    } catch (e, stacktrace) {
      print('Error: $e');
      print('Stacktrace: $stacktrace');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<String?> _showVideoTypeSelectionDialog() async {
    List<String> videoTypes = [
      "Acts of Kindness",
      "Athletic Achievements",
      "Educational",
      "Growth and Development",
      "Motivational Speech",
      "Success Stories"
    ];

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Video Type"),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: videoTypes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(videoTypes[index]),
                  onTap: () {
                    Navigator.of(context).pop(
                        videoTypes[index].toLowerCase().replaceAll(" ", "_"));
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel the dialog
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuidanceCounselorListPage(),
              ),
            ),
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Consultation(userId: widget.userId),
              ),
            ),
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
            onTap: () => Navigator.pop(context), // Already in Upload page
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

  Widget _buildTabButton(String label) {
    bool isSelected = selectedTab == label;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          if (label == "Audio") isHoveringAudio = true;
          if (label == "Video") isHoveringVideo = true;
        });
      },
      onExit: (_) {
        setState(() {
          if (label == "Audio") isHoveringAudio = false;
          if (label == "Video") isHoveringVideo = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = label;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Color(0xFF00796B)
                    : (label == "Audio" && isHoveringAudio) ||
                            (label == "Video" && isHoveringVideo)
                        ? Colors.black
                        : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            if (isSelected ||
                (label == "Audio" && isHoveringAudio) ||
                (label == "Video" && isHoveringVideo))
              Container(
                  height: 2,
                  width: 50, // Adjust width as needed
                  color: Color(0xFF00796B) // Pink underline for hover/selection
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selectedCategory == label ? Color(0xFF004D40) : Colors.white,
          border: Border.all(
            color:
                selectedCategory == label ? Colors.transparent : Colors.black45,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selectedCategory == label ? Colors.white : Colors.black,
            fontWeight:
                selectedCategory == label ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String? selectedAudioOption;
  String? selectedVideoOption;

  Widget _buildContent() {
    // Common Styles
    const headerStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFF00796B), // Dark teal for a clean look
    );

    const dropdownStyle = TextStyle(
      fontSize: 16,
      color: Color(0xFF004D40), // Slightly lighter teal for dropdown options
    );

    const hintStyle = TextStyle(
      fontSize: 16,
      color: Colors.grey,
    );

    if (selectedTab == "Audio") {
      List<String> audioOptions = [
        "Instrumental",
        "Classical",
        "Ambient",
        "Spa and Wellness",
        "Nature",
        "Breathing Exercise",
        "Meditation"
      ];

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Audio Category",
              style: headerStyle,
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFF00796B),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedAudioOption,
                  hint: Text("Select an option", style: hintStyle),
                  isExpanded: true,
                  style: dropdownStyle,
                  items: audioOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedAudioOption = newValue;
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  selectedAudioOption != null
                      ? "You selected: $selectedAudioOption"
                      : "Please select an audio category.",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (selectedTab == "Video") {
      List<String> videoOptions = ["Yoga", "Inspirational Video"];

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Video Category",
              style: headerStyle,
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFF00796B),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedVideoOption,
                  hint: Text("Select an option", style: hintStyle),
                  isExpanded: true,
                  style: dropdownStyle,
                  items: videoOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedVideoOption = newValue;
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  selectedVideoOption != null
                      ? "You selected: $selectedVideoOption"
                      : "Please select a video category.",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Text(
          "No Content Available",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  Future<String?> _showGenreSelectionDialog() async {
    List<String> genres = [
      "Instrumental",
      "Classical",
      "Ambient",
      "Spa and Wellness",
      "Nature"
    ];

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Music Genre"),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: genres.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(genres[index]),
                  onTap: () {
                    Navigator.of(context).pop(genres[index].toLowerCase());
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel the dialog
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadButton(String label, String fileType, Color buttonColor) {
    return ElevatedButton(
      onPressed: isUploading
          ? null
          : () => fileType == 'audio' ? uploadAudio() : uploadVideo(),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(label, style: TextStyle(fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      backgroundColor: Color(0xFFF3F8F8),
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
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildUploadButton('Upload Audio', 'audio', Color(0xFF004D40)),
                SizedBox(width: 10),
                _buildUploadButton('Upload Video', 'video', Color(0xFF00796B)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabButton("Audio"),
                SizedBox(width: 20),
                _buildTabButton("Video"),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                color: Colors.white,
                margin: EdgeInsets.all(16.0),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void main() {
    runApp(MaterialApp(
      home: Upload(userId: 'user-id-placeholder'),
      debugShowCheckedModeBanner: false,
    ));
  }
}
