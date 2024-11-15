import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  TextEditingController _journalTitleController = TextEditingController();
  TextEditingController _journalDescController = TextEditingController();

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
    print('Pick picture');

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
    print('Take picture');
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Store the image as a File
      });
    }
  }

  // Show BottomSheet with image options
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Upload Image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(); // Call pick image method
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture(); // Call take picture method
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /////////////// JOURNAL ENTRY /////////////////
  DateTime _dateToday = DateTime.now();

  ///////////////////////////////////////////////// WIDGET////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
      ),
      body: Center(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 5),
            margin: EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black54, width: 1),
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
                          hintText:
                              'Description / Quote', // Default text when empty
                          border: InputBorder.none,
                        ),
                        style:
                            TextStyle(fontSize: 18, color: Colors.purple[400]),
                      ),
                    ],
                  ),
                ),
                // Displaying the selected image or the Add Image icon
                _image == null
                    ? GestureDetector(
                        onTap: _showImageOptions, // Show options when pressed
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
                    : GestureDetector(
                        onTap: _showImageOptions, // Show options when pressed
                        child: Image.file(
                          _image!, // Display the selected image
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                SizedBox(height: 20),
              ],
            ),
          ),
          Container(
              margin: EdgeInsets.only(top: 10, left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${DateFormat('MMMM dd, yyyy').format(widget.selectedDate)}'),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    width: 372,
                    height: 200,
                    child: Text(
                        'datawrtbwrthbwrthwhdatawrtbwrthbwrthwhdatawrtbwrthbwrthwh \n'
                            'datawrtbwrthbwrthwhdatawrtbwrthbwrthwhdatawrtbwrthbwrthwh'),
                  ),
                  // Image.file(
                  //   _image!, // Display the selected image
                  //   width: 150,
                  //   height: 150,
                  //   fit: BoxFit.cover,
                  // ),

                  Container(
                    width: 300,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child:  Icon(
                      Icons.add_a_photo,
                      size: 100,
                      color: Colors.blue,
                    ),
                  ),

                ],
              )),
          Container(
            margin: EdgeInsets.only(top: 20),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey), top: BorderSide(color: Colors.grey) ),
            ),
            child:  Row(
              children: [
                Icon(Icons.image, size: 50,),
                Container(
                  child: Column(
                    children: [Text('data')],
                  ),
                )
              ],
            ),
          ),

        ],
      )),
    );
  }
}
