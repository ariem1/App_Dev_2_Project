import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'settings_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File operations

class JournalPage extends StatefulWidget {
  final void Function(Color) onColorUpdate;

  final DateTime selectedDate;

  const JournalPage(
      {super.key, required this.selectedDate, required this.onColorUpdate});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  String _journalName = "Journal";
  late String _journalEntryTitle;

  TextEditingController _journalTitleController = new TextEditingController();
  TextEditingController _journalDescController = new TextEditingController();

  // Update journal name and refresh AppBar title
  void _updateJournalName(String newName) {
    setState(() {
      _journalName = newName;
    });
  }

  ///////////// FOR IMAGE /////////////////

  File? _image;

  // Method to pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Store the image as a File
      });
    }
  }

  // Method to capture an image using the camera
  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Store the image as a File
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'Settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      journalName: _journalName,
                      onNameUpdated: _updateJournalName,
                      onColorUpdate: widget.onColorUpdate,
                    ),
                  ),
                ).then((updatedName) {
                  if (updatedName != null) {
                    _updateJournalName(updatedName);
                  }
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'Settings',
                child: Text('Settings'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
          child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 5),
            margin: EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 270,
                  margin: EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _journalTitleController,
                        decoration: InputDecoration(
                          hintText: 'Title', // Default text when empty
                          border: InputBorder.none,
                        ),
                        style: TextStyle(fontSize: 25),
                      ),
                      TextField(
                        controller: _journalDescController,
                        decoration: InputDecoration(
                          hintText: 'Title', // Default text when empty
                          border: InputBorder.none,
                        ),
                        style: TextStyle(fontSize: 18, color: Colors.pink[70]),
                      ),
                    ],
                  ),
                ),
                // Displaying the selected image or the Add Image icon
                _image == null
                    ? GestureDetector(
                        onTap: _pickImage, // Allow the user to pick an image
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.blue,
                          ),
                        ),
                      )
                    : Image.file(
                        _image!, // Display the selected image
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                SizedBox(height: 20),
                // ElevatedButton(
                //   onPressed: _pickImage, // Pick image from gallery
                //   child: Text('Pick Image from Gallery'),
                // ),
                // ElevatedButton(
                //   onPressed: _takePicture, // Capture image using camera
                //   child: Text('Capture Image using Camera'),
                // ),
              ],
            ),
          )
        ],
      )),
    );
  }
}
