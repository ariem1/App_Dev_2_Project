import 'package:flutter/material.dart';
import 'package:aura_journal/firestore_service.dart';

class SettingsPage extends StatefulWidget {
  final String journalName;
  final ValueChanged<String> onNameUpdated;
  final ValueChanged<Color> onColorUpdate;

  const SettingsPage({
    super.key,
    required this.journalName,
    required this.onNameUpdated,
    required this.onColorUpdate,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final FirestoreService fsService = FirestoreService();

  late TextEditingController _journalNameController;
  String? _selectedColor;
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _journalNameController = TextEditingController(text: widget.journalName);
    _selectedColor = 'Option 1';
    _selectedLanguage = 'English';

    fetchJournalName();
  }

  Color _getColorFromOption(String colorOption) {
    if (colorOption == 'Option 2') {
      return Colors.pink;
    } else if (colorOption == 'Option 3') {
      return Colors.purple;
    }
    return const Color(0xFFE3EFF9); // Default blue color
  }

  Future<void> fetchJournalName() async {

    String? userId = fsService.getCurrentUser()?.uid;

    if (userId != null) {
      final docSnapshot = await fsService.getDocument(
        collection: 'users',
        documentId: userId,
      );
      setState(() {
        widget.onNameUpdated(docSnapshot.data()?['journalName']);
        print('Settings: Journal Name updated in the app');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                height: 350,
                color: Colors.white70,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Journal Name',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _journalNameController,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Color',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRadio('Option 1', 'Blue', _selectedColor),
                        _buildRadio('Option 2', 'Pink', _selectedColor),
                        _buildRadio('Option 3', 'Purple', _selectedColor),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Language',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRadio('English', 'English', _selectedLanguage),
                        _buildRadio('French', 'French', _selectedLanguage),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async{

                  String? userId = fsService.getCurrentUserId();

                  // add the journal name to the db
                  if( userId != null && _journalNameController.text.isNotEmpty) {
                    await fsService.updateJournalName(_journalNameController.text);
                    print('Settings: Journal name updates to ${_journalNameController.text}');

                    fetchJournalName();

                  } else{
                    print('Please enter a journal name.');
                  }

                  widget.onColorUpdate(_getColorFromOption(_selectedColor!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aura journal settings have been updated'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                },
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build radio buttons for options
  Widget _buildRadio(String value, String label, String? groupValue) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: (value) {
            setState(() {
              _selectedColor = value;
            });
          },
        ),
        Text(label),
      ],
    );
  }
}
