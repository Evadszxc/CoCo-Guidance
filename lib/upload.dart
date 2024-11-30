import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

class Upload extends StatefulWidget {
  final String userId;

  Upload({required this.userId});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  final SupabaseClient supabase = Supabase.instance.client;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isUploading = false;
  String selectedTab = "Music"; // Default selected tab
  String selectedCategory = "Motivational Speech"; // Default category

  Future<void> uploadFile(String fileType) async {
    if (fileType == 'audio') {
      // Step 1: Select Genre
      String? selectedGenre = await _showGenreSelectionDialog();

      if (selectedGenre == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload canceled: No genre selected')),
        );
        return;
      }

      try {
        setState(() {
          isUploading = true;
        });

        // Step 2: Pick File
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
        );

        if (result != null && result.files.single.bytes != null) {
          // Step 3: Prepare File Details
          final fileBytes = result.files.single.bytes!; // Use bytes on web
          String fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
          String filePath = '${selectedGenre.toLowerCase()}/$fileName';

          // Step 4: Upload to Supabase Storage
          final uploadResponse = await supabase.storage
              .from('audio_uploads')
              .uploadBinary(filePath, fileBytes);

          if (uploadResponse.isEmpty) {
            throw Exception('File upload failed: response is empty');
          }

          // Get Public URL for the uploaded file
          String fileUrl =
              supabase.storage.from('audio_uploads').getPublicUrl(filePath);

          // Step 5: Insert Metadata into the Database
          final insertResponse = await supabase.from('music').insert({
            'title': result.files.single.name.split('.').first,
            'artist': 'Unknown Artist',
            'genre': selectedGenre.toLowerCase(),
            'file_url': fileUrl,
          }).execute();

          // Check for Errors in the Insert Response
          if (insertResponse.status != 201) {
            // 201 means "Created" in HTTP
            // Handle error
            print('Error: ${insertResponse.data}');
          } else {
            // Success logic
            print('Insert successful');
          }

          // Show Success Message
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'File uploaded and metadata saved successfully: $fileName'),
            backgroundColor: Colors.green,
          ));
        } else {
          throw Exception('No file selected or file is empty');
        }
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
                    Navigator.of(context).pop(genres[index]);
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

  Widget _buildTabButton(String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selectedTab == label ? Color(0xFF00796B) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedTab == label ? Color(0xFF00796B) : Colors.black12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selectedTab == label ? Colors.white : Colors.black,
            fontWeight:
                selectedTab == label ? FontWeight.bold : FontWeight.normal,
          ),
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

  Widget _buildContent() {
    if (selectedTab == "Music") {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryButton("Instrumental"),
              _buildCategoryButton("Classical"),
              _buildCategoryButton("Ambient"),
              _buildCategoryButton("Spa and Wellness"),
              _buildCategoryButton("Nature"),
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Text("1"),
                  title: Text(
                    "Havana",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Ann Joyce"),
                  trailing: Text("4:23"),
                ),
                ListTile(
                  leading: Text("2"),
                  title: Text("Awesome Days"),
                  subtitle: Text("Brad Din"),
                  trailing: Text("0:24"),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (selectedTab == "Video") {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryButton("Motivational Speech"),
              _buildCategoryButton("Acts of Kindness"),
              _buildCategoryButton("Athletic Achievements"),
              _buildCategoryButton("Growth and Development"),
              _buildCategoryButton("Success Stories"),
            ],
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              padding: EdgeInsets.all(16),
              children: List.generate(6, (index) {
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Text(
                      "Video Placeholder ${index + 1}",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF3F8F8),
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Image.asset('assets/menu.png', width: 30, height: 30),
                onPressed: () => _scaffoldKey.currentState!.openDrawer(),
              ),
              SizedBox(width: 10),
              Image.asset('assets/coco1.png', width: 200, height: 70),
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
              _buildTabButton("Music"),
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
    );
  }

  Widget _buildUploadButton(String label, String fileType, Color buttonColor) {
    return ElevatedButton(
      onPressed: isUploading ? null : () => uploadFile(fileType),
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
}

void main() {
  runApp(MaterialApp(
    home: Upload(userId: 'user-id-placeholder'),
    debugShowCheckedModeBanner: false,
  ));
}
