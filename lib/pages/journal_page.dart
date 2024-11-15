import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore_service.dart';
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
  //db connection
  final FirestoreService _fsService = FirestoreService();
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

  @override
  void initState() {
    super.initState();
    _fetchAndDisplayJournalEntryWhenLoad();
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

  bool isEditing = false;
  TextEditingController _entryController = TextEditingController();

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _saveToDatabase() async {
    String entry = _entryController.text;

    await _fsService.updateJournalEntry(entry);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Journal entry saved!')),
    );
  }

  void _fetchAndDisplayJournalEntryWhenLoad() async {
    //String journalEntry = await _fsService.fetchJournalEntry();
    String title = await _fsService.fetchJournalData('title');
    String content = await _fsService.fetchJournalData('entry');
    String desc = await _fsService.fetchJournalData('description');

    String? journalId = await _fsService.getJournalIdByUserIdAndDate();
    int? mood = await _fsService.getJournalMood(journalId!);

    if (title != null) {
      setState(() {
        _journalTitleController.text = title;
      });
    }

    if (desc != null) {
      setState(() {
        _journalDescController.text = desc;
      });
    }
    if (content != null) {
      setState(() {
        _entryController.text = content;
      });
    }
    //
    // setState(() {
    //   _buildIcon(mood!);
    //
    // });


  }

  void _fetchAndDisplayJournalEntry() async {
    String journalEntry = await _fsService.fetchJournalEntry();
    setState(() {
      _entryController.text = journalEntry;
    });
  }

  // List to store water drop icons
  List<Widget> droplets = [];

  // Function to add a droplet
  void _addDroplet() {
    setState(() {
      droplets
          .add(Icon(Icons.water_drop_outlined, size: 30)); // Add a new droplet
    });
  }

  /////////////// MOOD ///////////////////

  int _selectedMood = 5; // DEFAULT

  Icon _buildIcon(int index) {
    switch (index) {
      case 0:
        return Icon(Icons.sentiment_very_dissatisfied); // Lowest rating
      case 1:
        return Icon(Icons.sentiment_dissatisfied); // Moderate-low rating
      case 2:
        return Icon(Icons.sentiment_neutral); // Neutral rating
      case 3:
        return Icon(Icons.sentiment_satisfied); // Moderate-high rating
      case 4:
        return Icon(Icons.sentiment_very_satisfied); // Highest rating
      default:
        return Icon(Icons.star_border); // Default icon
    }
  }

  Icon _moodToDisplay(int index) {
    return Icon(
      _buildIcon(index).icon,
      size: 70,
    );
  }

  /* FIREBASE STUFF */
// Check if journal entry exists for today
  Future<bool> _checkJournalEntry() async {
    bool journalExists = await _fsService.journalEntryExistsForToday();
    print('Journal exists: $journalExists');

    return journalExists;
  }

  ///////////////////////////////////////////////// WIDGET////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
        actions: [
          // Updating the AppBar Icon dynamically based on the editing state
          IconButton(
            onPressed: () async {
              if (isEditing) {
                await _saveToDatabase();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Journal entry saved!')));
              } else {
                print('Jounral entry displaying');
                _fetchAndDisplayJournalEntry();
              }
              setState(() {
                isEditing = !isEditing;
              });
            },
            icon: Icon(isEditing ? Icons.check : Icons.edit, size: 20),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
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
                    width: 260,
                    margin: EdgeInsets.only(left: 20, right: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Journal title field or text
                        isEditing
                            ? TextField(
                                controller: _journalTitleController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a journal title',
                                  hintStyle: TextStyle(fontSize: 22),
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(0),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors
                                          .grey, // Color of the bottom border when not focused
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.purple,
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.normal),
                              )
                            : Text(
                                _journalTitleController.text.isEmpty
                                    ? 'Title'
                                    : _journalTitleController.text,
                                style: TextStyle(fontSize: 25),
                              ),

                        SizedBox(height: 10),

                        // Journal description field
                        isEditing
                            ? TextField(
                                controller: _journalDescController,
                                decoration: InputDecoration(
                                  hintStyle: TextStyle(fontSize: 17),
                                  hintText: 'Add a description or quote',
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(0),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey,
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors
                                          .purple, // Color of the bottom border when focused
                                      width: 1.0, // Thicker border on focus
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.normal),
                              )
                            : Text(
                                _journalDescController.text.isEmpty
                                    ? 'Description / Quote'
                                    : _journalDescController.text,
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.normal),
                              ),
                      ],
                    ),
                  ),
                  // Image
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
                    Row(
                      children: [
                        Text(
                            '${DateFormat('MMMM dd, yyyy').format(widget.selectedDate)}'),
                        SizedBox(
                          width: 200,
                        ),
                      ],
                    ),
                    Container(
                      width: 372,
                      height: 200,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: isEditing
                          ? SingleChildScrollView(
                              child: TextField(
                                style: TextStyle(fontSize: 17),
                                controller: _entryController,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.all(0),
                                  hintText: 'Add a journal entry',
                                ),
                                maxLines:
                                    null, // Allow unlimited lines, so text wraps
                                keyboardType: TextInputType
                                    .multiline, // Enable multiline input
                              ),
                            )
                          : SingleChildScrollView(
                              // Wrap text content with a scroll view for long text
                              child: Text(
                                _entryController.text,
                                style: TextStyle(fontSize: 17),
                              ),
                            ),
                    ),
                    Container(
                      width: 250,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Icon(
                        Icons.add_a_photo,
                        size: 100,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                )),
            Container(
              margin: EdgeInsets.only(top: 20),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Colors.grey),
                    top: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                children: [
                  Icon(Icons.water_drop_outlined, size: 70),
                  Container(
                    //  padding: EdgeInsets.only(bottom: 10),
                    margin: EdgeInsets.only(left: 10),
                    width: 260,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Water Intake"),
                        SizedBox(height: 7),
                        Row(children: droplets),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addDroplet,
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10),
              padding: EdgeInsets.only(top: 5, bottom: 5, left: 10),
              decoration: BoxDecoration(
                  border: Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              )),
              child: Row(
                children: [
                  _moodToDisplay(_selectedMood),
                  Container(
                    //  padding: EdgeInsets.only(bottom: 10),
                    margin: EdgeInsets.only(left: 10),
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Mood"),
                        // SizedBox(height: 10),
                        Row(
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: _buildIcon(index),
                              onPressed: () async {
                                // add mood to journal entry of the day

                                //If journal doesnt exist, make an entry
                                bool journalExists =
                                    await _checkJournalEntry(); // Await the check

                                if (!journalExists) {
                                  await _fsService.addJournalEntry(
                                    index,
                                    '',
                                  );
                                  print('Journal entry created and mood added');
                                } else {
                                  //If journal exists, update the mood
                                  String? journalId = await _fsService
                                      .getJournalIdByUserIdAndDate();

                                  //update mood
                                  _fsService.updateJournalMood(
                                      journalId!, index);
                                }

                                setState(() {
                                  _selectedMood = index;
                                });
                              },
                              color: _selectedMood == index
                                  ? Colors.deepPurple
                                  : null,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              //  margin: EdgeInsets.only(top: 5),
              padding: EdgeInsets.only(top: 7, left: 5, bottom: 7),
              decoration: BoxDecoration(
                  border: Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              )),
              child: Row(
                children: [
                  Icon(Icons.attach_money, size: 70),
                  Container(
                    //  padding: EdgeInsets.only(bottom: 10),
                    margin: EdgeInsets.only(left: 10),
                    width: 230,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Spendings"),
                        SizedBox(height: 10),
                        Row(children: [
                          Text("Balance: \$"),
                          // Expanded(
                          //     child: TextField(
                          //       controller: budgetController,
                          //       onChanged: (value) =>
                          //       amount = double.tryParse(value) ?? 0.0,
                          //       keyboardType: TextInputType.number,
                          //     ))
                        ]),
                      ],
                    ),
                  ),
                  // IconButton(
                  //   icon: Icon(Icons.add),
                  //   onPressed: addSpending,
                  // ),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}
