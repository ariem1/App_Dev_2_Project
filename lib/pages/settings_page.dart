import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String journalName;
  final ValueChanged<String> onNameUpdated;

  const SettingsPage({super.key, required this.journalName, required this.onNameUpdated});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _journalNameController;
  String? _selectedColor;
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _journalNameController = TextEditingController(text: widget.journalName);
    _selectedColor = 'Option 1';
    _selectedLanguage = 'English';
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _journalNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                onPressed: () {
                  widget.onNameUpdated(_journalNameController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Journal name updated successfully'),
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

  // Build radio buttons
  Widget _buildRadio(String value, String label, String? groupValue) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: (value) {
            setState(() {
              if (groupValue == _selectedColor) {
                _selectedColor = value;
              } else {
                _selectedLanguage = value;
              }
            });
          },
        ),
        Text(label),
      ],
    );
  }
}
