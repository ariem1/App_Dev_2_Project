import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class JournalPage extends StatefulWidget {
  final void Function(Color) onColorUpdate;
  final DateTime selectedDate;
  final String? currentUserId;

  const JournalPage({
    super.key,
    required this.selectedDate,
    required this.onColorUpdate,
    required this.currentUserId,

  });

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final FirestoreService _fsService = FirestoreService();
  bool isEditing = false;
  DateTime now = DateTime.now();
  late String formattedNow;
  late String formattedSelectDate;
  double spending = 0.0;


  // Controllers
  final TextEditingController _journalTitleController = TextEditingController();
  final TextEditingController _journalDescController = TextEditingController();
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  // Image handling
  File? _image;

  //Mood
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

  // Water droplet tracking
  List<Widget> droplets = [];

  // Fetch and display journal data
  Future<void> _fetchJournalData() async {
    print('Journal: fetching');
    final data =
        await _fsService.fetchJournalDataByDateAndUser(widget.selectedDate, widget.currentUserId);
    if (data.isNotEmpty) {
      setState(() {
        _journalTitleController.text = data['title'] ?? '';
        _journalDescController.text = data['description'] ?? '';
        _entryController.text = data['content'] ?? '';
        spending = double.tryParse(data['balance']?.toString() ?? '0.0') ?? 0.0;
        // Initialize droplets based on fetched water count
        int waterCount = int.tryParse(data['water']?.toString() ?? '0') ?? 0;
        droplets = List.generate(
          waterCount,
          (_) => Icon(Icons.water_drop_outlined, size: 30),
        );
      });
    }
  }

  // Save journal entry to the database
  Future<void> _saveJournalData() async {
    final content = _entryController.text;
    final title = _journalTitleController.text;
    final desc = _journalDescController.text;

    await _fsService.updateJournalEntry(content, desc, title, widget.currentUserId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Journal entry saved!')),
    );

    setState(() {
      isEditing = false;
    });
  }

  // Image handling methods
  Future<void> _pickImage() async {
    final picker = ImagePicker();

    try {
      // Step 1: Pick an image
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Step 2: Convert to File and set the state
        print('Image selected: ${pickedFile.path}');
        setState(() async {
          _image = File(pickedFile.path);


        });
        print('step 2');


        // Step 3: Upload the image to Firebasse Storage
        String? downloadURL = await _fsService.uploadImageToFirebase(_image!);
        print('Image selected: $downloadURL');

        if (downloadURL != null) {
          // Step 4: Save the download URL to Firestore
          await _fsService.saveImageURLToFirestore(downloadURL);
        } else {
          print('Failed to upload image to Firebase Storage.');
        }
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error selecting or uploading image: $e');
    }
  }


  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

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
                  print('Upload Image');

                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Add water droplet
  void _addDroplet() {
    setState(() {
      droplets.add(Icon(Icons.water_drop_outlined, size: 30));
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchJournalData();



    formattedNow = DateFormat('yyyy-MM-dd').format(now);
    formattedSelectDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    print(formattedSelectDate);
    print(formattedNow);

  }

  @override
  void dispose() {
    _journalTitleController.dispose();
    _journalDescController.dispose();
    _entryController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Entry'),
        actions: [
          if (formattedSelectDate == formattedNow )
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit),
              onPressed: isEditing
                  ? _saveJournalData
                  : () {
                setState(() {
                  isEditing = true;
                });
              },
            ),

        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fsService.fetchJournalDataByDateAndUser(widget.selectedDate, widget.currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
            // } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            //   return Center(
            //     child: Text('No journal entry found.'),
            //   );
            //
          }

          late int mood;
          final data = snapshot.data!;
          _journalTitleController.text = data['title'] ?? '';
          _journalDescController.text = data['description'] ?? '';
          _entryController.text = data['content'] ?? '';
          mood = data['mood'] ?? 5;

          return SingleChildScrollView(
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
                              isEditing
                                  ? TextField(
                                      controller: _journalTitleController,
                                      decoration: const InputDecoration(
                                        hintText: 'Add a journal title',
                                        hintStyle: TextStyle(fontSize: 22),
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
                              isEditing
                                  ? TextField(
                                      controller: _journalDescController,
                                      decoration: InputDecoration(
                                        hintText: 'Add a description or quote',
                                        hintStyle: TextStyle(fontSize: 17),
                                      ),
                                      style: TextStyle(fontSize: 17),
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
                        GestureDetector(
                          onTap: _showImageOptions,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: _image == null
                                ? Icon(Icons.add_a_photo,
                                    size: 40, color: Colors.blue)
                                : Image.file(_image!, fit: BoxFit.cover),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 400,
                    margin: EdgeInsets.only(top: 10, left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${DateFormat('MMMM dd, yyyy').format(widget.selectedDate)}'),
                        SizedBox(height: 10),
                        Container(
                          width: 372,
                          height: 200,
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: isEditing
                              ? SingleChildScrollView(
                                  child: TextField(
                                    controller: _entryController,
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      hintText: 'Add a journal entry',
                                    ),
                                    style: TextStyle(fontSize: 17),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Text(
                                    _entryController.text,
                                    style: TextStyle(fontSize: 17),
                                  ),
                                ),
                        ),

                        //IMAGE
                        GestureDetector(
                          onTap: _showImageOptions,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: _image == null
                                ? Icon(Icons.add_a_photo,
                                    size: 40, color: Colors.blue)
                                : Image.file(_image!, fit: BoxFit.cover),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // WATER
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey),
                        top: BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.water_drop_outlined, size: 70),
                        Container(
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
                      ],
                    ),
                  ),
                  // BUDGET
                  Container(
                    padding: EdgeInsets.only(top: 7, left: 5, bottom: 7),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black12, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, size: 70),
                        Container(
                          margin: EdgeInsets.only(left: 10),
                          width: 230,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Spendings"),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Text("Balance: \$ "),
                                  Text(spending.toStringAsFixed(2)),

                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // MOOD
                  Container(
                    //    margin: EdgeInsets.only(top: 10),
                    padding: EdgeInsets.only(top: 5, bottom: 15, left: 5),
                    decoration: BoxDecoration(
                        border: Border(
                      bottom: BorderSide(color: Colors.black12, width: 1),
                    )),
                    child: Row(
                      children: [
                        _moodToDisplay(mood),
                        Container(
                          padding: EdgeInsets.only(bottom: 20),
                          margin: EdgeInsets.only(left: 10),
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Today's Mood"),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
